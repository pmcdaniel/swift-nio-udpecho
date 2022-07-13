/**
 NIOUDPEchoClient [port]
 This sends the user supplied string to the port specified on the command line and expects the string to be returned
 (echoed) back.  The port passed in should match the port the server is listening on (default is 9999).  This
 is based on the example provided with SwiftNIO except uses UDP instead of TCP.
 */
import NIO

print("Please enter line to send to the server")
let line = readLine(strippingNewline: true)!

private final class EchoHandler : ChannelInboundHandler {
    // typealias changes to wrap out ByteBuffer in an AddressedEvelope which describes where the packages are going
    public typealias InboundIn = AddressedEnvelope<ByteBuffer>
    public typealias OutboundOut = AddressedEnvelope<ByteBuffer>
    private var numBytes = 0
    
    public init(_ expectedNumBytes: Int) {
        self.numBytes = expectedNumBytes
    }
    
    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        numBytes -= self.unwrapInboundIn(data).data.readableBytes
        
        assert(numBytes >= 0)
        
        if numBytes == 0 {
            print("Received the line back from the server, closing channel")
            ctx.close(promise: nil)
        }
    }
    
    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("error: ", error)
        ctx.close(promise: nil)
    }
}

private final class EchoOutputHandler : ChannelOutboundHandler {
    public typealias OutboundIn = AddressedEnvelope<ByteBuffer>
    
    // The method just grabs the data on the way out and adds the expected input handler
    public func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let expectedNumBytes = self.unwrapOutboundIn(data).data.readableBytes
        ctx.channel.pipeline.addHandler(EchoHandler(expectedNumBytes))
        ctx.write(data, promise: promise)

    }
}

let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

// Like with the NIOUDPEchoServer we switch to using DatagramBootstrap here instead of ServerBootstrap
let bootstrap = DatagramBootstrap(group: group)
    .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    .channelInitializer { channel in
        channel.pipeline.addHandler(EchoOutputHandler())
}
defer {
    try! group.syncShutdownGracefully()
}

let defaultPort = 9999
let listenPort = 8888

let arguments = CommandLine.arguments
let port = arguments.dropFirst().compactMap {Int($0)}.first ?? defaultPort

let channel = try bootstrap.bind(host: "127.0.0.1", port: listenPort).wait()
let remoteAddr = try SocketAddress(ipAddress: "127.0.0.1", port: port)

print("Sending message to \(remoteAddr)")
var buffer = channel.allocator.buffer(string: line)
let envelope = AddressedEnvelope(remoteAddress: remoteAddr, data: buffer)
channel.writeAndFlush(envelope, promise: nil)

// These lines would connect to the UDP socket vs sending the packets into the ether.
// The advantage being that if an ICMP packet came back about the port not being opened
// you'd be warned about it
/*channel.connect(to: remoteAddr).whenComplete {
    var buffer = channel.allocator.buffer(capacity: line.utf8.count)
    buffer.write(string: line)
    channel.writeAndFlush(buffer, promise: nil)
}*/

try channel.closeFuture.wait()

print("Client Closed")
