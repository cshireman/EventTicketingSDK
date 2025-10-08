//
//  TicketType.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//

import Foundation

public struct TicketType: Codable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let price: Decimal
    public let availableCount: Int
}
