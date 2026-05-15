import Testing
@testable import NetworkConnectivityClient

@Test func networkPathDefaultsToUnsatisfied() {
    let path = NetworkConnectivityClient.NetworkPath()
    #expect(path.status == .unsatisfied)
    #expect(path.isExpensive == false)
    #expect(path.isConstrained == false)
    #expect(path.availableInterfaceTypes.isEmpty)
}
