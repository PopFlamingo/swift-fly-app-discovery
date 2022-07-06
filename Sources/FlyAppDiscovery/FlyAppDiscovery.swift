import ServiceDiscovery
import DistributedActors
import Foundation
import DNSClient
import NIO

public class FlyAppDiscovery: ServiceDiscovery {
    public init(port: Int) async throws {
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.client = try await DNSClient.connectTCP(on: self.eventLoopGroup, host: "8.8.8.8").get()
        print( try await Self.ipv6Addresses(client: self.client, host: "google.com").first)
        print( try await Self.ipv6Addresses(client: self.client, host: "wikipedia.org").first)
        guard let selfIP = try await Self.ipv6Addresses(client: self.client, host: "_local_ip.internal").first else {
            throw Error.noSelfIPAddress
        }
        print("Self IP is \(selfIP)")
        self.selfIP = selfIP
        self.port = port
    }

    deinit {
        try? eventLoopGroup.syncShutdownGracefully()
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
            
                var adressesSet = Set(try await self.ipv6Addresses(for: service.host))
                adressesSet.remove(self.selfIP)
                print(adressesSet)
                let nodes = adressesSet.map { DistributedActors.Node(host: $0, port: self.port) }
                print(nodes)
                nextResultHandler(.success(nodes))
                while !Task.isCancelled {
                    try await Task.sleep(nanoseconds: 60_000_000_000)
                    let nextFetch = Set(try await self.ipv6Addresses(for: service.host))
                    var newNodes = nextFetch.subtracting(adressesSet)
                    newNodes.remove(self.selfIP)
                    nextResultHandler(.success(newNodes.map { DistributedActors.Node(host: $0, port: self.port) }))
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
        let message = try await client.sendQuery(forHost: host, type: .aaaa).get()
        return message.answers.compactMap { answer -> String? in
            guard case .aaaa(let aaaaRecord) = answer else {
                return nil
            }
            let ipBytes = ByteBuffer(bytes: aaaaRecord.resource.address)
            let socket = try? SocketAddress(packedIPAddress: ipBytes, port: 0)
            return socket?.ipAddress
        }
    }

    public struct InstanceSelector: Hashable {
        let host: String

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

        public enum Region {
            case all
            case region(String)
        }

        public typealias Instance = Node

    }
    
}

func foo() async throws {
    let loop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let client = try await DNSClient.connect(on: loop).get()
    
}