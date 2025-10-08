//
//  RefundStatus.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//
import Foundation

public enum RefundStatus: String, Codable, Sendable {
    case pending
    case approved
    case processed
    case denied
}
