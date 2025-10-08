//
//  NetworkError.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//
import Foundation

public enum NetworkError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case badRequest
    case unauthorized
    case notFound
    case rateLimited
    case serverError
    case decodingFailed(Error)
    case unknown(statusCode: Int)
    case noConnection

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .badRequest:
            return "Bad request"
        case .unauthorized:
            return "Unauthorized - check your API key"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Rate limit exceeded"
        case .serverError:
            return "Server error"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unknown(let statusCode):
            return "Unknown error (status code: \(statusCode))"
        case .noConnection:
            return "No internet connection"
        }
    }
}
