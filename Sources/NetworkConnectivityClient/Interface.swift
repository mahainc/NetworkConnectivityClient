import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
public struct NetworkConnectivityClient: Sendable {
	/// Stream of network path changes — emits whenever connectivity changes.
	public var observePath: @Sendable () async -> AsyncStream<NetworkConnectivityClient.NetworkPath> = {
		AsyncStream { _ in }
	}

	/// Get a snapshot of the current network path.
	public var currentPath: @Sendable () async -> NetworkConnectivityClient.NetworkPath = {
		NetworkPath()
	}
}
