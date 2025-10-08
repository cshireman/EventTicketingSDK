//
//  OrderService.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//

import Foundation

actor OrderService {

    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    /// Purchase tickets using a reservation and payment method
    func purchaseTickets(
        reservation: TicketReservation,
        paymentMethod: PaymentMethod
    ) async throws -> Order {
        let purchaseRequest = PurchaseRequest(
            reservationID: reservation.reservationID,
            paymentMethod: paymentMethod
        )

        let endpoint = Endpoint.purchaseTicketsWithPayment(purchaseRequest)
        return try await networkClient.request(endpoint)
    }

    /// Get order details by ID
    func getOrder(id: String) async throws -> Order {
        let endpoint = Endpoint.order(id: id)
        return try await networkClient.request(endpoint)
    }

    /// Get all orders for a user (would typically require user authentication)
    func getUserOrders(userID: String) async throws -> [Order] {
        let endpoint = Endpoint.userOrders(userID: userID)
        return try await networkClient.request(endpoint)
    }

    /// Cancel an order (if within cancellation policy)
    func cancelOrder(id: String) async throws -> Order {
        let endpoint = Endpoint.cancelOrder(id: id)
        return try await networkClient.request(endpoint)
    }

    /// Request refund for an order
    func requestRefund(orderID: String, reason: String) async throws -> RefundRequest {
        let refundData = RefundRequestData(reason: reason)
        let endpoint = Endpoint.requestRefundWithData(orderID: orderID, data: refundData)
        return try await networkClient.request(endpoint)
    }

    /// Get refund status
    func getRefundStatus(orderID: String) async throws -> RefundStatus {
        let endpoint = Endpoint.refundStatus(orderID: orderID)
        return try await networkClient.request(endpoint)
    }
}
