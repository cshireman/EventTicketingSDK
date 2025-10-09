//
//  NetworkClient.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//
import Foundation

protocol NetworkClient: Actor {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func streamUpdates(eventID: String) -> AsyncStream<EventUpdate>
}
