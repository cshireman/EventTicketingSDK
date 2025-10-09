//
//  RefundRequest.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//
import Foundation

public struct RefundRequest: Codable, Identifiable, Sendable {
    public let id: String
    public let orderId: String
    public let amount: Decimal
    public let reason: String
    public let status: RefundStatus
    public let requestDate: Date
}
