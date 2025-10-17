//
//  ContentView.swift
//  EventTicketingDemo
//
//  Created by Chris Shireman on 10/13/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var router = NavigationRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            EventListView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .eventList:
                        EventListView()
                    case .eventDetail(let event):
                        EventDetailView(viewModel: .init(event: event))
                    case .ticketSelection(let event):
                        TicketSelectionView(viewModel: .init(event: event))
                    case .checkout(let reservation):
                        CheckoutView(viewModel: .init(reservation: reservation))
                    }
                }
        }
        .environmentObject(router)
    }
}

#Preview {
    ContentView()
}
