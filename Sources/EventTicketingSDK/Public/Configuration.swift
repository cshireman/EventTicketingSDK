//
//  Configuration.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//
import Foundation

public struct Configuration: Sendable {
    public let baseURL: URL
    public let webSocketURL: URL
    public let apiKey: String
    public let environment: Environment
    public let timeout: TimeInterval

    public enum Environment: Sendable {
        case development
        case staging
        case production
    }

    public static let `default` = Configuration(
        baseURL: URL(string: "http://localhost:8080")!,
        webSocketURL: URL(string: "ws://localhost:8080/ws")!,
        apiKey: "",
        environment: .development,
        timeout: 30,
    )

    public init(
        baseURL: URL,
        webSocketURL: URL? = nil,
        apiKey: String,
        environment: Environment = .production,
        timeout: TimeInterval = 30,
    ) {
        self.baseURL = baseURL
        self.webSocketURL = webSocketURL ?? URL(string: baseURL.absoluteString.replacingOccurrences(of: "http", with: "ws") + "/ws")!
        self.apiKey = apiKey
        self.environment = environment
        self.timeout = timeout
    }
}
