import XCTest
@testable import FlyAppDiscovery

final class SwiftFlyAppDiscoveryTests: XCTestCase {
    func testExample() async throws {
        
        let disovery = try await FlyAppDiscovery(port: 8080)
        for try await first in disovery.subscribe(to: .currentApp()) {
            print(first)
        }
    }
}
