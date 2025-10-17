//
//  EventDetailViewModel.swift
//  EventTicketingDemo
//
//  Created by Chris Shireman on 10/17/25.
//

import Foundation
import Combine
import EventTicketingSDK

@Observable
class EventDetailViewModel {
    var event: Event

    var eventName: String {
        return event.name
    }

    var eventDate: String {
        return event.date.formatted(date: .abbreviated, time: .shortened)
    }

    var doorsDate: String {
        return event.doors.formatted(date: .omitted, time: .shortened)
    }

    var eventStatus: String {
        return event.status.rawValue.capitalized
    }

    var eventDescription: String {
        return event.description
    }

    var venueName: String {
        return event.venue.name
    }

    var venueAddress: String {
        return "\(event.venue.address)\n\(event.venue.city), \(event.venue.state)"
    }

    var capacity: Int {
        return event.venue.capacity
    }

    var ticketTypes: [TicketType] {
        return event.ticketTypes
    }

    var hasTicketsAvailable: Bool {
        return event.hasTicketsAvailable
    }

    init(event: Event) {
        self.event = event
    }
}
