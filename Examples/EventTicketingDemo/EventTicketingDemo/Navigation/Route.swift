//
//  Routes.swift
//  EventTicketingDemo
//
//  Created by Chris Shireman on 10/17/25.
//
import Foundation
import EventTicketingSDK

enum Route {
    case eventList
    case eventDetail(event: Event)
    case ticketSelection(event: Event)
    case checkout(reservation: TicketReservation)

    public var name: String {
        switch self {
        case .eventList:
            return "eventList"
        case .eventDetail:
            return "eventDetail"
        case .ticketSelection:
            return "ticketSelection"
        case .checkout:
            return "checkout"
        }
    }
}

extension Route: Equatable {
    static func == (lhs: Route, rhs: Route) -> Bool {
        return lhs.name == rhs.name
    }
}

extension Route: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
    }
}
