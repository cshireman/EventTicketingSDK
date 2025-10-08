//
//  TicketService.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//

import Foundation

actor TicketService {

    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    /// Get available tickets for an event
    func getAvailableTickets(eventID: String) async throws -> [Ticket] {
        let endpoint = Endpoint.availableTickets(eventID: eventID)
        return try await networkClient.request(endpoint)
    }

    /// Reserve tickets (holds them for a specified time)
    func reserveTickets(
        ticketIDs: [String],
        eventID: String
    ) async throws -> TicketReservation {
        let endpoint = Endpoint.reserveTickets(eventID: eventID, ticketIDs: ticketIDs)
        return try await networkClient.request(endpoint)
    }

    /// Get details for a specific ticket
    func getTicket(id: String) async throws -> Ticket {
        // This would require adding a new endpoint for individual ticket details
        let endpoint = Endpoint.ticket(id: id)
        return try await networkClient.request(endpoint)
    }

    /// Check reservation status
    func getReservation(id: String) async throws -> TicketReservation {
        let endpoint = Endpoint.reservation(id: id)
        return try await networkClient.request(endpoint)
    }

    /// Cancel a ticket reservation
    func cancelReservation(id: String) async throws {
        let endpoint = Endpoint.cancelReservation(id: id)
        let _: EmptyResponse = try await networkClient.request(endpoint)
    }
}

// Helper struct for endpoints that don't return data
private struct EmptyResponse: Codable {}
