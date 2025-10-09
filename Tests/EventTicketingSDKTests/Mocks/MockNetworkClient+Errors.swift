//
//  MockNetworkClient+Errors.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/9/25.
//

@testable import EventTicketingSDK
import Foundation

extension MockNetworkClient {

    /// Simulate various error scenarios for testing
    func simulateNetworkError(_ error: NetworkError, for endpoint: Endpoint) {
        setMockError(for: endpoint, error: error)
    }

    /// Simulate slow network conditions
    func simulateSlowNetwork(delay: TimeInterval = 2.0) {
        networkDelay = delay
    }

    /// Simulate offline conditions
    func simulateOffline() {
        isOffline = true
    }

    /// Simulate back online
    func simulateOnline() {
        isOffline = false
    }

    /// Verify that a specific endpoint was called with expected frequency
    func verifyRequestCount(for endpoint: Endpoint, expectedCount: Int) -> Bool {
        return getRequestCount(for: endpoint) == expectedCount
    }

    /// Get the most recent request to a specific endpoint
    func getLastRequest(to endpoint: Endpoint) -> MockRequest? {
        let key = endpointKey(endpoint)
        return requestHistory.last { $0.endpointKey == key }
    }
}
