//
//  OrderServiceTests.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/8/25.
//

import Testing
import Foundation
@testable import EventTicketingSDK

@Suite("OrderService Tests")
struct OrderServiceTests {
    
    // MARK: - Test Data Helpers
    
    private func createTestTicketType(id: String = "ticket-type-1") -> TicketType {
        TicketType(
            id: id,
            name: "General Admission",
            description: "Standard ticket",
            price: 50.00,
            availableCount: 100
        )
    }
    
    private func createTestTicket(id: String = "ticket-1", eventID: String = "event-1") -> Ticket {
        Ticket(
            id: id,
            eventId: eventID,
            section: "A",
            row: "1",
            seat: "15",
            price: 50.00,
            type: createTestTicketType(),
            available: true
        )
    }
    
    private func createTestTicketReservation(reservationID: String = "reservation-1", eventID: String = "event-1") -> TicketReservation {
        TicketReservation(
            reservationID: reservationID,
            tickets: [createTestTicket(eventID: eventID)],
            expiresAt: Date().addingTimeInterval(900), // 15 minutes from now
            total: 50.00
        )
    }
    
    private func createTestPaymentMethod(type: PaymentMethod.PaymentType = .creditCard) -> PaymentMethod {
        PaymentMethod(type: type, token: "test-payment-token")
    }
    
    private func createTestOrder(id: String = "order-1", eventID: String = "event-1", status: Order.OrderStatus = .confirmed) -> Order {
        Order(
            id: id,
            tickets: [createTestTicket(id: "ticket-\(id)", eventID: eventID)],
            total: 50.00,
            status: status,
            purchaseDate: Date(),
            qrCode: "QR123456789"
        )
    }
    
    private func createTestRefundRequest(id: String = "refund-1", orderID: String = "order-1", reason: String = "Event cancelled") -> RefundRequest {
        RefundRequest(
            id: id,
            orderId: orderID,
            amount: 50.00,
            reason: reason,
            status: .pending,
            requestDate: Date()
        )
    }
    
    // MARK: - Purchase Tickets Tests
    
    @Test("Purchase tickets successfully")
    func purchaseTicketsSuccess() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let eventID = "test-event-1"
        let reservation = createTestTicketReservation(eventID: eventID)
        let paymentMethod = createTestPaymentMethod()
        let expectedOrder = createTestOrder(eventID: eventID)
        
        await mockClient.setMockResponse(for: .purchaseTicketsWithPayment(
            PurchaseRequest(reservationID: reservation.reservationID, paymentMethod: paymentMethod)
        ), response: expectedOrder)
        
        // Act
        let result = try await orderService.purchaseTickets(
            reservation: reservation,
            paymentMethod: paymentMethod
        )
        
