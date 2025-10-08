//
//  PaymentMethod.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//
import Foundation

public struct PaymentMethod: Codable, Sendable {
    public let type: PaymentType
    public let token: String
    
    public enum PaymentType: String, Codable, Sendable {
        case creditCard
        case applePay
        case googlePay
        case paypal
    }
    
    public init(type: PaymentType, token: String) {
        self.type = type
        self.token = token
    }
}
