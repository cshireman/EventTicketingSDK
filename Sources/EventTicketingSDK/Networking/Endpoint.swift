//
//  Endpoint.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//
import Foundation

enum Endpoint {
    case events
    case event(id: String)
    case searchEvents(query: String)
    case availableTickets(eventID: String)
    case reserveTickets(eventID: String, ticketIDs: [String])
    case purchaseTickets(reservationID: String)
    
    // Ticket endpoints
    case ticket(id: String)
    case reservation(id: String)
    case cancelReservation(id: String)
    
    // Order endpoints
    case purchaseTicketsWithPayment(PurchaseRequest)
    case order(id: String)
    case userOrders(userID: String)
    case cancelOrder(id: String)
    case requestRefundWithData(orderID: String, data: RefundRequestData)
    case refundStatus(orderID: String)

    var path: String {
        switch self {
        case .events:
            return "/api/v1/events"
        case .event(let id):
            return "/api/v1/events/\(id)"
        case .searchEvents:
            return "/api/v1/events/search"
        case .availableTickets(let eventID):
            return "/api/v1/events/\(eventID)/tickets"
        case .reserveTickets(let eventID, _):
            return "/api/v1/events/\(eventID)/reserve"
        case .purchaseTickets:
            return "/api/v1/orders"
        case .ticket(let id):
            return "/api/v1/tickets/\(id)"
        case .reservation(let id):
            return "/api/v1/reservations/\(id)"
        case .cancelReservation(let id):
            return "/api/v1/reservations/\(id)/cancel"
        case .purchaseTicketsWithPayment:
            return "/api/v1/orders"
        case .order(let id):
            return "/api/v1/orders/\(id)"
        case .userOrders(let userID):
            return "/api/v1/users/\(userID)/orders"
        case .cancelOrder(let id):
            return "/api/v1/orders/\(id)/cancel"
        case .requestRefundWithData(let orderID, _):
            return "/api/v1/orders/\(orderID)/refund"
        case .refundStatus(let orderID):
            return "/api/v1/orders/\(orderID)/refund/status"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .events, .event, .searchEvents, .availableTickets, .ticket, .reservation, .order, .userOrders, .refundStatus:
            return .get
        case .reserveTickets, .purchaseTickets, .purchaseTicketsWithPayment, .requestRefundWithData:
            return .post
        case .cancelReservation, .cancelOrder:
            return .delete
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .searchEvents(let query):
            return [URLQueryItem(name: "q", value: query)]
        default:
            return []
        }
    }

    var body: Encodable? {
        switch self {
        case .reserveTickets(_, let ticketIDs):
            return ["ticket_ids": ticketIDs]
        case .purchaseTicketsWithPayment(let request):
            return request
        case .requestRefundWithData(_, let data):
            return data
        default:
            return nil
        }
    }
}

// MARK: - Supporting Types

struct PurchaseRequest: Codable {
    let reservationID: String
    let paymentMethod: PaymentMethod
}

struct RefundRequestData: Codable {
    let reason: String
}
