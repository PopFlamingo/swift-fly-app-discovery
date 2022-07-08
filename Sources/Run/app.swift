import FlyAppDiscovery
import Backtrace

@main
struct App {
    static func main() async throws {
        Backtrace.install()
        let disovery = try await FlyAppDiscovery(port: 8080)
        print("Subscribing to service discovery.")
        for try await first in disovery.subscribe(to: .currentApp()) {
            print(first)
        }
    }
}