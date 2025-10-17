//
//  CheckoutViewModel.swift
//  EventTicketingDemo
//
//  Created by Chris Shireman on 10/14/25.
//

import SwiftUI
import Combine
import Foundation
import EventTicketingSDK

@Observable
class CheckoutViewModel {
    var reservation: TicketReservation?
    var event: Event?
    
    var isLoading: Bool = false
    var isCompleted: Bool = false
    var showError: Bool = false
    var errorMessage: String = ""
    var order: Order?
    
    init(reservation: TicketReservation? = nil) {
        self.reservation = reservation
    }

    var formattedPrice: String {
        return (reservation?.total ?? 0).formatted(as: true)
    }

    @MainActor
    func loadEventDetails() async {
        guard let reservation = reservation,
              let firstTicket = reservation.tickets.first else { return }
        
        isLoading = true
        
        do {
            event = try await EventTicketingClient.shared.getEvent(id: firstTicket.eventId)
        } catch {
            errorMessage = "Failed to load event details: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    @MainActor
    func purchaseTickets() async throws {
        guard let reservation = reservation else {
            throw CheckoutError.noReservation
        }
        
        isLoading = true
        showError = false
        
        // For demo purposes, using a mock payment method
        let paymentMethod = PaymentMethod(type: .creditCard, token: "demo-token")
        
        do {
            order = try await EventTicketingClient.shared.purchaseTickets(
                reservation: reservation,
                paymentMethod: paymentMethod
            )
            isCompleted = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            throw error
        }
        
        isLoading = false
    }
}

enum CheckoutError: LocalizedError {
    case noReservation
    
    var errorDescription: String? {
        switch self {
        case .noReservation:
            return "No reservation found"
        }
    }
}
