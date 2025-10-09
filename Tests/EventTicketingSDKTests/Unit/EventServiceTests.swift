//
//  EventServiceTests.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//

import Testing
import Foundation
@testable import EventTicketingSDK

@Suite("EventService Tests")
struct EventServiceTests {
    
    // MARK: - Test Data Helpers
    
    private func createTestEvent(id: String = "test-event-1", name: String = "Test Event") -> Event {
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
    
    private func createMultipleTestEvents(count: Int) -> [Event] {
        return (1...count).map { index in
            createTestEvent(id: "event-\(index)", name: "Event \(index)")
        }
    }
    
    private func createEventService(
        mockNetworkClient: MockNetworkClient? = nil,
        cacheManager: CacheManager? = nil
    ) async -> (EventService, MockNetworkClient, CacheManager) {
        let mockClient = mockNetworkClient ?? MockNetworkClient()
        let cache = cacheManager ?? CacheManager()
        let service = EventService(networkClient: mockClient, cacheManager: cache)
        return (service, mockClient, cache)
    }
    
    // MARK: - Fetch Events Tests
    
    @Test("Fetch events from network when cache is empty")
    func fetchEventsFromNetwork() async throws {
        let (service, mockClient, _) = await createEventService()
        let testEvents = createMultipleTestEvents(count: 3)
        
        // Setup mock response
        await mockClient.setMockResponse(for: .events, response: testEvents)
        
        // Fetch events
        let fetchedEvents = try await service.fetchEvents()
        
        // Verify results
        #expect(fetchedEvents.count == 3, "Should return all events from network")
        #expect(fetchedEvents[0].id == "event-1", "Should return correct events")
        
        // Verify network was called
        let wasNetworkCalled = await mockClient.wasRequestMade(to: .events)
        #expect(wasNetworkCalled, "Should make network request when cache is empty")
    }
    
    @Test("Fetch events from cache when available")
    func fetchEventsFromCache() async throws {
        let cacheManager = CacheManager()
        let (service, mockClient, _) = await createEventService(cacheManager: cacheManager)
        let testEvents = createMultipleTestEvents(count: 2)
        
        // Pre-populate cache
        await cacheManager.cacheEvents(testEvents)
        
        // Setup network response (should not be used)
        await mockClient.setMockResponse(for: .events, response: [] as [Event])

        // Fetch events
        let fetchedEvents = try await service.fetchEvents()
        
        // Verify results come from cache
        #expect(fetchedEvents.count == 2, "Should return cached events")
        
        // Verify network was NOT called
        let wasNetworkCalled = await mockClient.wasRequestMade(to: .events)
        #expect(!wasNetworkCalled, "Should not make network request when cache has data")
    }
    
    @Test("Fetch events caches network response")
    func fetchEventsCachesResponse() async throws {
        let cacheManager = CacheManager()
        let (service, mockClient, _) = await createEventService(cacheManager: cacheManager)
        let testEvents = createMultipleTestEvents(count: 2)
        
        // Setup mock response
        await mockClient.setMockResponse(for: .events, response: testEvents)
        
        // Fetch events
        let _ = try await service.fetchEvents()

        // Verify events were cached
        let cachedEvents = await cacheManager.getCachedEvents()
        #expect(cachedEvents?.count == 2, "Should cache fetched events")
        #expect(cachedEvents?[0].id == testEvents[0].id, "Should cache correct events")
    }
    
    @Test("Fetch events handles network error")
    func fetchEventsNetworkError() async throws {
        let (service, mockClient, _) = await createEventService()
        
        // Setup mock error
        await mockClient.setMockError(for: .events, error: .serverError)
        
        // Attempt to fetch events should throw
        await #expect(throws: NetworkError.self) {
            try await service.fetchEvents()
        }
    }
    
    @Test("Fetch events with empty cache fetches from network")
    func fetchEventsEmptyCache() async throws {
        let cacheManager = CacheManager()
        let (service, mockClient, _) = await createEventService(cacheManager: cacheManager)
        let testEvents = createMultipleTestEvents(count: 1)
        
        // Ensure cache is empty
        await cacheManager.clearCache()
        
        // Setup mock response
        await mockClient.setMockResponse(for: .events, response: testEvents)
        
        // Fetch events
        let fetchedEvents = try await service.fetchEvents()
        
        // Verify network was called
        let wasNetworkCalled = await mockClient.wasRequestMade(to: .events)
        #expect(wasNetworkCalled, "Should make network request when cache is empty")
        #expect(fetchedEvents.count == 1, "Should return network events")
    }
    
