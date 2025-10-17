//
//  TicketType.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//

import Foundation

public struct TicketType: Codable, Sendable, Hashable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let price: Decimal
    public let availableCount: Int

    public init(id: String, name: String, description: String, price: Decimal, availableCount: Int) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.availableCount = availableCount
    }
}
