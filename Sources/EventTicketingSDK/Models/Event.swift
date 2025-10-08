//
//  Event.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//
import Foundation

public struct Event: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let venue: Venue
    public let date: Date
    public let doors: Date
    public let imageURL: URL?
    public let ticketTypes: [TicketType]
    public let status: EventStatus

    public enum EventStatus: String, Codable, Sendable {
        case upcoming
        case onSale
        case soldOut
        case cancelled
        case rescheduled
    }
}
