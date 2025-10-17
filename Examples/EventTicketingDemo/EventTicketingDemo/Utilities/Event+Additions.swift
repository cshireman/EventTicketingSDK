//
//  Event+Additions.swift
//  EventTicketingDemo
//
//  Created by Chris Shireman on 10/13/25.
//

import Foundation
import EventTicketingSDK

extension Event {
    static var empty: Event {
        return Event(id: "1",
                     name: "Sample Event",
                     description: "This is a sample event description.",
                     venue: Venue(id: "v1",
                                  name: "Sample Venue",
                                  address: "123 Main St",
                                  city: "Anytown",
                                  state: "CA",
                                  capacity: 5000),
                     date: Date(),
                     doors: Date(),
                     imageURL: nil,
                     ticketTypes: [],
                     status: .upcoming)
    }

    var hasTicketsAvailable: Bool {
        return !ticketTypes.isEmpty && (status == .onSale || status == .upcoming || status == .rescheduled)
    }
}


