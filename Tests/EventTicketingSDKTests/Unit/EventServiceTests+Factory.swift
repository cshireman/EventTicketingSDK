//
//  EventServiceTests+Factory.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/9/25.
//

@testable import EventTicketingSDK
import Foundation

extension EventServiceTests {
    internal func createTestEvent(id: String = "test-event-1", name: String = "Test Event") -> Event {
        let venue = Venue(
            id: "venue-1",
            name: "Test Venue",
            address: "123 Test St",
            city: "Test City",
            state: "TS",
            capacity: 1000
        )

        let ticketType = TicketType(
            id: "ticket-1",
            name: "General Admission",
            description: "Standard ticket",
            price: 50.00,
            availableCount: 100
        )

        return Event(
            id: id,
            name: name,
            description: "A test event",
            venue: venue,
            date: Date().addingTimeInterval(86400), // Tomorrow
            doors: Date().addingTimeInterval(86400 - 3600), // 1 hour before event
            imageURL: URL(string: "https://example.com/image.jpg"),
            ticketTypes: [ticketType],
            status: .onSale
        )
    }

    internal func createMultipleTestEvents(count: Int) -> [Event] {
        return (1...count).map { index in
            createTestEvent(id: "event-\(index)", name: "Event \(index)")
        }
    }

    internal func createEventService(
        mockNetworkClient: MockNetworkClient? = nil,
        cacheManager: CacheManager? = nil
    ) async -> (EventService, MockNetworkClient, CacheManager) {
        let mockClient = mockNetworkClient ?? MockNetworkClient()
        let cache = cacheManager ?? CacheManager()
        let service = EventService(networkClient: mockClient, cacheManager: cache)
        return (service, mockClient, cache)
    }
}
