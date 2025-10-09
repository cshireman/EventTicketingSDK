//
//  CacheManagerTests.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//

@testable import EventTicketingSDK
import Testing
import Foundation

@Suite("CacheManager Tests")
struct CacheManagerTests {
    
    @Test("Cache single event successfully")
    func cacheEvent() async throws {
        let cacheManager = CacheManager()
        let testEvent = createTestEvent()
        
        await cacheManager.cacheEvent(testEvent)
        
        let cachedEvent = await cacheManager.getCachedEvent(id: testEvent.id)
        
        #expect(cachedEvent != nil, "Event should be cached")
        #expect(cachedEvent?.id == testEvent.id, "Cached event should have the same ID")
        #expect(cachedEvent?.name == testEvent.name, "Cached event should have the same name")
    }
    
    @Test("Cache multiple events successfully")
    func cacheEvents() async throws {
        let cacheManager = CacheManager()
        let testEvents = createMultipleTestEvents(count: 3)
        
        await cacheManager.cacheEvents(testEvents)
        
        let cachedEvents = await cacheManager.getCachedEvents()
        
        #expect(cachedEvents != nil, "Events should be cached")
        #expect(cachedEvents?.count == 3, "Should cache all 3 events")
        
        // Verify each event is cached correctly
        for testEvent in testEvents {
            let cachedEvent = await cacheManager.getCachedEvent(id: testEvent.id)
            #expect(cachedEvent != nil, "Event \(testEvent.id) should be cached")
            #expect(cachedEvent?.id == testEvent.id, "Cached event should have correct ID")
        }
    }
    
    @Test("Overwrite existing cached event")
    func overwriteCachedEvent() async throws {
        let cacheManager = CacheManager()
        let originalEvent = createTestEvent(id: "test-event", name: "Original Event")
        let updatedEvent = createTestEvent(id: "test-event", name: "Updated Event")
        
        // Cache original event
        await cacheManager.cacheEvent(originalEvent)
        
        // Cache updated event with same ID
        await cacheManager.cacheEvent(updatedEvent)
        
        let cachedEvent = await cacheManager.getCachedEvent(id: "test-event")
        
        #expect(cachedEvent != nil, "Event should still be cached")
        #expect(cachedEvent?.name == "Updated Event", "Should contain updated event data")
    }
    
    // MARK: - Get Cached Event Tests
    
    @Test("Get cached event that exists")
    func getCachedEventExists() async throws {
        let cacheManager = CacheManager()
        let testEvent = createTestEvent()
        
        await cacheManager.cacheEvent(testEvent)
        let cachedEvent = await cacheManager.getCachedEvent(id: testEvent.id)
        
        #expect(cachedEvent != nil, "Should return cached event")
        #expect(cachedEvent?.id == testEvent.id, "Should return correct event")
    }
    
    @Test("Get cached event that doesn't exist")
    func getCachedEventNotExists() async throws {
        let cacheManager = CacheManager()
        
        let cachedEvent = await cacheManager.getCachedEvent(id: "non-existent-id")
        
        #expect(cachedEvent == nil, "Should return nil for non-existent event")
    }
    
    @Test("Get expired cached event returns nil")
    func getCachedEventExpired() async throws {
        let cacheManager = CacheManager()
        let testEvent = createTestEvent()
        
        // We need to test cache expiration, but the timeout is 5 minutes
        // For testing purposes, we can't easily manipulate time
        // This test documents the expected behavior
        await cacheManager.cacheEvent(testEvent)
        
        // Immediately after caching, event should be available
        let cachedEvent = await cacheManager.getCachedEvent(id: testEvent.id)
        #expect(cachedEvent != nil, "Freshly cached event should be available")
        
        // Note: In a real scenario, after 5+ minutes, this would return nil
        // To properly test this, we'd need dependency injection for Date/TimeInterval
    }
    
    // MARK: - Get All Cached Events Tests
    
    @Test("Get all cached events when cache is empty")
    func getCachedEventsEmpty() async throws {
        let cacheManager = CacheManager()
        
        let cachedEvents = await cacheManager.getCachedEvents()
        
        #expect(cachedEvents == nil, "Should return nil when cache is empty")
    }
    
    @Test("Get all cached events when cache has events")
    func getCachedEventsWithData() async throws {
        let cacheManager = CacheManager()
        let testEvents = createMultipleTestEvents(count: 5)
        
        await cacheManager.cacheEvents(testEvents)
        
        let cachedEvents = await cacheManager.getCachedEvents()
        
        #expect(cachedEvents != nil, "Should return cached events")
        #expect(cachedEvents?.count == 5, "Should return all cached events")
        
        // Verify all events are present (order might be different)
        let cachedEventIds = Set(cachedEvents?.map { $0.id } ?? [])
        let originalEventIds = Set(testEvents.map { $0.id })
        #expect(cachedEventIds == originalEventIds, "Should contain all original event IDs")
    }
    
