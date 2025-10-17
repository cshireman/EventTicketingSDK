//
//  EventCard.swift
//  EventTicketingDemo
//
//  Created by Chris Shireman on 10/13/25.
//

import SwiftUI
import EventTicketingSDK

struct EventCard: View {
    var event: Event

    var body: some View {
        VStack {
            Text(event.name)
                .font(.title)
                .padding(.bottom, 2)
            Text(event.date.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(event.venue.name)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Button(action: {
                // Action to view event details
            }) {
                Text("View Details")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

#Preview {
    EventCard(event: Event(id: "1", name: "Sample Event", description: "This is a sample event description.", venue: Venue(id: "v1", name: "Sample Venue", address: "123 Main St", city: "Anytown", state: "CA", capacity: 5000), date: Date(), doors: Date(), imageURL: nil, ticketTypes: [], status: .upcoming))
}
