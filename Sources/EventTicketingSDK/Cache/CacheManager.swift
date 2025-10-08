//
//  CacheManager.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//
import Foundation

actor CacheManager {

    private var eventCache: [String: Event] = [:]
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes

    func getCachedEvents() -> [Event]? {
        let allEvents = Array(eventCache.values)
        return allEvents.isEmpty ? nil : allEvents
    }

    func getCachedEvent(id: String) -> Event? {
        guard let timestamp = cacheTimestamps[id],
              Date().timeIntervalSince(timestamp) < cacheTimeout else {
            return nil
        }
        return eventCache[id]
    }

    func cacheEvents(_ events: [Event]) {
        let now = Date()
        for event in events {
            eventCache[event.id] = event
            cacheTimestamps[event.id] = now
        }
    }

    func cacheEvent(_ event: Event) {
        eventCache[event.id] = event
        cacheTimestamps[event.id] = Date()
    }

    func clearCache() {
        eventCache.removeAll()
        cacheTimestamps.removeAll()
    }
}
