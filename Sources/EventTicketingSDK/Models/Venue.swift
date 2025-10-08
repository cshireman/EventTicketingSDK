//
//  Venue.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//
import Foundation

public struct Venue: Codable, Sendable {
    public let id: String
    public let name: String
    public let address: String
    public let city: String
    public let state: String
    public let capacity: Int
}
