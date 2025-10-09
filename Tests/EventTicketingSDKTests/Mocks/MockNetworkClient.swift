//
//  MockNetworkClient.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//

@testable import EventTicketingSDK
import Foundation

/// A mock implementation of NetworkClient for testing purposes
/// This mock allows you to simulate network responses, errors, and streaming updates
actor MockNetworkClient: NetworkClient {
    
    // MARK: - Mock State
    
    /// Stored responses for different endpoints
    private var mockResponses: [String: Result<Data, NetworkError>] = [:]
    
    /// Delay to simulate network latency (in seconds)
    var networkDelay: TimeInterval = 0.0
    
    /// Whether the client should simulate being offline
    var isOffline: Bool = false
    
    /// Mock streaming updates for WebSocket connections
    private var mockStreamUpdates: [String: [EventUpdate]] = [:]
    
    /// Tracks which requests have been made
    internal var requestHistory: [MockRequest] = []

    // MARK: - Configuration
    
    private let configuration: Configuration
    
    init(configuration: Configuration = .default) {
        self.configuration = configuration
    }
    
    // MARK: - Mock Configuration Methods
    
    /// Set a mock response for a specific endpoint
    func setMockResponse<T: Codable>(for endpoint: Endpoint, response: T) {
        let key = endpointKey(endpoint)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(response)
            mockResponses[key] = .success(data)
        } catch {
            mockResponses[key] = .failure(.decodingFailed(error))
        }
    }
    
    /// Set a mock error for a specific endpoint
    func setMockError(for endpoint: Endpoint, error: NetworkError) {
        let key = endpointKey(endpoint)
        mockResponses[key] = .failure(error)
    }
    
    /// Set mock streaming updates for an event
    func setMockStreamUpdates(for eventID: String, updates: [EventUpdate]) {
        mockStreamUpdates[eventID] = updates
    }
    
    /// Clear all mock responses and history
    func resetMocks() {
        mockResponses.removeAll()
        mockStreamUpdates.removeAll()
        requestHistory.removeAll()
        networkDelay = 0.0
        isOffline = false
    }
    
    /// Get the history of requests made to this mock client
    func getRequestHistory() -> [MockRequest] {
        return requestHistory
    }
    
    /// Check if a specific request was made
    func wasRequestMade(to endpoint: Endpoint) -> Bool {
        let key = endpointKey(endpoint)
        return requestHistory.contains { $0.endpointKey == key }
    }
    
    /// Get the number of times a specific endpoint was called
    func getRequestCount(for endpoint: Endpoint) -> Int {
        let key = endpointKey(endpoint)
        return requestHistory.filter { $0.endpointKey == key }.count
    }
    
    // MARK: - NetworkClient Protocol Implementation
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        // Record the request
        let request = MockRequest(
            endpointKey: endpointKey(endpoint),
            endpoint: endpoint,
            timestamp: Date()
        )
        requestHistory.append(request)
        
        // Simulate offline state
        if isOffline {
            throw NetworkError.noConnection
        }
        
        // Simulate network delay
        if networkDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        }
        
        // Get mock response
        let key = endpointKey(endpoint)
        guard let mockResult = mockResponses[key] else {
            // If no mock response is set, return a default error
            throw NetworkError.notFound
        }
        
        switch mockResult {
        case .success(let data):
            return try parseResponse(data: data)
        case .failure(let error):
            throw error
        }
    }
    
    func streamUpdates(eventID: String) -> AsyncStream<EventUpdate> {
        AsyncStream { continuation in
            Task {
                await startMockStreamingUpdates(eventID: eventID, continuation: continuation)
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    func endpointKey(_ endpoint: Endpoint) -> String {
        switch endpoint {
        case .events:
            return "events"
        case .event(let id):
            return "event-\(id)"
        case .searchEvents(let query):
            return "searchEvents-\(query)"
        case .availableTickets(let eventID):
            return "availableTickets-\(eventID)"
        case .reserveTickets(let eventID, let ticketIDs):
            return "reserveTickets-\(eventID)-\(ticketIDs.joined(separator: ","))"
        case .purchaseTickets(let reservationID):
            return "purchaseTickets-\(reservationID)"
        case .ticket(let id):
            return "ticket-\(id)"
        case .reservation(let id):
            return "reservation-\(id)"
        case .cancelReservation(let id):
            return "cancelReservation-\(id)"
        case .purchaseTicketsWithPayment(let request):
            return "purchaseTicketsWithPayment-\(request.reservationID)"
        case .order(let id):
            return "order-\(id)"
        case .userOrders(let userID):
            return "userOrders-\(userID)"
        case .cancelOrder(let id):
            return "cancelOrder-\(id)"
        case .requestRefundWithData(let orderID, _):
            return "requestRefund-\(orderID)"
        case .refundStatus(let orderID):
            return "refundStatus-\(orderID)"
        }
    }
    
    private func parseResponse<T: Decodable>(data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
    
    private func startMockStreamingUpdates(
        eventID: String,
        continuation: AsyncStream<EventUpdate>.Continuation
    ) async {
        guard let updates = mockStreamUpdates[eventID] else {
            continuation.finish()
            return
        }
        
        // Simulate streaming by yielding updates with small delays
        for update in updates {
            if Task.isCancelled {
                break
            }
            
            continuation.yield(update)
            
            // Small delay between updates to simulate real-time streaming
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        continuation.finish()
    }
}

