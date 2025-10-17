//
//  TicketSelectionView.swift
//  EventTicketingDemo
//
//  Created by Chris Shireman on 10/14/25.
//

import SwiftUI
import EventTicketingSDK

struct TicketSelectionView: View {
    @EnvironmentObject var router: NavigationRouter
    @State var viewModel: TicketSelectionViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    Divider()
                    ticketTypes
                    Spacer(minLength: 100) // Space for bottom bar
                }
                .padding()
            }

            if viewModel.canProceedToPurchase {
                footer
            }
        }
        .navigationTitle("Select Tickets")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.isSubmitted) { _, isSubmitted in
            guard isSubmitted else { return }
            guard let reservation = viewModel.reservation else { return }
            router.navigate(to: .checkout(reservation: reservation))
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.event.name)
                .font(.title2)
                .bold()

            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text(viewModel.event.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Image(systemName: "location")
                    .foregroundColor(.secondary)
                Text(viewModel.event.venue.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    var ticketTypes: some View {
        if viewModel.event.ticketTypes.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "ticket")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No ticket types available")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("Check back later for ticket availability")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Ticket Types")
                        .font(.headline)
                    Spacer()
                    if viewModel.totalTickets > 0 {
                        Text("\(viewModel.totalTickets) selected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                ForEach(viewModel.event.ticketTypes, id: \.id) { ticketType in
                    TicketSelectorRow(
                        ticketType: ticketType,
                        selectedQuantity: Binding(
                            get: { viewModel.selectedTickets[ticketType.id] ?? 0 },
                            set: { viewModel.selectedTickets[ticketType.id] = $0 }
                        )
                    )
                }
            }
        }
    }

    var footer: some View {
        VStack(spacing: 12) {
            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.totalTicketsLabel)
                        .font(.headline)
                    Text(viewModel.totalPriceLabel)
                        .font(.title2)
                        .bold()
                }

                Spacer()

                Button("Continue to Checkout") {
                    Task {
                        try await viewModel.reserveTickets()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .background(.regularMaterial)
    }
}

struct TicketSelectorRow: View {
    let ticketType: TicketType
    @Binding var selectedQuantity: Int

    private let maxTicketsPerType = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ticketType.name)
                        .font(.headline)

                    if !ticketType.description.isEmpty {
                        Text(ticketType.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text(ticketType.price.formatted(.currency(code: "USD")))
                            .font(.title3)
                            .bold()

                        Spacer()

                        if ticketType.availableCount <= 10 && ticketType.availableCount > 0 {
                            Text("Only \(ticketType.availableCount) left")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }

                Spacer()
            }

            // Quantity Selector
            HStack {
                Spacer()

                if ticketType.availableCount > 0 {
                    HStack(spacing: 16) {
                        Button {
                            if selectedQuantity > 0 {
                                selectedQuantity -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(selectedQuantity > 0 ? .blue : .gray)
                        }
                        .disabled(selectedQuantity == 0)

                        Text("\(selectedQuantity)")
                            .font(.headline)
                            .frame(minWidth: 30)

                        Button {
                            let maxAllowed = min(maxTicketsPerType, ticketType.availableCount)
                            if selectedQuantity < maxAllowed {
                                selectedQuantity += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(selectedQuantity < min(maxTicketsPerType, ticketType.availableCount) ? .blue : .gray)
                        }
                        .disabled(selectedQuantity >= min(maxTicketsPerType, ticketType.availableCount))
                    }
                } else {
                    Text("Sold Out")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationView {
        TicketSelectionView(viewModel: TicketSelectionViewModel(event: Event(
            id: "preview",
            name: "Sample Concert",
            description: "A great concert event",
            venue: Venue(id: "v1", name: "Concert Hall", address: "123 Music St", city: "Music City", state: "TN", capacity: 2000),
            date: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            doors: Calendar.current.date(byAdding: .day, value: 30, to: Date().addingTimeInterval(-3600)) ?? Date(),
            imageURL: nil,
            ticketTypes: [
                TicketType(id: "general", name: "General Admission", description: "Standing room only", price: 45.00, availableCount: 500),
                TicketType(id: "vip", name: "VIP Package", description: "Premium seating with complimentary drinks", price: 125.00, availableCount: 50),
                TicketType(id: "limited", name: "Premium Seats", description: "Best seats in the house", price: 85.00, availableCount: 3)
            ],
            status: .onSale
        )))
    }
}
