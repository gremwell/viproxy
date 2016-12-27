# Viproxy 1.0

Transparent intercepting proxy in Ruby for MITM attacks.

# Viproxy is forked from em-proxy
- Author: Ilya Grigorik
- Original Project: https://travis-ci.org/igrigorik/em-proxy
- EngineYard tutorial: [Load testing your environment using em-proxy](http://docs.engineyard.com/em-proxy.html)
- [Slides from RailsConf 2009](http://bit.ly/D7oWB)
- [GoGaRuCo notes & Slides](http://www.igvita.com/2009/04/20/ruby-proxies-for-scale-and-monitoring/)

## New Features
- Log file support
- SSL support
- Custom digital certificate support
- Search & Replace support for traffic manipulation

## Known bugs
- No error handling :)
- Duplex server must be SSL enabled if connection is SSL enabled
- Multithreads create some errors, they will be fixed after Blackhat/Defcon


## Getting started

    $ ruby bin/viproxy
    Usage: viproxy [options]
    -l, --listen [PORT]              Port to listen on
    -d, --duplex [host:port, ...]    List of backends to duplex data to
    -r, --relay [hostname:port]      Relay endpoint: hostname:port
    -s, --socket [filename]          Relay endpoint: unix filename
        --l-ssl                      l-leg: run in SSL mode
        --l-sslkey [filename]        l-leg: SSL certificate key file (PEM)
        --l-sslcert [filename]       l-leg: SSL certificate file (PEM)
        --l-sni [sni hostname]       l-leg: SNI hostname
        --r-ssl                      r-leg: run in SSL mode
        --r-sslkey [filename]        r-leg: SSL certificate key file (PEM)
        --r-sslcert [filename]       r-leg: SSL certificate file (PEM)
        --r-sni [sni hostname]       r-leg: SNI hostname
    -f, --logfile [filename]         Log file
        --req-replace [filename]     Replacement file for requests
        --resp-replace [filename]    Replacement file for responses
    -v, --verbose                    Run in debug mode

Usage example:

    $ ruby bin/viproxy -l 8443 -f test1.log -v -r dest.example.com:443 --l-ssl --r-ssl --l-sslkey ssl-key.pem --l-sslcert ssl-cert.pem --req-replace test-replace.rb

This will listen on localhost:8443, write all data to test1.log, print debugging info, send incoming data towards dest.example.com:443, use SSL for incoming and outgoing connections, use specified SSL certificates for listening socket, match/replace incoming requests using specified script.

## Sample Search & Replace file

See `replace_zip.rb`.

## License

The MIT License - Copyright (c) 2010 Ilya Grigorik
