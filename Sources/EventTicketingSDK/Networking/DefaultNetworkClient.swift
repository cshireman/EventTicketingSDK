//
//  DefaultNetworkClient.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/9/25.
//
import Foundation

actor DefaultNetworkClient: NetworkClient {

    internal let session: URLSession
    internal let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: sessionConfig)
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        // Build request
        let request = try buildRequest(for: endpoint)

        // Execute request
        let (data, response) = try await session.data(for: request)

        // Validate response
        try validateResponse(response)

        // Parse response
        return try parseResponse(data: data)
    }

    private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(
            url: configuration.baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        )

        // Add query parameters
        if !endpoint.queryItems.isEmpty {
            components?.queryItems = endpoint.queryItems
        }

        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        // Add headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")

        // Add body if needed
        if let body = endpoint.body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 400:
            throw NetworkError.badRequest
        case 401:
            throw NetworkError.unauthorized
        case 404:
            throw NetworkError.notFound
        case 429:
            throw NetworkError.rateLimited
        case 500...599:
            throw NetworkError.serverError
        default:
            throw NetworkError.unknown(statusCode: httpResponse.statusCode)
        }
    }

    private func parseResponse<T: Decodable>(data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }

    func streamUpdates(eventID: String) -> AsyncStream<EventUpdate> {
        AsyncStream { continuation in
            Task {
                await startWebSocketConnection(eventID: eventID, continuation: continuation)
            }
        }
    }
}
