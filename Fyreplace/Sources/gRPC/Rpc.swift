import Foundation
import GRPC

class Rpc {
    private let group = PlatformSupport.makeEventLoopGroup(loopCount: 1)
    let channel: ClientConnection

    init() {
        let host = Bundle.main.infoDictionary!["FPApiHost"] as! String
        let port = Bundle.main.infoDictionary!["FPApiPort"] as! String

        #if DEBUG
            let builder = ClientConnection.insecure(group: group)
        #else
            let builder = ClientConnection.usingPlatformAppropriateTLS(for: group)
        #endif

        channel = builder.connect(host: host, port: Int(port)!)
    }

    deinit {
        try? group.syncShutdownGracefully()
    }
}
