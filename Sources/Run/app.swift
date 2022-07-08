import FlyAppDiscovery
import Backtrace
import NIO

@main
struct App {
    static func main() async throws {
        Backtrace.install()
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let disovery = try await FlyAppDiscovery(eventLoopGroup: eventLoopGroup, port: 8080)
        print("Subscribing to service discovery.")
        for try await discoveredNodes in disovery.subscribe(to: .currentApp()) {
            print(discoveredNodes)
        }
    }
}