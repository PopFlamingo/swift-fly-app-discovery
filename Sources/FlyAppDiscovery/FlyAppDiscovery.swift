import ServiceDiscovery
import DistributedActors
import Foundation
import DNSClient
import NIO

public class FlyAppDiscovery: ServiceDiscovery {
    /// Create a new FlyAppDiscovery instance configured to provide Distributed Actors `Node`s.
    /// The nodes will be configured to use the provided `port` as their listening port.
    public init(port: Int) async throws {
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.client = try await DNSClient.connectTCP(on: self.eventLoopGroup).get()
        guard let selfIP = try await Self.ipv6Addresses(client: self.client, host: "_local_ip.internal").first else {
            throw Error.noSelfIPAddress
        }
        self.selfIP = selfIP
        self.port = port
    }

    public func syncShutdownGracefully() throws {
        try eventLoopGroup.syncShutdownGracefully()
    }

    public func shutdown() async throws {
        try await eventLoopGroup.shutdownGracefully()
    }

    enum Error: Swift.Error {
        case noSelfIPAddress
    }

    let eventLoopGroup: MultiThreadedEventLoopGroup
    let client: DNSClient
    let selfIP: String
    let port: Int

    public func subscribe(to service: InstanceSelector, onNext nextResultHandler: @escaping (Result<[DistributedActors.Node], Swift.Error>) -> Void, onComplete completionHandler: @escaping (CompletionReason) -> Void) -> CancellationToken {
        let task = Task {
            do {
                var currentAddresses = Set(try await self.ipv6Addresses(for: service.host))
                currentAddresses.remove(self.selfIP)
                let nodes = currentAddresses.map { DistributedActors.Node(host: $0, port: self.port) }
                nextResultHandler(.success(nodes))
                while !Task.isCancelled {
                    try await Task.sleep(nanoseconds: 60_000_000_000)
                    var nextFetch = Set(try await self.ipv6Addresses(for: service.host))
                    nextFetch.remove(self.selfIP)
                    // Notify the nextResultHandler only if the set of addresses has changed.
                    if nextFetch != currentAddresses {
                        currentAddresses = nextFetch
                        let nodes = currentAddresses.map { DistributedActors.Node(host: $0, port: self.port) }
                        nextResultHandler(.success(nodes))
                    }                    
                }
                if Task.isCancelled {
                    completionHandler(.cancellationRequested)
                }
            } catch {
                if error is CancellationError {
                    completionHandler(.cancellationRequested)
                } else {
                    completionHandler(.serviceDiscoveryUnavailable)
                }
            }
        }
        let cancellationToken = CancellationToken {  reason in
            task.cancel()
        }

        return cancellationToken
    }

    public func lookup(_ service: InstanceSelector, deadline: DispatchTime?, callback: @escaping (Result<[DistributedActors.Node], Swift.Error>) -> Void) {
        if deadline != nil {
            print("Custom deadline not supported currently, default is 30 seconds.")
        }
        Task {
            do {
                var addressesSet = Set(try await self.ipv6Addresses(for: service.host))
                addressesSet.remove(selfIP)
                let nodes = addressesSet.map { Node(host: $0, port: port) }
                callback(.success(nodes))
            } catch {
                callback(.failure(error))
            }
        }
    }

    public var defaultLookupTimeout: DispatchTimeInterval {
        return .seconds(30)
    }

    func ipv6Addresses(for host: String) async throws -> [String] {
        return try await Self.ipv6Addresses(client: self.client, host: host)
    }

    static func ipv6Addresses(client: DNSClient, host: String) async throws -> [String] {
        let addresses = try await client.initiateAAAAQuery(host: host, port: 0).get()
        return addresses.compactMap { socketAddress in
            socketAddress.ipAddress
        }
    }

    public struct InstanceSelector: Hashable {
        let host: String
        /// Select instances of the current app.
        /// - parameter region: Select which regions to return instances from
        public static func currentApp(region: Region = .all) -> InstanceSelector {
            // Get FLY_APP_NAME from the environment
            guard let flyAppName = ProcessInfo.processInfo.environment["FLY_APP_NAME"] else {
                fatalError("FLY_APP_NAME environment variable is not set")
            }

            switch region {
            case .all:
                return InstanceSelector(host: "global.\(flyAppName).internal")
            case .region(let region):
                return InstanceSelector(host: "\(region).\(flyAppName).internal")
            }
        }

        /// The region defines the physical location where app instances are located.
        public enum Region {
            /// Get all instances regardless of region.
            case all

            /// Get instances in the specified region.
            case region(String)
        }

        public typealias Instance = Node
    }
    
}