    // MARK: - Get Single Event Tests
    
    @Test("Get event from cache when available")
    func getEventFromCache() async throws {
        let cacheManager = CacheManager()
        let (service, mockClient, _) = await createEventService(cacheManager: cacheManager)
        let testEvent = createTestEvent(id: "cached-event")
        
        // Pre-populate cache
        await cacheManager.cacheEvent(testEvent)
        
        // Get event
        let fetchedEvent = try await service.getEvent(id: "cached-event")
        
        // Verify results
        #expect(fetchedEvent.id == "cached-event", "Should return cached event")
        #expect(fetchedEvent.name == testEvent.name, "Should return correct event data")
        
        // Verify network was NOT called
        let wasNetworkCalled = await mockClient.wasRequestMade(to: .event(id: "cached-event"))
        #expect(!wasNetworkCalled, "Should not make network request when event is cached")
    }
    
    @Test("Get event from network when not cached")
    func getEventFromNetwork() async throws {
        let (service, mockClient, _) = await createEventService()
        let testEvent = createTestEvent(id: "network-event")
        
        // Setup mock response
        await mockClient.setMockResponse(for: .event(id: "network-event"), response: testEvent)
        
        // Get event
        let fetchedEvent = try await service.getEvent(id: "network-event")
        
        // Verify results
        #expect(fetchedEvent.id == "network-event", "Should return network event")
        #expect(fetchedEvent.name == testEvent.name, "Should return correct event data")
        
        // Verify network was called
        let wasNetworkCalled = await mockClient.wasRequestMade(to: .event(id: "network-event"))
        #expect(wasNetworkCalled, "Should make network request when event not cached")
    }
    
    @Test("Get event caches network response")
    func getEventCachesResponse() async throws {
        let cacheManager = CacheManager()
        let (service, mockClient, _) = await createEventService(cacheManager: cacheManager)
        let testEvent = createTestEvent(id: "cache-test")
        
        // Setup mock response
        await mockClient.setMockResponse(for: .event(id: "cache-test"), response: testEvent)
        
        // Get event
        let _ = try await service.getEvent(id: "cache-test")

        // Verify event was cached
        let cachedEvent = await cacheManager.getCachedEvent(id: "cache-test")
        #expect(cachedEvent != nil, "Should cache fetched event")
        #expect(cachedEvent?.id == "cache-test", "Should cache correct event")
    }
    
