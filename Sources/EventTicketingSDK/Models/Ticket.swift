//
//  Ticket.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//
import Foundation

public struct Ticket: Codable, Identifiable, Sendable {
    public let id: String
    public let eventID: String
    public let section: String
    public let row: String?
    public let seat: String?
    public let price: Decimal
    public let type: TicketType
    public let available: Bool
}
