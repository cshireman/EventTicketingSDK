//
//  Order.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//

import Foundation

public struct Order: Codable, Identifiable, Sendable {
    public let id: String
    public let tickets: [Ticket]
    public let total: Decimal
    public let status: OrderStatus
    public let purchaseDate: Date
    public let qrCode: String

    public enum OrderStatus: String, Codable, Sendable {
        case pending
        case confirmed
        case cancelled
        case refunded
    }
}
