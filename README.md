# FlyAppDiscovery

**⚠️ This package is still a work in progress, the API isn't stable and the code isn't reliable yet. Swift 5.7 is required**

FlyAppDiscovery is a Swift package that enables DNS-based discovery of [Fly.io](fly.io) application instances, vended as [`Node`](https://apple.github.io/swift-distributed-actors/1.0.0-beta.1.1/documentation/distributedactors/node) objects from the [Swift Distributed Actors library](https://github.com/apple/swift-distributed-actors/).

# Usage

## Initialization

You must initialize `FlyAppDiscovery` with an event loop group and a port the nodes of the cluster will be listening on.

```swift
let disovery = try await FlyAppDiscovery(eventLoopGroup: eventLoopGroup, port: 8080)
```

## Selecting and getting nodes

Selecting instance is done through the `InstanceSelector` type which defines a `.currentApp(region: Region)` static method.

### All app instances

```swift
 let nodes = try await disovery.lookup(.currentApp())
```

### App instances for a certain region

```swift
 let nodes = try await disovery.lookup(.currentApp(.region("scl"))) // Nodes in Santiago de Chile
```

Note that in general, it is probably preferable to get the nodes / actors of all regions (as it is done in the previous example using `.currentApp()`) and then filter them based on their metadata. 

Using `.currentApp(.region("..."))` makes the service discovery completely unaware of any other regions, which might not be desirable.

### More

See the documentation of [Swift Service Discovery](https://github.com/apple/swift-service-discovery) and [Swift Distributed Actors](https://github.com/apple/swift-distributed-actors/) for more details on usage.

With the Swift Distributed Actors library you don't generally need to call methods like `lookup` or `subscribe` yourself and instead just provide a `ServiceDiscoverySettings` object that the cluster system will use to discover and automatically join the nodes.
