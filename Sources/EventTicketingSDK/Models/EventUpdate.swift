//
//  EventUpdate.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//
import Foundation

public struct EventUpdate: Sendable {
    public let eventID: String
    public let type: UpdateType
    public let timestamp: Date
    
    public enum UpdateType: Sendable {
        case ticketsAvailable(count: Int)
        case soldOut
        case priceChanged(newPrice: Decimal)
        case rescheduled(newDate: Date)
        case cancelled
    }
}
