import FlyAppDiscovery

@main
struct App {
    static func main() async throws {
        let disovery = try await FlyAppDiscovery(port: 8080)
        for try await first in disovery.subscribe(to: .currentApp()) {
            print(first)
        }
    }
}