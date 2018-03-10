# NIOUDPEcho

This was an exploratory project to check out [SwiftNIO](https://github.com/apple/swift-nio) and what its capabilities
 are like for UDP packets.  I set out to modify the Echo client and server examples for use with UDP instead of
 TCP as they were written.  I did not implement all the command line options the original Echo examples had as I more
 focused on what was needed to switch from TCP to UDP.
 
 ## NIOUDPEchoServer
 
 This is the simple echo server.  Unlike the example included with SwiftNIO it is hard coded to bind to `127.0.0.1`.
 It can be invoked with the following commands:
 
 ```
 swift run NIOUDPEchoServer  # Binds the server on 127.0.0.1, port 9999.
 swift run NIOUDPEchoServer 8888  # Binds the server on 127.0.0.1, port 8888
 ```
 
 ## NIOUDPEchoClient
 
 This is the simple echo client.  Unlike the example include with SwiftNIO it is hard coded to send packets to
 `127.0.0.1`.  It can be invoked with the following commands:
 
 ```
 swift run NIOUDPEchoClient # Sends packets to 127.0.0.1, port 9999.
 swift run NIOUDPEchoClient 8888  # Send packets to 127.0.0.1, port 8888.
 ```