    @Test("Get event handles network error")
    func getEventNetworkError() async throws {
        let (service, mockClient, _) = await createEventService()
        
        // Setup mock error
        await mockClient.setMockError(for: .event(id: "error-event"), error: .notFound)
        
        // Attempt to get event should throw
        await #expect(throws: NetworkError.self) {
            try await service.getEvent(id: "error-event")
        }
    }
    
    // MARK: - Search Events Tests
    
    @Test("Search events makes network request")
    func searchEvents() async throws {
        let (service, mockClient, _) = await createEventService()
        let searchResults = [createTestEvent(id: "search-result")]
        
        // Setup mock response
        await mockClient.setMockResponse(for: .searchEvents(query: "rock concert"), response: searchResults)
        
        // Search events
        let results = try await service.searchEvents(query: "rock concert")
        
        // Verify results
        #expect(results.count == 1, "Should return search results")
        #expect(results[0].id == "search-result", "Should return correct search result")
        
        // Verify network was called with correct query
        let wasNetworkCalled = await mockClient.wasRequestMade(to: .searchEvents(query: "rock concert"))
        #expect(wasNetworkCalled, "Should make network request with search query")
    }
    
    @Test("Search events with empty query")
    func searchEventsEmptyQuery() async throws {
        let (service, mockClient, _) = await createEventService()
        
        // Setup mock response for empty query
        await mockClient.setMockResponse(for: .searchEvents(query: ""), response: [Event]())
        
        // Search with empty query
        let results = try await service.searchEvents(query: "")
        
        // Verify results
        #expect(results.isEmpty, "Should return empty results for empty query")
        
        // Verify network was called
        let wasNetworkCalled = await mockClient.wasRequestMade(to: .searchEvents(query: ""))
        #expect(wasNetworkCalled, "Should make network request even with empty query")
    }
    
    @Test("Search events handles network error")
    func searchEventsNetworkError() async throws {
        let (service, mockClient, _) = await createEventService()
        
        // Setup mock error
        await mockClient.setMockError(for: .searchEvents(query: "test"), error: .rateLimited)
        
        // Attempt to search should throw
        await #expect(throws: NetworkError.self) {
            try await service.searchEvents(query: "test")
        }
    }
    
    @Test("Search events with different queries")
    func searchEventsMultipleQueries() async throws {
        let (service, mockClient, _) = await createEventService()
        
        // Setup mock responses for different queries
        await mockClient.setMockResponse(
            for: .searchEvents(query: "jazz"),
            response: [createTestEvent(id: "jazz-event", name: "Jazz Night")]
        )
        await mockClient.setMockResponse(
            for: .searchEvents(query: "rock"),
            response: [createTestEvent(id: "rock-event", name: "Rock Concert")]
        )
        
        // Search for jazz
        let jazzResults = try await service.searchEvents(query: "jazz")
        #expect(jazzResults[0].name == "Jazz Night", "Should return jazz results")
        
        // Search for rock
        let rockResults = try await service.searchEvents(query: "rock")
        #expect(rockResults[0].name == "Rock Concert", "Should return rock results")
        
        // Verify both requests were made
        let jazzCalled = await mockClient.wasRequestMade(to: .searchEvents(query: "jazz"))
        let rockCalled = await mockClient.wasRequestMade(to: .searchEvents(query: "rock"))
        #expect(jazzCalled && rockCalled, "Should make separate requests for different queries")
    }
    
    // MARK: - Stream Updates Tests
    
    @Test("Stream updates yields mock updates")
    func streamUpdates() async throws {
        let (service, mockClient, _) = await createEventService()
        let eventID = "stream-event"
        
        // Setup mock stream updates
        let mockUpdates = [
            EventUpdate(eventID: eventID, type: .ticketsAvailable(count: 50), timestamp: Date()),
            EventUpdate(eventID: eventID, type: .priceChanged(newPrice: 60.00), timestamp: Date().addingTimeInterval(60)),
            EventUpdate(eventID: eventID, type: .soldOut, timestamp: Date().addingTimeInterval(120))
        ]
        await mockClient.setMockStreamUpdates(for: eventID, updates: mockUpdates)
        
        // Stream updates
        var receivedUpdates: [EventUpdate] = []
        let stream = await service.streamUpdates(for: eventID)
        
        for await update in stream {
            receivedUpdates.append(update)
            if receivedUpdates.count >= 3 {
                break
            }
        }
        
        // Verify updates
        #expect(receivedUpdates.count == 3, "Should receive all mock updates")
        
        // Verify update types
        if case .ticketsAvailable(let count) = receivedUpdates[0].type {
            #expect(count == 50, "Should receive correct tickets available update")
        } else {
            #expect(Bool(false), "First update should be tickets available")
        }
        
        if case .priceChanged(let price) = receivedUpdates[1].type {
            #expect(price == 60.00, "Should receive correct price change update")
        } else {
            #expect(Bool(false), "Second update should be price changed")
        }
        
        if case .soldOut = receivedUpdates[2].type {
            // Success - this is the expected case
        } else {
            #expect(Bool(false), "Third update should be sold out")
        }
    }
    
    @Test("Stream updates with no mock data finishes immediately")
    func streamUpdatesNoData() async throws {
        let (service, _, _) = await createEventService()
        let eventID = "no-updates-event"
        
        // Don't set any mock updates
        
        // Stream updates
        var receivedUpdates: [EventUpdate] = []
        let stream = await service.streamUpdates(for: eventID)
        
        for await update in stream {
            receivedUpdates.append(update)
        }
        
        // Verify no updates received
        #expect(receivedUpdates.isEmpty, "Should receive no updates when none are mocked")
    }
    
    // MARK: - Integration Tests
    
    @Test("Integration: Fetch then get individual event uses cache")
    func integrationFetchThenGetUsesCache() async throws {
        let cacheManager = CacheManager()
        let (service, mockClient, _) = await createEventService(cacheManager: cacheManager)
        let testEvents = createMultipleTestEvents(count: 3)
        
        // Setup mock response for events list
        await mockClient.setMockResponse(for: .events, response: testEvents)
        
        // First, fetch all events (should cache them)
        let fetchedEvents = try await service.fetchEvents()
        #expect(fetchedEvents.count == 3, "Should fetch all events")
        
        // Then get individual event (should use cache)
        let individualEvent = try await service.getEvent(id: "event-2")
        #expect(individualEvent.id == "event-2", "Should return correct individual event")
        
        // Verify only the events endpoint was called, not the individual event endpoint
        let eventsEndpointCalled = await mockClient.wasRequestMade(to: .events)
        let individualEventEndpointCalled = await mockClient.wasRequestMade(to: .event(id: "event-2"))
        
        #expect(eventsEndpointCalled, "Should have called events endpoint")
        #expect(!individualEventEndpointCalled, "Should not have called individual event endpoint")
    }
    
    @Test("Integration: Multiple service instances are independent")
    func integrationMultipleServiceInstances() async throws {
        let (service1, mockClient1, _) = await createEventService()
        let (service2, mockClient2, _) = await createEventService()
        
        let event1 = createTestEvent(id: "service1-event")
        let event2 = createTestEvent(id: "service2-event")
        
        // Setup different mock responses for each client
        await mockClient1.setMockResponse(for: .event(id: "service1-event"), response: event1)
        await mockClient2.setMockResponse(for: .event(id: "service2-event"), response: event2)
        
        // Each service should only access its own mock
        let result1 = try await service1.getEvent(id: "service1-event")
        let result2 = try await service2.getEvent(id: "service2-event")
        
        #expect(result1.id == "service1-event", "Service 1 should get its event")
        #expect(result2.id == "service2-event", "Service 2 should get its event")
        
        // Verify each client only received its own request
        let client1Called = await mockClient1.wasRequestMade(to: .event(id: "service1-event"))
        let client2Called = await mockClient2.wasRequestMade(to: .event(id: "service2-event"))
        let client1CalledWrong = await mockClient1.wasRequestMade(to: .event(id: "service2-event"))
        let client2CalledWrong = await mockClient2.wasRequestMade(to: .event(id: "service1-event"))
        
        #expect(client1Called && client2Called, "Each client should receive its own request")
        #expect(!client1CalledWrong && !client2CalledWrong, "Clients should not receive wrong requests")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Handle various network errors gracefully")
    func handleNetworkErrors() async throws {
        let (service, mockClient, _) = await createEventService()
        
        let errorCases: [(Endpoint, NetworkError)] = [
            (.events, .unauthorized),
            (.event(id: "test"), .notFound),
            (.searchEvents(query: "test"), .rateLimited),
            (.events, .serverError)
        ]
        
        for (endpoint, expectedError) in errorCases {
            await mockClient.setMockError(for: endpoint, error: expectedError)
            
            switch endpoint {
            case .events:
                await #expect(throws: NetworkError.self) {
                    try await service.fetchEvents()
                }
            case .event(let id):
                await #expect(throws: NetworkError.self) {
                    try await service.getEvent(id: id)
                }
            case .searchEvents(let query):
                await #expect(throws: NetworkError.self) {
                    try await service.searchEvents(query: query)
                }
            default:
                break
            }
        }
    }
    
    @Test("Offline simulation")
    func offlineSimulation() async throws {
        let (service, mockClient, _) = await createEventService()
        
        // Simulate offline
        await mockClient.simulateOffline()
        
        // All network operations should fail
        await #expect(throws: NetworkError.self) {
            try await service.fetchEvents()
        }
        
        await #expect(throws: NetworkError.self) {
            try await service.getEvent(id: "test")
        }
        
        await #expect(throws: NetworkError.self) {
            try await service.searchEvents(query: "test")
        }
    }
}
