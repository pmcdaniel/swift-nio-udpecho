/**
 NIOUDPEchoServer [port]
 This starts up a server which will echo anything recieved on the localhost port.  The port can be passed in
 or will default to 9999.  This is based on the example provided with SwiftNIO except uses UDP instead of TCP
 */
import NIO

private final class EchoHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    
    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        ctx.write(data, promise: nil)
    }
    
    public func channelReadComplete(ctx: ChannelHandlerContext) {
        ctx.flush()
    }
    
    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("error :", error)
        
        ctx.close(promise: nil)
    }
}

let group = MultiThreadedEventLoopGroup(numThreads: System.coreCount)

// Using DatagramBootstrap turns out to be the only significant change between TCP and UDP in this case
let bootstrap = DatagramBootstrap(group: group)
    .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    .channelInitializer { channel in
        channel.pipeline.add(handler: EchoHandler())
}
defer {
    try! group.syncShutdownGracefully()
}

let defaultPort = 9999

let arguments = CommandLine.arguments
let port = arguments.dropFirst().flatMap {Int($0)}.first ?? defaultPort

let channel = try! bootstrap.bind(host: "127.0.0.1", port: port).wait()

print("Channel accepting connections on \(channel.localAddress!)")

try channel.closeFuture.wait()

print("Channel closed")
