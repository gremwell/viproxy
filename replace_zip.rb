
require "zip"

h = self.index("\x50\x4b\x03\x04")
if h
  puts "zip signature found"

  begin
    Zip::InputStream.open(StringIO.new(self[h, self.length])) do |io|
      while entry = io.get_next_entry
        puts "entry: #{entry.name}"
        puts "content: #{io.read}"
      end
    end
  rescue Exception => msg
    # buffer data, wait for the next packet
    :wait
  else
    # save intercepted zip archive
    #File.open("/tmp/1.zip", "wb") {|f| f.write(self[h, self.length]) }

    # read new one
    newzip = File.new("/tmp/1_mod.zip", "r").read
    # calculate length difference between them
    diff = self.length - h - newzip.force_encoding('ASCII-8BIT').length
    # substitute content of the old archive with the new one
    self[h, self.length] = newzip.force_encoding('ASCII-8BIT') + "\x00"*diff

    # send packet further
    :ok
  end
end
