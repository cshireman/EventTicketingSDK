//
//  TicketServiceTests+Factory.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/9/25.
//

@testable import EventTicketingSDK
import Foundation

extension TicketServiceTests {
    internal func createTestTicket(
        id: String = "ticket-1",
        eventId: String = "event-1",
        section: String = "A",
        row: String? = "5",
        seat: String? = "12",
        price: Decimal = 75.00,
        available: Bool = true
    ) -> Ticket {
        let ticketType = TicketType(
            id: "type-1",
            name: "General Admission",
            description: "Standard ticket",
            price: price,
            availableCount: 100
        )

        return Ticket(
            id: id,
            eventId: eventId,
            section: section,
            row: row,
            seat: seat,
            price: price,
            type: ticketType,
            available: available
        )
    }

    internal func createTestReservation(
        id: String = "reservation-1",
        tickets: [Ticket]? = nil,
        expiresAt: Date? = nil,
        total: Decimal = 150.00
    ) -> TicketReservation {
        let testTickets = tickets ?? [
            createTestTicket(id: "ticket-1", price: 75.00),
            createTestTicket(id: "ticket-2", seat: "13", price: 75.00)
        ]

        let expiration = expiresAt ?? Date().addingTimeInterval(900) // 15 minutes from now

        return TicketReservation(
            reservationId: id,
            tickets: testTickets,
            expiresAt: expiration,
            total: total
        )
    }
}
