module EventMachine
  module ProxyServer
    class Connection < EventMachine::Connection
      attr_accessor :debug

      ##### Proxy Methods
      def on_finish(&blk); @on_finish = blk; end
      def on_connect(&blk); @on_connect = blk; end

      ##### EventMachine
      def initialize(options)
        @debug = options[:debug] || false
        @servers = {}
        @req_buff = ''
        @resp_buff = ''
      end

      def post_init
        if $l_ssl_options[:do_ssl]
          puts "Initiating SSL connection with client" if @debug
          start_tls($l_ssl_options)
        end
      end

      def receive_data(data)
        debug [:connection, data]

        if $replacement_req
          # add new data to buffer (in most cases buffer is empty)
          @req_buff += data
          # choose payload's destiny depending on processing script
          ret = @req_buff.instance_eval($replacement_req)
          case ret
          when :skip
            # just skip this payload
            @req_buff = ''
            return
          when :wait
            # buffer more data
            return
          when :ok
            # proceed to sending
          end
        else
          # no replacement -- no buffering
          @req_buff = data
        end

        log("Client", @req_buff)
        relay_to_servers(@req_buff)
        @req_buff = ''
      end

      def relay_to_servers(processed)
        if processed.is_a? Array
          data, servers = *processed

          # guard for "unbound" servers
          servers = servers.collect {|s| @servers[s]}.compact
        else
          data = processed
          servers ||= @servers.values.compact
        end

        servers.each do |s|
          puts "Sending client data to the server"
          s.send data unless data.nil?
        end
      end

      #
      # initialize connections to backend servers
      #
      def server(name, opts)
        if opts[:socket]
          srv = EventMachine::connect_unix_domain(opts[:socket], EventMachine::ProxyServer::Backend, @debug) do |c|
            c.name = name
            c.plexer = self
            c.proxy_incoming_to(self, 10240) if opts[:relay_server]
          end
        else
          srv = EventMachine::bind_connect(opts[:bind_host], opts[:bind_port], opts[:host], opts[:port], EventMachine::ProxyServer::Backend, @debug) do |c|
            c.name = name
            c.plexer = self
            c.proxy_incoming_to(self, 10240) if opts[:relay_server]
          end
        end

        self.proxy_incoming_to(srv, 10240) if opts[:relay_client]

        @servers[name] = srv
      end

      #
      # [ip, port] of the connected client
      #
      def peer
        @peer ||= begin
          peername = get_peername
          peername ? Socket.unpack_sockaddr_in(peername).reverse : nil
        end
      end

      #
      # [ip, port] of the local server connect
      #
      def sock
        @sock ||= begin
          sockname = get_sockname
          sockname ? Socket.unpack_sockaddr_in(sockname).reverse : nil
        end
      end

      #
      # relay data from backend server to client
      #
      def relay_from_backend(name, data)
        puts "Backend sent data..."
        debug [:relay_from_backend, name, data]

        if $replacement_resp
          @resp_buff += data
          ret = @resp_buff.instance_eval($replacement_resp)
          case ret
          when :skip
            @resp_buff = ''
            return
          when :wait
            return
          when :ok
          end
        else
          @resp_buff = data
        end

        log("Backend Server", @resp_buff)
        send_data(@resp_buff)
        @resp_buff = ''
      end

      def connected(name)
        debug [:connected]
        @on_connect.call(name) if @on_connect
      end

      def unbind
        debug [:unbind, :connection]

        puts "Terminating any unfinished connections"
        @servers.values.compact.each do |s|
          s.close_connection_after_writing
        end
      end

      def unbind_backend(name)
        debug [:unbind_backend, name]
        @servers[name] = nil
        close = :close

        if @on_finish
          close = @on_finish.call(name)
        end

        # if all connections are terminated downstream, then notify client
        if (@servers.values.compact.size.zero? && close != :keep) || (close == :close)
          close_connection_after_writing
        end
      end

      private

      def debug(*data)
        if @debug
          require 'pp'
          pp data
          puts
        end
      end

      def log(t,data)
        if $logfile
          logfile=File.new($logfile,'a')
          #logfile.puts "-------------#{t}--------------\n\n#{data}\n\n"
          logfile.puts "#{data}"
          logfile.close
        end
      end
    end
  end
end
