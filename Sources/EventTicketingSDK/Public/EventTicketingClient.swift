//
//  EventTicketingClient.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//

@MainActor
public final class EventTicketingClient: Sendable {

    public static var shared = EventTicketingClient()

    private let eventService: EventService
    private let ticketService: TicketService
    private let orderService: OrderService

    private init(_ config: Configuration = .default) {
        let networkClient = DefaultNetworkClient(configuration: config)
        let cacheManager = CacheManager()

        self.eventService = EventService(
            networkClient: networkClient,
            cacheManager: cacheManager
        )
        self.ticketService = TicketService(
            networkClient: networkClient
        )
        self.orderService = OrderService(
            networkClient: networkClient
        )
    }

    public static func configure(_ config: Configuration) {
        EventTicketingClient.shared = .init(config)
    }

    // MARK: - Public API

    /// Fetch all available events
    public func fetchEvents() async throws -> [Event] {
        try await eventService.fetchEvents()
    }

    /// Get event details by ID
    public func getEvent(id: String) async throws -> Event {
        try await eventService.getEvent(id: id)
    }

    /// Search events by query
    public func searchEvents(query: String) async throws -> [Event] {
        try await eventService.searchEvents(query: query)
    }

    /// Get available tickets for an event
    public func getAvailableTickets(eventID: String) async throws -> [Ticket] {
        try await ticketService.getAvailableTickets(eventID: eventID)
    }

    /// Reserve tickets (holds for X minutes)
    public func reserveTickets(ticketIDs: [String], eventID: String) async throws -> TicketReservation {
        try await ticketService.reserveTickets(
            ticketIDs: ticketIDs,
            eventID: eventID
        )
    }

    /// Purchase tickets
    public func purchaseTickets(reservation: TicketReservation, paymentMethod: PaymentMethod) async throws -> Order {
        try await orderService.purchaseTickets(
            reservation: reservation,
            paymentMethod: paymentMethod
        )
    }

    /// Stream real-time event updates
    public func eventUpdates(for eventID: String) async -> AsyncStream<EventUpdate> {
        await eventService.streamUpdates(for: eventID)
    }
}