        // Assert
        #expect(result.id == expectedOrder.id)
        #expect(result.total == expectedOrder.total)
        #expect(result.status == .confirmed)
        #expect(result.tickets.count == 1)
        #expect(result.qrCode == expectedOrder.qrCode)
    }
    
    @Test("Purchase tickets with Apple Pay")
    func purchaseTicketsWithApplePay() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let eventID = "test-event-2"
        let reservation = createTestTicketReservation(eventID: eventID)
        let paymentMethod = createTestPaymentMethod(type: .applePay)
        let expectedOrder = createTestOrder(eventID: eventID)
        
        await mockClient.setMockResponse(for: .purchaseTicketsWithPayment(
            PurchaseRequest(reservationID: reservation.reservationID, paymentMethod: paymentMethod)
        ), response: expectedOrder)
        
        // Act
        let result = try await orderService.purchaseTickets(
            reservation: reservation,
            paymentMethod: paymentMethod
        )
        
        // Assert
        #expect(result.id == expectedOrder.id)
        #expect(result.status == .confirmed)
    }
    
    @Test("Purchase tickets fails with network error")
    func purchaseTicketsNetworkError() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let reservation = createTestTicketReservation()
        let paymentMethod = createTestPaymentMethod()
        
        await mockClient.setMockError(for: .purchaseTicketsWithPayment(
            PurchaseRequest(reservationID: reservation.reservationID, paymentMethod: paymentMethod)
        ), error: .serverError)
        
        // Act & Assert
        await #expect(throws: NetworkError.self) {
            try await orderService.purchaseTickets(
                reservation: reservation,
                paymentMethod: paymentMethod
            )
        }
    }
    
    @Test("Purchase tickets fails with payment declined")
    func purchaseTicketsPaymentDeclined() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let reservation = createTestTicketReservation()
        let paymentMethod = createTestPaymentMethod()
        
        await mockClient.setMockError(for: .purchaseTicketsWithPayment(
            PurchaseRequest(reservationID: reservation.reservationID, paymentMethod: paymentMethod)
        ), error: .serverError)
        
        // Act & Assert
        await #expect(throws: NetworkError.self) {
            try await orderService.purchaseTickets(
                reservation: reservation,
                paymentMethod: paymentMethod
            )
        }
    }
    
    // MARK: - Get Order Tests
    
    @Test("Get order by ID successfully")
    func getOrderSuccess() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let orderID = "test-order-1"
        let eventID = "test-event-1"
        let expectedOrder = createTestOrder(id: orderID, eventID: eventID)
        
        await mockClient.setMockResponse(for: .order(id: orderID), response: expectedOrder)
        
        // Act
        let result = try await orderService.getOrder(id: orderID)
        
        // Assert
        #expect(result.id == orderID)
        #expect(result.status == .confirmed)
        #expect(result.total == 50.00)
    }
    
    @Test("Get order fails with not found error")
    func getOrderNotFound() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let orderID = "nonexistent-order"
        
        await mockClient.setMockError(for: .order(id: orderID), error: .notFound)
        
        // Act & Assert
        await #expect(throws: NetworkError.self) {
            try await orderService.getOrder(id: orderID)
        }
    }
    
    // MARK: - Get User Orders Tests
    
    @Test("Get user orders successfully")
    func getUserOrdersSuccess() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let userID = "user-123"
        let eventID = "test-event-1"
        let expectedOrders = [
            createTestOrder(id: "order-1", eventID: eventID),
            createTestOrder(id: "order-2", eventID: eventID),
            createTestOrder(id: "order-3", eventID: eventID, status: .cancelled)
        ]
        
        await mockClient.setMockResponse(for: .userOrders(userID: userID), response: expectedOrders)
        
        // Act
        let result = try await orderService.getUserOrders(userID: userID)
        
        // Assert
        #expect(result.count == 3)
        #expect(result[0].id == "order-1")
        #expect(result[1].id == "order-2")
        #expect(result[2].id == "order-3")
        #expect(result[2].status == .cancelled)
    }
    
    @Test("Get user orders returns empty array")
    func getUserOrdersEmpty() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let userID = "user-no-orders"
        let expectedOrders: [Order] = []
        
        await mockClient.setMockResponse(for: .userOrders(userID: userID), response: expectedOrders)
        
        // Act
        let result = try await orderService.getUserOrders(userID: userID)
        
        // Assert
        #expect(result.isEmpty)
    }
    
    // MARK: - Cancel Order Tests
    
    @Test("Cancel order successfully")
    func cancelOrderSuccess() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let orderID = "order-to-cancel"
        let eventID = "test-event-1"
        let cancelledOrder = createTestOrder(id: orderID, eventID: eventID, status: .cancelled)
        
        await mockClient.setMockResponse(for: .cancelOrder(id: orderID), response: cancelledOrder)
        
        // Act
        let result = try await orderService.cancelOrder(id: orderID)
        
        // Assert
        #expect(result.id == orderID)
        #expect(result.status == .cancelled)
    }
    
    @Test("Cancel order fails when order cannot be cancelled")
    func cancelOrderNotAllowed() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let orderID = "order-cannot-cancel"
        
        await mockClient.setMockError(for: .cancelOrder(id: orderID), 
                                     error: .unauthorized)
        
        // Act & Assert
        await #expect(throws: NetworkError.self) {
            try await orderService.cancelOrder(id: orderID)
        }
    }
    
    @Test("Cancel nonexistent order fails")
    func cancelNonexistentOrder() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let orderID = "nonexistent-order"
        
        await mockClient.setMockError(for: .cancelOrder(id: orderID), 
                                     error: .notFound)
        
        // Act & Assert
        await #expect(throws: NetworkError.self) {
            try await orderService.cancelOrder(id: orderID)
        }
    }
    
    // MARK: - Request Refund Tests
    
    @Test("Request refund successfully")
    func requestRefundSuccess() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let orderID = "order-for-refund"
        let reason = "Event was cancelled"
        let expectedRefundRequest = createTestRefundRequest(id: "refund-123", orderID: orderID, reason: reason)
        
        await mockClient.setMockResponse(
            for: .requestRefundWithData(orderID: orderID, data: RefundRequestData(reason: reason)),
            response: expectedRefundRequest
        )
        
        // Act
        let result = try await orderService.requestRefund(orderID: orderID, reason: reason)
        
        // Assert
        #expect(result.orderId == orderID)
        #expect(result.reason == reason)
        #expect(result.status == .pending)
        #expect(result.amount == 50.00)
    }
    
    @Test("Request refund with different reasons")
    func requestRefundDifferentReasons() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let orderID = "order-for-refund"
        let reasons = ["Event cancelled", "Unable to attend", "Duplicate purchase"]
        
        for (index, reason) in reasons.enumerated() {
            let refundRequest = RefundRequest(
                id: "refund-\(index + 1)",
                orderId: orderID,
                amount: 50.00,
                reason: reason,
                status: .pending,
                requestDate: Date()
            )
            
            await mockClient.setMockResponse(
                for: .requestRefundWithData(orderID: orderID, data: RefundRequestData(reason: reason)),
                response: refundRequest
            )
            
            // Act
            let result = try await orderService.requestRefund(orderID: orderID, reason: reason)
            
            // Assert
            #expect(result.reason == reason)
            #expect(result.status == .pending)
        }
    }
    
    @Test("Request refund fails for ineligible order")
    func requestRefundIneligible() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let orderID = "ineligible-order"
        let reason = "Changed my mind"
        
        await mockClient.setMockError(
            for: .requestRefundWithData(orderID: orderID, data: RefundRequestData(reason: reason)),
            error: .unauthorized
        )
        
        // Act & Assert
        await #expect(throws: NetworkError.self) {
            try await orderService.requestRefund(orderID: orderID, reason: reason)
        }
    }
    
    // MARK: - Get Refund Status Tests
    
    @Test("Get refund status successfully")
    func getRefundStatusSuccess() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let orderID = "order-with-refund"
        let expectedStatus = RefundStatus.approved
        
        await mockClient.setMockResponse(for: .refundStatus(orderID: orderID), response: expectedStatus)
        
        // Act
        let result = try await orderService.getRefundStatus(orderID: orderID)
        
        // Assert
        #expect(result == .approved)
    }
    
    @Test("Get refund status for different statuses")
    func getRefundStatusVariousStates() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let statuses: [RefundStatus] = [.pending, .approved, .processed, .denied]
        
        for (index, status) in statuses.enumerated() {
            let orderID = "order-\(index + 1)"
            await mockClient.setMockResponse(for: .refundStatus(orderID: orderID), response: status)
            
            // Act
            let result = try await orderService.getRefundStatus(orderID: orderID)
            
            // Assert
            #expect(result == status)
        }
    }
    
    @Test("Get refund status fails for order without refund")
    func getRefundStatusNoRefund() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let orderID = "order-no-refund"
        
        await mockClient.setMockError(for: .refundStatus(orderID: orderID), 
                                     error: .notFound)
        
        // Act & Assert
        await #expect(throws: NetworkError.self) {
            try await orderService.getRefundStatus(orderID: orderID)
        }
    }
    
    // MARK: - Integration Tests
    
    @Test("Complete order workflow: purchase, get, cancel")
    func completeOrderWorkflow() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let eventID = "workflow-event"
        let reservation = createTestTicketReservation(reservationID: "workflow-reservation", eventID: eventID)
        let paymentMethod = createTestPaymentMethod()
        let orderID = "workflow-order"
        
        // Setup mock responses for the workflow
        let confirmedOrder = createTestOrder(id: orderID, eventID: eventID, status: .confirmed)
        let cancelledOrder = createTestOrder(id: orderID, eventID: eventID, status: .cancelled)
        
        await mockClient.setMockResponse(
            for: .purchaseTicketsWithPayment(
                PurchaseRequest(reservationID: reservation.reservationID, paymentMethod: paymentMethod)
            ),
            response: confirmedOrder
        )
        await mockClient.setMockResponse(for: .order(id: orderID), response: confirmedOrder)
        await mockClient.setMockResponse(for: .cancelOrder(id: orderID), response: cancelledOrder)
        
        // Act & Assert - Purchase
        let purchasedOrder = try await orderService.purchaseTickets(
            reservation: reservation,
            paymentMethod: paymentMethod
        )
        #expect(purchasedOrder.status == .confirmed)
        
        // Act & Assert - Get order
        let fetchedOrder = try await orderService.getOrder(id: orderID)
        #expect(fetchedOrder.id == orderID)
        #expect(fetchedOrder.status == .confirmed)
        
        // Act & Assert - Cancel order
        let finalOrder = try await orderService.cancelOrder(id: orderID)
        #expect(finalOrder.id == orderID)
        #expect(finalOrder.status == .cancelled)
    }
    
    @Test("Complete refund workflow: request and check status")
    func completeRefundWorkflow() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let orderID = "refund-workflow-order"
        let reason = "Event was postponed"
        let refundRequest = createTestRefundRequest(id: "refund-workflow-123", orderID: orderID, reason: reason)
        
        await mockClient.setMockResponse(
            for: .requestRefundWithData(orderID: orderID, data: RefundRequestData(reason: reason)),
            response: refundRequest
        )
        await mockClient.setMockResponse(for: .refundStatus(orderID: orderID), response: RefundStatus.pending)
        
        // Act & Assert - Request refund
        let requestResult = try await orderService.requestRefund(orderID: orderID, reason: reason)
        #expect(requestResult.orderId == orderID)
        #expect(requestResult.reason == reason)
        #expect(requestResult.status == .pending)
        
        // Act & Assert - Check status
        let statusResult = try await orderService.getRefundStatus(orderID: orderID)
        #expect(statusResult == .pending)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Handle server error gracefully")
    func handleServerError() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let orderID = "timeout-order"
        
        await mockClient.setMockError(for: .order(id: orderID), error: .serverError)
        
        // Act & Assert
        await #expect(throws: NetworkError.self) {
            try await orderService.getOrder(id: orderID)
        }
    }
    
    @Test("Handle server maintenance")
    func handleServerMaintenance() async throws {
        // Arrange
        let mockClient = MockNetworkClient()
        let orderService = OrderService(networkClient: mockClient)
        
        let userID = "maintenance-user"
        
        await mockClient.setMockError(for: .userOrders(userID: userID), 
                                     error: .serverError)
        
        // Act & Assert
        await #expect(throws: NetworkError.self) {
            try await orderService.getUserOrders(userID: userID)
        }
    }
}

