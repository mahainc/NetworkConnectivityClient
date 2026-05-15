import Dependencies
import Foundation

// MARK: - Dependency Registration

extension DependencyValues {
	public var networkConnectivityClient: NetworkConnectivityClient {
		get { self[NetworkConnectivityClient.self] }
		set { self[NetworkConnectivityClient.self] = newValue }
	}
}

// MARK: - Test Dependency Key

extension NetworkConnectivityClient: TestDependencyKey {
	/// Used in SwiftUI previews — returns realistic mock data.
	public static let previewValue = Self.happy

	/// Used in tests — all endpoints unimplemented (will fail if called without override).
	public static let testValue = Self()
}

// MARK: - Mock Constants

private enum MockConstants {
	static let eventEmissionDelayNanoseconds: UInt64 = 100_000_000  // 100ms
}

// MARK: - Mock Implementations

extension NetworkConnectivityClient {
	/// Simulates a connected WiFi network with realistic behavior.
	public static let happy = Self(
		observePath: {
			AsyncStream { continuation in
				Task {
					try? await Task.sleep(nanoseconds: MockConstants.eventEmissionDelayNanoseconds)
					continuation.yield(NetworkPath(
						status: .satisfied,
						isExpensive: false,
						isConstrained: false,
						availableInterfaceTypes: [.wifi]
					))
				}
			}
		},
		currentPath: {
			NetworkPath(
				status: .satisfied,
				isExpensive: false,
				isConstrained: false,
				availableInterfaceTypes: [.wifi]
			)
		}
	)

	/// All operations are no-ops — stream finishes immediately.
	public static let noop = Self(
		observePath: { .finished },
		currentPath: { NetworkPath() }
	)

	/// Simulates a disconnected network.
	public static let disconnected = Self(
		observePath: {
			AsyncStream { continuation in
				continuation.yield(NetworkPath(
					status: .unsatisfied,
					isExpensive: false,
					isConstrained: false,
					availableInterfaceTypes: []
				))
			}
		},
		currentPath: {
			NetworkPath(
				status: .unsatisfied,
				isExpensive: false,
				isConstrained: false,
				availableInterfaceTypes: []
			)
		}
	)

	/// Simulates an expensive cellular connection.
	public static let cellular = Self(
		observePath: {
			AsyncStream { continuation in
				continuation.yield(NetworkPath(
					status: .satisfied,
					isExpensive: true,
					isConstrained: false,
					availableInterfaceTypes: [.cellular]
				))
			}
		},
		currentPath: {
			NetworkPath(
				status: .satisfied,
				isExpensive: true,
				isConstrained: false,
				availableInterfaceTypes: [.cellular]
			)
		}
	)
}
