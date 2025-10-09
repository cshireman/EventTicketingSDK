//
//  NetworkClient+WebSocket.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/9/25.
//
import Foundation

extension DefaultNetworkClient {
    internal func startWebSocketConnection(
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

    internal func parseWebSocketMessage(data: Data) throws -> EventUpdate {
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
