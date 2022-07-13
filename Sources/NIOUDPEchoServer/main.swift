/**
 NIOUDPEchoServer [port]
 This starts up a server which will echo anything recieved on the localhost port.  The port can be passed in
 or will default to 9999.  This is based on the example provided with SwiftNIO except uses UDP instead of TCP
 */
import NIO

private final class EchoHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let addressedEnvelope = self.unwrapInboundIn(data)
        print("Recieved data from \(addressedEnvelope.remoteAddress)")
        context.write(data, promise: nil)
    }

    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("error :", error)

        context.close(promise: nil)
    }
}

let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

// Using DatagramBootstrap turns out to be the only significant change between TCP and UDP in this case
let bootstrap = DatagramBootstrap(group: group)
    .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    .channelInitializer { channel in
        channel.pipeline.addHandler(EchoHandler())
}
defer {
    try! group.syncShutdownGracefully()
}

let defaultPort = 9999

let arguments = CommandLine.arguments
let port = arguments.dropFirst().compactMap {Int($0)}.first ?? defaultPort

let channel = try! bootstrap.bind(host: "127.0.0.1", port: port).wait()

print("Channel accepting connections on \(channel.localAddress!)")

try channel.closeFuture.wait()

print("Channel closed")
