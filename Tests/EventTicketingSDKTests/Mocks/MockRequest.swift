//
//  MockRequest.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/9/25.
//
@testable import EventTicketingSDK
import Foundation

struct MockRequest: Sendable {
    let endpointKey: String
    let endpoint: Endpoint
    let timestamp: Date
}
