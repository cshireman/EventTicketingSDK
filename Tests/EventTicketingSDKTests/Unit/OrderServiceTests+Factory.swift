//
//  OrderServiceTests+Factory.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/9/25.
//

@testable import EventTicketingSDK
import Foundation

extension OrderServiceTests {

    internal func createTestTicketType(id: String = "ticket-type-1") -> TicketType {
        TicketType(
            id: id,
            name: "General Admission",
            description: "Standard ticket",
            price: 50.00,
            availableCount: 100
        )
    }

    internal func createTestTicket(id: String = "ticket-1", eventID: String = "event-1") -> Ticket {
        Ticket(
            id: id,
            eventId: eventID,
            section: "A",
            row: "1",
            seat: "15",
            price: 50.00,
            type: createTestTicketType(),
            available: true
        )
    }

    internal func createTestTicketReservation(reservationID: String = "reservation-1", eventID: String = "event-1") -> TicketReservation {
        TicketReservation(
            reservationId: reservationID,
            tickets: [createTestTicket(eventID: eventID)],
            expiresAt: Date().addingTimeInterval(900), // 15 minutes from now
            total: 50.00
        )
    }

    internal func createTestPaymentMethod(type: PaymentMethod.PaymentType = .creditCard) -> PaymentMethod {
        PaymentMethod(type: type, token: "test-payment-token")
    }

    internal func createTestOrder(id: String = "order-1", eventID: String = "event-1", status: Order.OrderStatus = .confirmed) -> Order {
        Order(
            id: id,
            tickets: [createTestTicket(id: "ticket-\(id)", eventID: eventID)],
            total: 50.00,
            status: status,
            purchaseDate: Date(),
            qrCode: "QR123456789"
        )
    }

    internal func createTestRefundRequest(id: String = "refund-1", orderID: String = "order-1", reason: String = "Event cancelled") -> RefundRequest {
        RefundRequest(
            id: id,
            orderId: orderID,
            amount: 50.00,
            reason: reason,
            status: .pending,
            requestDate: Date()
        )
    }

}