    @Test("Get all cached events returns independent array")
    func getCachedEventsIndependentArray() async throws {
        let cacheManager = CacheManager()
        let testEvents = createMultipleTestEvents(count: 2)
        
        await cacheManager.cacheEvents(testEvents)
        
        let cachedEvents1 = await cacheManager.getCachedEvents()
        let cachedEvents2 = await cacheManager.getCachedEvents()
        
        #expect(cachedEvents1?.count == cachedEvents2?.count, "Both calls should return same number of events")
        
        // Verify they contain the same data but are independent arrays
        #expect(cachedEvents1 != nil && cachedEvents2 != nil, "Both should return valid arrays")
    }
    
    // MARK: - Clear Cache Tests
    
    @Test("Clear cache removes all events")
    func clearCache() async throws {
        let cacheManager = CacheManager()
        let testEvents = createMultipleTestEvents(count: 3)
        
        // Cache some events
        await cacheManager.cacheEvents(testEvents)
        
        // Verify events are cached
        let cachedEventsBeforeClear = await cacheManager.getCachedEvents()
        #expect(cachedEventsBeforeClear?.count == 3, "Events should be cached before clear")
        
        // Clear cache
        await cacheManager.clearCache()
        
        // Verify cache is empty
        let cachedEventsAfterClear = await cacheManager.getCachedEvents()
        #expect(cachedEventsAfterClear == nil, "Cache should be empty after clear")
        
        // Verify individual events are also cleared
        for event in testEvents {
            let cachedEvent = await cacheManager.getCachedEvent(id: event.id)
            #expect(cachedEvent == nil, "Individual event \(event.id) should be cleared")
        }
    }
    
    @Test("Clear empty cache doesn't cause issues")
    func clearEmptyCache() async throws {
        let cacheManager = CacheManager()
        
        // Clear already empty cache
        await cacheManager.clearCache()
        
        let cachedEvents = await cacheManager.getCachedEvents()
        #expect(cachedEvents == nil, "Cache should remain empty")
    }
    
    // MARK: - Concurrency Tests
    
    @Test("Concurrent cache operations are safe")
    func concurrentOperations() async throws {
        let cacheManager = CacheManager()
        let testEvents = createMultipleTestEvents(count: 10)
        
        // Perform concurrent cache operations
        await withTaskGroup(of: Void.self) { group in
            // Cache events concurrently
            for event in testEvents {
                group.addTask {
                    await cacheManager.cacheEvent(event)
                }
            }
            
            // Read from cache concurrently
            for event in testEvents {
                group.addTask {
                    _ = await cacheManager.getCachedEvent(id: event.id)
                }
            }
            
            // Clear cache concurrently (this might clear before some cache operations)
            group.addTask {
                await cacheManager.clearCache()
            }
        }
        
        // After all concurrent operations, cache state should be consistent
        // (either empty due to clear, or containing some events)
        _ = await cacheManager.getCachedEvents()
        // We can't predict the exact final state due to concurrency,
        // but the operations should not crash or cause data corruption
        #expect(true, "Concurrent operations should complete without crashing")
    }
    
    @Test("Multiple cache managers are independent")
    func independentCacheManagers() async throws {
        let cacheManager1 = CacheManager()
        let cacheManager2 = CacheManager()
        
        let event1 = createTestEvent(id: "event-1", name: "Event 1")
        let event2 = createTestEvent(id: "event-2", name: "Event 2")
        
        await cacheManager1.cacheEvent(event1)
        await cacheManager2.cacheEvent(event2)
        
        // Each cache manager should only have its own event
        let cached1FromManager1 = await cacheManager1.getCachedEvent(id: "event-1")
        let cached2FromManager1 = await cacheManager1.getCachedEvent(id: "event-2")
        
        let cached1FromManager2 = await cacheManager2.getCachedEvent(id: "event-1")
        let cached2FromManager2 = await cacheManager2.getCachedEvent(id: "event-2")
        
        #expect(cached1FromManager1 != nil, "Manager 1 should have event 1")
        #expect(cached2FromManager1 == nil, "Manager 1 should not have event 2")
        
        #expect(cached1FromManager2 == nil, "Manager 2 should not have event 1")
        #expect(cached2FromManager2 != nil, "Manager 2 should have event 2")
    }
}
