//
//  CheckoutView.swift
//  EventTicketingDemo
//
//  Created by Chris Shireman on 10/14/25.
//

import SwiftUI
import EventTicketingSDK

struct CheckoutView: View {
    @State var viewModel: CheckoutViewModel
    @State private var showConfirmationAlert = false
    @EnvironmentObject var router: NavigationRouter

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.isCompleted {
                    completedView
                } else {
                    checkoutContent
                }
            }
            .padding()
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadEventDetails()
        }
        .alert("Confirm Purchase", isPresented: $showConfirmationAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Purchase") {
                Task {
                    try await viewModel.purchaseTickets()
                }
            }
        } message: {
            Text("Are you sure you want to purchase these tickets for \(viewModel.formattedPrice)?")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    @ViewBuilder
    private var checkoutContent: some View {
        // Event Information
        if let event = viewModel.event {
            eventInfoSection(event)
        }
        
        // Selected Tickets
        if let reservation = viewModel.reservation {
            selectedTicketsSection(reservation)
            
            // Total and Purchase Button
            totalAndPurchaseSection(reservation)
        }
    }
    
    @ViewBuilder
    private func eventInfoSection(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("Event Details")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(event.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(event.venue.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(event.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Doors: \(event.doors, style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func selectedTicketsSection(_ reservation: TicketReservation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "ticket")
                    .foregroundColor(.green)
                Text("Selected Tickets")
                    .font(.headline)
                Spacer()
            }
            
            // Group tickets by type for cleaner display
            let groupedTickets = Dictionary(grouping: reservation.tickets) { $0.type }

            ForEach(Array(groupedTickets.keys), id: \.id) { ticketType in
                if let tickets = groupedTickets[ticketType],
                   let firstTicket = tickets.first {
                    ticketTypeRow(tickets: tickets, sampleTicket: firstTicket)
                }
            }
            
            Divider()
            
            HStack {
                Text("Reservation expires:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(reservation.expiresAt, style: .timer)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func ticketTypeRow(tickets: [Ticket], sampleTicket: Ticket) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(sampleTicket.type.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !sampleTicket.section.isEmpty {
                    Text("Section \(sampleTicket.section)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let row = sampleTicket.row, !row.isEmpty {
                    Text("Row \(row)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(tickets.count) × \(formatPrice(sampleTicket.price))")
                    .font(.subheadline)
                
                Text(formatPrice(sampleTicket.price * Decimal(tickets.count)))
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
    }
    
    @ViewBuilder
    private func totalAndPurchaseSection(_ reservation: TicketReservation) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Total")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Text(formatPrice(reservation.total))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Button(action: {
                showConfirmationAlert = true
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "creditcard")
                        Text("Purchase Tickets")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.isLoading)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var completedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Purchase Complete!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your tickets have been purchased successfully. You'll receive confirmation via email.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if let order = viewModel.order {
                Text("Order ID: \(order.id)")
                    .font(.caption)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            Button("Done") {
                router.path = NavigationPath()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding()
    }
    
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: price as NSDecimalNumber) ?? "$0.00"
    }
}


#Preview {
    CheckoutView(viewModel: CheckoutViewModel(reservation: TicketReservation(
        reservationId: "preview-reservation-1",
        tickets: [],
        expiresAt: Date().addingTimeInterval(15 * 60), // 15 minutes from now
        total: Decimal(29.99)
    )))
}
