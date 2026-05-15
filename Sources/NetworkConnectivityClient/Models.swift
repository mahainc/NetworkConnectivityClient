import Foundation

// MARK: - NetworkPath

extension NetworkConnectivityClient {
	/// Wrapper around NWPath — provides a constructible, Sendable snapshot of network state.
	/// NWPath has no public initializer, so this model enables mock construction in tests.
	public struct NetworkPath: Sendable, Equatable {
		public let status: NetworkStatus
		public let isExpensive: Bool
		public let isConstrained: Bool
		public let availableInterfaceTypes: [InterfaceType]

		public var isConnected: Bool { status == .satisfied }
		public var isWifi: Bool { availableInterfaceTypes.contains(.wifi) }
		public var isCellular: Bool { availableInterfaceTypes.contains(.cellular) }

		public init(
			status: NetworkStatus = .unsatisfied,
			isExpensive: Bool = false,
			isConstrained: Bool = false,
			availableInterfaceTypes: [InterfaceType] = []
		) {
			self.status = status
			self.isExpensive = isExpensive
			self.isConstrained = isConstrained
			self.availableInterfaceTypes = availableInterfaceTypes
		}
	}
}

// MARK: - NetworkStatus

extension NetworkConnectivityClient {
	public enum NetworkStatus: Sendable, Equatable {
		case satisfied
		case unsatisfied
		case requiresConnection
	}
}

// MARK: - InterfaceType

extension NetworkConnectivityClient {
	public enum InterfaceType: Sendable, Equatable {
		case wifi
		case cellular
		case wiredEthernet
		case loopback
		case other
	}
}
