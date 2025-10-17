//
//  TicketSelectionViewModel.swift
//  EventTicketingDemo
//
//  Created by Chris Shireman on 10/14/25.
//

import SwiftUI
import Combine
import EventTicketingSDK

@Observable
class TicketSelectionViewModel {
    var event: Event
    var ticketTypes: [TicketType] = []
    var availableTickets: [Ticket] = []
    var selectedTickets: [String: Int] = [:] // TicketType ID to quantity
    var reservation: TicketReservation?

    var isLoading: Bool = false
    var isSubmitted: Bool = false
    var showError: Bool = false
    var errorMessage: String = ""

    var totalTickets: Int {
        selectedTickets.values.reduce(0, +)
    }

    var totalPrice: Decimal {
        selectedTickets.reduce(0) { total, pair in
            if let ticketType = ticketTypes.first(where: { $0.id == pair.key }) {
                return total + (ticketType.price * Decimal(pair.value))
            }
            return total
        }
    }

    var canProceedToPurchase: Bool {
        totalTickets > 0 && event.hasTicketsAvailable
    }

    var totalTicketsLabel: String {
        return "Total: \(totalTickets) ticket\(totalTickets == 1 ? "" : "s")"
    }

    var totalPriceLabel: String {
        return totalPrice.formatted(.currency(code: "USD"))
    }

    init(event: Event) {
        self.event = event
        self.ticketTypes = event.ticketTypes
        loadAvailableTickets()
    }

    func loadAvailableTickets() {
        Task.detached { @MainActor in
            do {
                self.availableTickets = try await EventTicketingClient.shared
                    .getAvailableTickets(eventID: self.event.id)
            } catch {
                print("Error fetching available tickets: \(error)")
            }
        }
    }

    func incrementTicket(for ticketType: TicketType) {
        let currentCount = selectedTickets[ticketType.id] ?? 0
        if currentCount < ticketType.availableCount {
            selectedTickets[ticketType.id] = currentCount + 1
        }
    }

    func decrementTicket(for ticketType: TicketType) {
        let currentCount = selectedTickets[ticketType.id] ?? 0
        if currentCount > 0 {
            selectedTickets[ticketType.id] = currentCount - 1
            if selectedTickets[ticketType.id] == 0 {
                selectedTickets.removeValue(forKey: ticketType.id)
            }
        }
    }

    func reserveTickets() async throws {
        isLoading = true
        isSubmitted = false
        showError = false

        let tickets = selectedTickets.keys.compactMap { key in
            availableTickets.first(where: { $0.type.id == key })
        }

        do {
            reservation = try await EventTicketingClient.shared.reserveTickets(ticketIDs: tickets.map { $0.id },
                                                                               eventID: event.id)
            isLoading = false
            isSubmitted = true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
            isSubmitted = false
            throw error
        }
    }
}
