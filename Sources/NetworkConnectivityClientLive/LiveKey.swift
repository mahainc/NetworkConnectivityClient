import Dependencies
import Foundation
import NetworkConnectivityClient
import Network

// MARK: - Monitor Delegate

private final class MonitorDelegate: @unchecked Sendable {
	private let monitor = NWPathMonitor()
	private let queue = DispatchQueue(label: "com.app.network-connectivity", qos: .utility)
	private var isStarted = false

	var onPathUpdate: (@Sendable (NWPath) -> Void)?

	func start() {
		guard !isStarted else { return }
		monitor.pathUpdateHandler = { [weak self] path in
			self?.onPathUpdate?(path)
		}
		monitor.start(queue: queue)
		isStarted = true
	}

	func stop() {
		guard isStarted else { return }
		monitor.cancel()
		isStarted = false
	}

	func currentNWPath() -> NWPath {
		monitor.currentPath
	}
}

// MARK: - Actor

private actor NetworkMonitor {
	private let delegate = MonitorDelegate()
	private var pathContinuation: AsyncStream<NetworkConnectivityClient.NetworkPath>.Continuation?

	init() {
		delegate.onPathUpdate = { [weak self] nwPath in
			Task { await self?.handlePathUpdate(nwPath) }
		}
		delegate.start()
	}

	deinit {
		pathContinuation?.finish()
	}

	func observePath() -> AsyncStream<NetworkConnectivityClient.NetworkPath> {
		pathContinuation?.finish()

		return AsyncStream { continuation in
			self.pathContinuation = continuation

			let current = delegate.currentNWPath()
			continuation.yield(NetworkPath(from: current))

			continuation.onTermination = { [weak self] _ in
				Task { await self?.handleStreamTermination() }
			}
		}
	}

	func currentPath() -> NetworkConnectivityClient.NetworkPath {
		NetworkPath(from: delegate.currentNWPath())
	}

	private func handlePathUpdate(_ nwPath: NWPath) {
		let path = NetworkPath(from: nwPath)
		pathContinuation?.yield(path)
	}

	private func handleStreamTermination() {
		pathContinuation = nil
	}
}

// MARK: - DependencyKey

extension NetworkConnectivityClient: DependencyKey {
	public static let liveValue: NetworkConnectivityClient = {
		let monitor = NetworkMonitor()
		return NetworkConnectivityClient(
			observePath: {
				await monitor.observePath()
			},
			currentPath: {
				await monitor.currentPath()
			}
		)
	}()
}

// MARK: - NWPath Conversion

private typealias NetworkPath = NetworkConnectivityClient.NetworkPath
private typealias NetworkStatus = NetworkConnectivityClient.NetworkStatus
private typealias InterfaceType = NetworkConnectivityClient.InterfaceType

extension NetworkPath {
	fileprivate init(from nwPath: NWPath) {
		let interfaceTypes: [NWInterface.InterfaceType] = [.wifi, .cellular, .wiredEthernet, .loopback, .other]
		self.init(
			status: NetworkStatus(from: nwPath.status),
			isExpensive: nwPath.isExpensive,
			isConstrained: nwPath.isConstrained,
			availableInterfaceTypes: interfaceTypes.compactMap { type in
				nwPath.usesInterfaceType(type) ? InterfaceType(from: type) : nil
			}
		)
	}
}

extension NetworkStatus {
	fileprivate init(from status: NWPath.Status) {
		switch status {
		case .satisfied: self = .satisfied
		case .unsatisfied: self = .unsatisfied
		case .requiresConnection: self = .requiresConnection
		@unknown default: self = .unsatisfied
		}
	}
}

extension InterfaceType {
	fileprivate init(from type: NWInterface.InterfaceType) {
		switch type {
		case .wifi: self = .wifi
		case .cellular: self = .cellular
		case .wiredEthernet: self = .wiredEthernet
		case .loopback: self = .loopback
		default: self = .other
		}
	}
}
