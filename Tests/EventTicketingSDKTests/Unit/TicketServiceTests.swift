//
//  TicketServiceTests.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//

import Testing
import Foundation
@testable import EventTicketingSDK

@Suite("TicketService Tests")
struct TicketServiceTests {
    
    @Test("Get available tickets for event - success")
    func testGetAvailableTicketsSuccess() async throws {
        // Given
        let mockClient = MockNetworkClient()
        let ticketService = TicketService(networkClient: mockClient)
        let eventID = "event-123"
        
        let expectedTickets = [
            createTestTicket(id: "ticket-1", eventId: eventID),
            createTestTicket(id: "ticket-2", eventId: eventID, seat: "13"),
            createTestTicket(id: "ticket-3", eventId: eventID, seat: "14")
        ]
        
        await mockClient.setMockResponse(for: .availableTickets(eventID: eventID), response: expectedTickets)
        
        // When
        let result = try await ticketService.getAvailableTickets(eventID: eventID)
        
        // Then
        #expect(result.count == 3)
        #expect(result[0].id == "ticket-1")
        #expect(result[1].id == "ticket-2")
        #expect(result[2].id == "ticket-3")
        #expect(result.allSatisfy { $0.eventId == eventID })
    }
    
    @Test("Get available tickets for event - network error")
    func testGetAvailableTicketsNetworkError() async throws {
        // Given
        let mockClient = MockNetworkClient()
        let ticketService = TicketService(networkClient: mockClient)
        let eventID = "event-123"
        
        await mockClient.setMockError(for: .availableTickets(eventID: eventID), error: .noConnection)

        // When & Then
        await #expect(throws: NetworkError.noConnection) {
            try await ticketService.getAvailableTickets(eventID: eventID)
        }
    }
    
    @Test("Get available tickets for event - empty response")
    func testGetAvailableTicketsEmptyResponse() async throws {
        // Given
        let mockClient = MockNetworkClient()
        let ticketService = TicketService(networkClient: mockClient)
        let eventID = "event-123"
        
        let emptyTickets: [Ticket] = []
        await mockClient.setMockResponse(for: .availableTickets(eventID: eventID), response: emptyTickets)
        
        // When
        let result = try await ticketService.getAvailableTickets(eventID: eventID)
        
        // Then
        #expect(result.isEmpty)
    }
    
    // MARK: - reserveTickets Tests
    
    @Test("Reserve tickets - success")
    func testReserveTicketsSuccess() async throws {
        // Given
        let mockClient = MockNetworkClient()
        let ticketService = TicketService(networkClient: mockClient)
        let eventID = "event-123"
        let ticketIDs = ["ticket-1", "ticket-2"]
        
        let expectedReservation = createTestReservation(
            id: "reservation-456",
            tickets: [
                createTestTicket(id: "ticket-1", eventId: eventID),
                createTestTicket(id: "ticket-2", eventId: eventID, seat: "13")
            ]
        )
        
        await mockClient.setMockResponse(
            for: .reserveTickets(eventID: eventID, ticketIDs: ticketIDs),
            response: expectedReservation
        )
        
        // When
        let result = try await ticketService.reserveTickets(
            ticketIDs: ticketIDs,
            eventID: eventID
        )
        
        // Then
        #expect(result.reservationId == "reservation-456")
        #expect(result.tickets.count == 2)
        #expect(result.tickets[0].id == "ticket-1")
        #expect(result.tickets[1].id == "ticket-2")
        #expect(result.total == 150.00)
        #expect(result.expiresAt > Date())
    }
    
    @Test("Reserve tickets - tickets unavailable")
    func testReserveTicketsUnavailable() async throws {
        // Given
        let mockClient = MockNetworkClient()
        let ticketService = TicketService(networkClient: mockClient)
        let eventID = "event-123"
        let ticketIDs = ["ticket-1", "ticket-2"]
        
        await mockClient.setMockError(
            for: .reserveTickets(eventID: eventID, ticketIDs: ticketIDs),
            error: .badRequest
        )
        
        // When & Then
        await #expect(throws: NetworkError.badRequest) {
            try await ticketService.reserveTickets(
                ticketIDs: ticketIDs,
                eventID: eventID
            )
        }
    }
    
    @Test("Reserve tickets - empty ticket IDs")
    func testReserveTicketsEmptyIDs() async throws {
        // Given
        let mockClient = MockNetworkClient()
        let ticketService = TicketService(networkClient: mockClient)
        let eventID = "event-123"
        let ticketIDs: [String] = []
        
        let expectedReservation = createTestReservation(
            id: "reservation-empty",
            tickets: [],
            total: 0.00
        )
        
        await mockClient.setMockResponse(
            for: .reserveTickets(eventID: eventID, ticketIDs: ticketIDs),
            response: expectedReservation
        )
        
        // When
        let result = try await ticketService.reserveTickets(
            ticketIDs: ticketIDs,
            eventID: eventID
        )
        
        // Then
        #expect(result.reservationId == "reservation-empty")
        #expect(result.tickets.isEmpty)
        #expect(result.total == 0.00)
    }
    
    // MARK: - getTicket Tests
    
    @Test("Get individual ticket - success")
    func testGetTicketSuccess() async throws {
        // Given
        let mockClient = MockNetworkClient()
        let ticketService = TicketService(networkClient: mockClient)
        let ticketID = "ticket-123"
        
        let expectedTicket = createTestTicket(id: ticketID, section: "VIP", price: 125.00)
        
        await mockClient.setMockResponse(for: .ticket(id: ticketID), response: expectedTicket)
        
        // When
        let result = try await ticketService.getTicket(id: ticketID)
        
        // Then
        #expect(result.id == ticketID)
        #expect(result.section == "VIP")
        #expect(result.price == 125.00)
        #expect(result.available == true)
    }
    
    @Test("Get individual ticket - not found")
    func testGetTicketNotFound() async throws {
        // Given
        let mockClient = MockNetworkClient()
        let ticketService = TicketService(networkClient: mockClient)
        let ticketID = "invalid-ticket-id"
        
        await mockClient.setMockError(for: .ticket(id: ticketID), error: .notFound)
        
        // When & Then
        await #expect(throws: NetworkError.notFound) {
            try await ticketService.getTicket(id: ticketID)
        }
    }
    
    // MARK: - getReservation Tests
    
    @Test("Get reservation - success")
    func testGetReservationSuccess() async throws {
        // Given
        let mockClient = MockNetworkClient()
        let ticketService = TicketService(networkClient: mockClient)
        let reservationID = "reservation-789"
        
        let expectedReservation = createTestReservation(
            id: reservationID,
            total: 200.00
        )
        
        await mockClient.setMockResponse(for: .reservation(id: reservationID), response: expectedReservation)
        
        // When
        let result = try await ticketService.getReservation(id: reservationID)
        
        // Then
        #expect(result.reservationId == reservationID)
        #expect(result.tickets.count == 2)
        #expect(result.total == 200.00)
        #expect(result.expiresAt > Date())
    }
    
    @Test("Get reservation - not found")
    func testGetReservationNotFound() async throws {
        // Given
        let mockClient = MockNetworkClient()
        let ticketService = TicketService(networkClient: mockClient)
        let reservationID = "invalid-reservation-id"
        
        await mockClient.setMockError(for: .reservation(id: reservationID), error: .notFound)
        
        // When & Then
        await #expect(throws: NetworkError.notFound) {
            try await ticketService.getReservation(id: reservationID)
        }
    }
    
    @Test("Get reservation - expired")
    func testGetReservationExpired() async throws {
        // Given
        let mockClient = MockNetworkClient()
        let ticketService = TicketService(networkClient: mockClient)
        let reservationID = "expired-reservation"
        
        let expiredReservation = createTestReservation(
            id: reservationID,
            expiresAt: Date().addingTimeInterval(-300) // 5 minutes ago
        )
        
        await mockClient.setMockResponse(for: .reservation(id: reservationID), response: expiredReservation)
        
        // When
        let result = try await ticketService.getReservation(id: reservationID)
        
        // Then
        #expect(result.reservationId == reservationID)
        #expect(result.expiresAt < Date(), "Reservation should be expired")
    }
    
    // MARK: - cancelReservation Tests
    
    @Test("Cancel reservation - success")
    func testCancelReservationSuccess() async throws {
        // Given
        let mockClient = MockNetworkClient()
        let ticketService = TicketService(networkClient: mockClient)
        let reservationID = "reservation-to-cancel"
        
        // Mock empty response for successful cancellation
        await mockClient.setMockResponse(
            for: .cancelReservation(id: reservationID),
            response: EmptyTestResponse()
        )
        
        // When & Then - Should not throw
        try await ticketService.cancelReservation(id: reservationID)
    }
    
    @Test("Cancel reservation - not found")
    func testCancelReservationNotFound() async throws {
        // Given
        let mockClient = MockNetworkClient()
        let ticketService = TicketService(networkClient: mockClient)
        let reservationID = "invalid-reservation-id"
        
        await mockClient.setMockError(for: .cancelReservation(id: reservationID), error: .notFound)
        
        // When & Then
        await #expect(throws: NetworkError.notFound) {
            try await ticketService.cancelReservation(id: reservationID)
        }
    }
    
    @Test("Cancel reservation - already processed")
    func testCancelReservationAlreadyProcessed() async throws {
        // Given
        let mockClient = MockNetworkClient()
        let ticketService = TicketService(networkClient: mockClient)
        let reservationID = "processed-reservation"
        
        await mockClient.setMockError(for: .cancelReservation(id: reservationID), error: .notFound)

        // When & Then
        await #expect(throws: NetworkError.notFound) {
            try await ticketService.cancelReservation(id: reservationID)
        }
    }
    
    // MARK: - Integration Tests
    
    @Test("Full ticket workflow - reserve and check status")
    func testFullTicketWorkflow() async throws {
        // Given
        let mockClient = MockNetworkClient()
        let ticketService = TicketService(networkClient: mockClient)
        let eventID = "event-workflow"
        let ticketIDs = ["ticket-w1", "ticket-w2"]
        
        // Setup mock responses
        let tickets = [
            createTestTicket(id: "ticket-w1", eventId: eventID, price: 80.00),
            createTestTicket(id: "ticket-w2", eventId: eventID, seat: "13", price: 80.00)
        ]
        
        let reservation = createTestReservation(
            id: "workflow-reservation",
            tickets: tickets,
            total: 160.00
        )
        
        await mockClient.setMockResponse(for: .availableTickets(eventID: eventID), response: tickets)
        await mockClient.setMockResponse(
            for: .reserveTickets(eventID: eventID, ticketIDs: ticketIDs),
            response: reservation
        )
        await mockClient.setMockResponse(
            for: .reservation(id: reservation.reservationId),
            response: reservation
        )
        
        // When
        let availableTickets = try await ticketService.getAvailableTickets(eventID: eventID)
        let ticketReservation = try await ticketService.reserveTickets(
            ticketIDs: ticketIDs,
            eventID: eventID
        )
        let retrievedReservation = try await ticketService.getReservation(id: ticketReservation.reservationId)

        // Then
        #expect(availableTickets.count == 2)
        #expect(ticketReservation.reservationId == "workflow-reservation")
        #expect(ticketReservation.total == 160.00)
        #expect(retrievedReservation.reservationId == ticketReservation.reservationId)
        #expect(retrievedReservation.tickets.count == 2)
    }
    
    @Test("Network delay simulation")
    func testNetworkDelaySimulation() async throws {
        // Given
        let mockClient = MockNetworkClient()
        await mockClient.simulateSlowNetwork(delay: 0.1) // 100ms delay
        let ticketService = TicketService(networkClient: mockClient)
        let eventID = "delay-test-event"
        
        let tickets = [createTestTicket(eventId: eventID)]
        await mockClient.setMockResponse(for: .availableTickets(eventID: eventID), response: tickets)
        
        // When
        let startTime = Date()
        let _ = try await ticketService.getAvailableTickets(eventID: eventID)
        let endTime = Date()
        
        // Then
        let elapsed = endTime.timeIntervalSince(startTime)
        #expect(elapsed >= 0.1, "Should take at least 100ms due to simulated network delay")
    }
}

// MARK: - Helper Types

private struct EmptyTestResponse: Codable {}

