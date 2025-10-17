//
//  Venue.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//
import Foundation

public struct Venue: Codable, Sendable, Identifiable, Hashable, Equatable {
    public let id: String
    public let name: String
    public let address: String
    public let city: String
    public let state: String
    public let capacity: Int

    public init(id: String, name: String, address: String, city: String, state: String, capacity: Int) {
        self.id = id
        self.name = name
        self.address = address
        self.city = city
        self.state = state
        self.capacity = capacity
    }
}
