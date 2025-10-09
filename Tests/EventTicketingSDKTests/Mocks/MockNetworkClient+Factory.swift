//
//  MockNetworkClient+Factory.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/9/25.
//
import Foundation
@testable import EventTicketingSDK

extension MockNetworkClient {

    /// Create mock responses for common test scenarios
    static func withCommonMockData() -> MockNetworkClient {
        let mockClient = MockNetworkClient()

        Task {
            await mockClient.setupCommonMockResponses()
        }

        return mockClient
    }

    func setupCommonMockResponses() {
        // Mock events list
        let events = createMockEvents()
        setMockResponse(for: .events, response: events)

        // Mock individual events
        for event in events {
            setMockResponse(for: .event(id: event.id), response: event)
        }

        // Mock search results
        setMockResponse(for: .searchEvents(query: "test"), response: [events.first!])

        // Mock available tickets
        let tickets = createMockTickets()
        for event in events {
            setMockResponse(for: .availableTickets(eventID: event.id), response: tickets)
        }

        // Mock stream updates
        let updates = createMockEventUpdates(eventId: events.first!.id)
        setMockStreamUpdates(for: events.first!.id, updates: updates)
    }

    func createMockEvents() -> [Event] {
        let venue = Venue(
            id: "venue-1",
            name: "Mock Venue",
            address: "123 Test Street",
            city: "Test City",
            state: "TS",
            capacity: 1000
        )

        let ticketType = TicketType(
            id: "ticket-type-1",
            name: "General Admission",
            description: "Standard ticket",
            price: 50.00,
            availableCount: 100
        )

        return [
            Event(
                id: "event-1",
                name: "Mock Event 1",
                description: "A test event for mocking",
                venue: venue,
                date: Date().addingTimeInterval(86400), // Tomorrow
                doors: Date().addingTimeInterval(86400 - 3600), // 1 hour before
                imageURL: URL(string: "https://example.com/event1.jpg"),
                ticketTypes: [ticketType],
                status: .onSale
            ),
            Event(
                id: "event-2",
                name: "Mock Event 2",
                description: "Another test event",
                venue: venue,
                date: Date().addingTimeInterval(172800), // Day after tomorrow
                doors: Date().addingTimeInterval(172800 - 3600),
                imageURL: URL(string: "https://example.com/event2.jpg"),
                ticketTypes: [ticketType],
                status: .upcoming
            )
        ]
    }

    func createMockTickets() -> [Ticket] {
        let ticketType = TicketType(
            id: "ticket-type-1",
            name: "General Admission",
            description: "Standard ticket",
            price: 50.00,
            availableCount: 100
        )

        return [
            Ticket(
                id: "ticket-1",
                eventId: "event-1",
                section: "General",
                row: nil,
                seat: nil,
                price: 50.00,
                type: ticketType,
                available: true
            ),
            Ticket(
                id: "ticket-2",
                eventId: "event-1",
                section: "General",
                row: nil,
                seat: nil,
                price: 50.00,
                type: ticketType,
                available: true
            )
        ]
    }

    func createMockEventUpdates(eventId: String) -> [EventUpdate] {
        return [
            EventUpdate(
                eventId: eventId,
                type: .ticketsAvailable(count: 50),
                timestamp: Date()
            ),
            EventUpdate(
                eventId: eventId,
                type: .priceChanged(newPrice: 55.00),
                timestamp: Date().addingTimeInterval(60)
            ),
            EventUpdate(
                eventId: eventId,
                type: .soldOut,
                timestamp: Date().addingTimeInterval(120)
            )
        ]
    }
}
