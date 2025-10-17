//
//  EventDetailView.swift
//  EventTicketingDemo
//
//  Created by Chris Shireman on 10/13/25.
//

import Foundation
import SwiftUI
import EventTicketingSDK

struct EventDetailView: View {
    @EnvironmentObject var router: NavigationRouter

    var viewModel: EventDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                Divider()

                eventDescription

                Divider()

                venueInfo

                Divider()

                ticketTypes

                Divider()

                getTicketsButton
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.eventName)
                .font(.largeTitle)
                .bold()

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text(viewModel.eventDate)
                        .font(.subheadline)
                }

                GridRow {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    Text("Doors: \(viewModel.doorsDate)")
                        .font(.subheadline)
                }

                GridRow {
                    Image(systemName: "tag")
                        .foregroundColor(.blue)
                    Text("Status: \(viewModel.eventStatus)")
                        .font(.subheadline)
                }
            }
        }
    }

    var eventDescription: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About This Event")
                .font(.title2)
                .bold()

            Text(viewModel.eventDescription)
                .font(.body)
                .lineLimit(nil)
        }
    }

    var venueInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Venue Information")
                .font(.title2)
                .bold()

            HStack {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
                        Image(systemName: "building.2")
                            .foregroundColor(.blue)
                            .frame(width: 20)

                        Text(viewModel.venueName)
                            .font(.headline)
                            .gridColumnAlignment(.leading)
                    }

                    GridRow {
                        Image(systemName: "location")
                            .foregroundColor(.blue)
                            .frame(width: 20)

                        Text(viewModel.venueAddress)
                            .font(.subheadline)
                            .gridColumnAlignment(.leading)
                    }

                    GridRow {
                        Image(systemName: "person.3")
                            .foregroundColor(.blue)
                            .frame(width: 20)

                        Text("Capacity: \(viewModel.capacity)")
                            .font(.subheadline)
                            .gridColumnAlignment(.leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    var ticketTypes: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Tickets")
                .font(.title2)
                .bold()

            if viewModel.ticketTypes.isEmpty {
                Text("No ticket information available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.ticketTypes, id: \.id) { ticketType in
                        TicketTypeRow(ticketType: ticketType)
                    }
                }
            }
        }
    }

    var getTicketsButton: some View {
        Button(action: selectTickets) {
            HStack {
                Image(systemName: "ticket")
                Text("Select Tickets")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .disabled(viewModel.ticketTypes.isEmpty || !viewModel.hasTicketsAvailable)
    }

    func selectTickets() {
        router.navigate(to: .ticketSelection(event: viewModel.event))
    }
}

struct TicketTypeRow: View {
    let ticketType: TicketType
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(ticketType.name)
                    .font(.headline)

                Text(ticketType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(ticketType.price.formatted(.currency(code: "USD")))
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        EventDetailView(viewModel: .init(event: Event.empty))
    }
}
