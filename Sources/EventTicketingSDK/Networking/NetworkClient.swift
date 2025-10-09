//
//  NetworkClient.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//
import Foundation

// MARK: - NetworkClient Protocol

protocol NetworkClient: Actor {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func streamUpdates(eventID: String) -> AsyncStream<EventUpdate>
}

// MARK: - Default NetworkClient Implementation

actor DefaultNetworkClient: NetworkClient {

    private let session: URLSession
    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: sessionConfig)
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        // Build request
        let request = try buildRequest(for: endpoint)

        // Execute request
        let (data, response) = try await session.data(for: request)

        // Validate response
        try validateResponse(response)

        // Parse response
        return try parseResponse(data: data)
    }

    private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(
            url: configuration.baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        )

        // Add query parameters
        if !endpoint.queryItems.isEmpty {
            components?.queryItems = endpoint.queryItems
        }

        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        // Add headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")

        // Add body if needed
        if let body = endpoint.body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 400:
            throw NetworkError.badRequest
        case 401:
            throw NetworkError.unauthorized
        case 404:
            throw NetworkError.notFound
        case 429:
            throw NetworkError.rateLimited
        case 500...599:
            throw NetworkError.serverError
        default:
            throw NetworkError.unknown(statusCode: httpResponse.statusCode)
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

    func streamUpdates(eventID: String) -> AsyncStream<EventUpdate> {
        AsyncStream { continuation in
            Task {
                await startWebSocketConnection(eventID: eventID, continuation: continuation)
            }
        }
    }
    
    private func startWebSocketConnection(
        eventID: String, 
        continuation: AsyncStream<EventUpdate>.Continuation
    ) async {
        var components = URLComponents(url: configuration.webSocketURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "eventId", value: eventID),
            URLQueryItem(name: "apiKey", value: configuration.apiKey)
        ]
        
        guard let webSocketURL = components?.url else {
            continuation.finish()
            return
        }
        
        let webSocketTask = session.webSocketTask(with: webSocketURL)
        webSocketTask.resume()
        
        // Set up termination handler
        continuation.onTermination = { @Sendable _ in
            webSocketTask.cancel(with: .goingAway, reason: nil)
        }
        
        do {
            // Start listening for messages
            while !Task.isCancelled {
                let message = try await webSocketTask.receive()
                
                switch message {
                case .data(let data):
                    if let eventUpdate = try? parseWebSocketMessage(data: data) {
                        continuation.yield(eventUpdate)
                    }
                    
                case .string(let text):
                    if let data = text.data(using: .utf8),
                       let eventUpdate = try? parseWebSocketMessage(data: data) {
                        continuation.yield(eventUpdate)
                    }
                    
                @unknown default:
                    break
                }
            }
        } catch {
            // Connection closed or error occurred
        }
        
        continuation.finish()
    }
    
    private func parseWebSocketMessage(data: Data) throws -> EventUpdate {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        // First try to decode the raw message structure
        struct WebSocketMessage: Decodable {
            let eventId: String
            let type: String
            let timestamp: Date
            let data: AnyCodable?
        }
        
        let message = try decoder.decode(WebSocketMessage.self, from: data)
        
        // Convert to EventUpdate.UpdateType based on the message type
        let updateType: EventUpdate.UpdateType
        
        switch message.type {
        case "tickets_available":
            if let count = message.data?.value as? Int {
                updateType = .ticketsAvailable(count: count)
            } else {
                throw NetworkError.decodingFailed(DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: [], debugDescription: "Invalid tickets_available data")
                ))
            }
            
        case "sold_out":
            updateType = .soldOut
            
        case "price_changed":
            if let priceValue = message.data?.value as? Double {
                updateType = .priceChanged(newPrice: Decimal(priceValue))
            } else {
                throw NetworkError.decodingFailed(DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: [], debugDescription: "Invalid price_changed data")
                ))
            }
            
        case "rescheduled":
            if let dateString = message.data?.value as? String,
               let newDate = ISO8601DateFormatter().date(from: dateString) {
                updateType = .rescheduled(newDate: newDate)
            } else {
                throw NetworkError.decodingFailed(DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: [], debugDescription: "Invalid rescheduled data")
                ))
            }
            
        case "cancelled":
            updateType = .cancelled
            
        default:
            throw NetworkError.decodingFailed(DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Unknown update type: \(message.type)")
            ))
        }
        
        return EventUpdate(
            eventId: message.eventId,
            type: updateType,
            timestamp: message.timestamp
        )
    }
}
