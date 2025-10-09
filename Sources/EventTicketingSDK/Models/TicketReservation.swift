//
//  TicketReservation.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//
import Foundation

public struct TicketReservation: Codable, Sendable {
    public let reservationId: String
    public let tickets: [Ticket]
    public let expiresAt: Date
    public let total: Decimal
}
