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

    public init(
        id: String,
        name: String,
        description: String,
        venue: Venue,
        date: Date,
        doors: Date,
        imageURL: URL?,
        ticketTypes: [TicketType],
        status: EventStatus
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.venue = venue
        self.date = date
        self.doors = doors
        self.imageURL = imageURL
        self.ticketTypes = ticketTypes
        self.status = status
    }
}
