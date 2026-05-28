# NetworkConnectivityClient

A small TCA dependency client wrapping `Network.framework`'s `NWPathMonitor` behind a `Sendable` interface that streams connectivity changes and offers a synchronous snapshot. Built on [`swift-composable-architecture`](https://github.com/pointfreeco/swift-composable-architecture).

The package ships two products:

- **`NetworkConnectivityClient`** — interface only. No `Network` import, safe for tests and previews; ships a `NetworkPath` model that mirrors `NWPath` without its no-public-init constraint.
- **`NetworkConnectivityClientLive`** — internal `actor NetworkMonitor` wrapping `NWPathMonitor`, bridges path-update callbacks into an `AsyncStream<NetworkPath>`. Registered as the live `DependencyKey`.

## Installation

In your `Package.swift`:

```swift
.package(url: "https://github.com/mahainc/NetworkConnectivityClient.git", from: "0.1.0"),
```

Add `NetworkConnectivityClient` to your feature target and `NetworkConnectivityClientLive` to your app target.

## Usage

```swift
import NetworkConnectivityClient
import ComposableArchitecture

@Reducer
struct ConnectivityFeature {
    @ObservableState
    struct State {
        var path: NetworkConnectivityClient.NetworkPath = .init()
    }

    enum Action {
        case onAppear
        case pathChanged(NetworkConnectivityClient.NetworkPath)
    }

    @Dependency(\.networkConnectivityClient) var network

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    for await path in await network.observePath() {
                        await send(.pathChanged(path))
                    }
                }

            case let .pathChanged(path):
                state.path = path
                return .none
            }
        }
    }
}
```

## Snapshot vs. stream

```swift
// One-shot snapshot — useful inside conditionals before kicking off work
let path = await network.currentPath()
if path.isConnected && path.isWifi { /* download large asset */ }

// Live stream — emits the current path immediately then any subsequent change
for await path in await network.observePath() {
    // path.isConnected / .isWifi / .isCellular / .isExpensive / .isConstrained
}
```

## Testing

The interface module ships several preconfigured mocks plus an unimplemented `testValue`:

```swift
let store = TestStore(initialState: ConnectivityFeature.State()) {
    ConnectivityFeature()
} withDependencies: {
    $0.networkConnectivityClient = .happy        // .happy / .disconnected / .cellular / .noop
}
```

`happy` simulates a connected Wi-Fi network, `disconnected` an offline state, `cellular` an expensive metered connection, and `noop` a finished stream with default snapshot. `testValue` uses the macro-generated unimplemented defaults — override `observePath` / `currentPath` to assert directly.

## Platform support

- iOS 17+
- macOS 14+

## License

MIT — see [LICENSE](./LICENSE).
