import XCTest
@testable import FlyAppDiscovery

final class SwiftFlyAppDiscoveryTests: XCTestCase {
    func testExample() async throws {
        
        let disovery = try await FlyAppDiscovery(port: 8080)
        disovery.subscribe(to: .currentApp())
    }
}
