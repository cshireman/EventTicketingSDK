//
//  EventService.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//

actor EventService {

    private let networkClient: any NetworkClient
    private let cacheManager: CacheManager

    init(networkClient: any NetworkClient, cacheManager: CacheManager) {
        self.networkClient = networkClient
        self.cacheManager = cacheManager
    }

    func fetchEvents() async throws -> [Event] {
        // Try cache first
        if let cached = await cacheManager.getCachedEvents(),
           !cached.isEmpty {
            return cached
        }

        // Fetch from network
        let endpoint = Endpoint.events
        let events: [Event] = try await networkClient.request(endpoint)

        // Update cache
        await cacheManager.cacheEvents(events)

        return events
    }

    func getEvent(id: String) async throws -> Event {
        // Check cache
        if let cached = await cacheManager.getCachedEvent(id: id) {
            return cached
        }

        // Fetch from network
        let endpoint = Endpoint.event(id: id)
        let event: Event = try await networkClient.request(endpoint)

        // Update cache
        await cacheManager.cacheEvent(event)

        return event
    }

    func searchEvents(query: String) async throws -> [Event] {
        let endpoint = Endpoint.searchEvents(query: query)
        return try await networkClient.request(endpoint)
    }

    func streamUpdates(for eventID: String) -> AsyncStream<EventUpdate> {
        AsyncStream { continuation in
            // WebSocket or Server-Sent Events implementation
            Task {
                // Simplified example
                for await update in await networkClient.streamUpdates(eventID: eventID) {
                    continuation.yield(update)
                }
                continuation.finish()
            }
        }
    }
}
