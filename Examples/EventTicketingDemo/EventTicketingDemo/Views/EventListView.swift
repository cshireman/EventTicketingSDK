//
//  EventListView.swift
//  EventTicketingDemo
//
//  Created by Chris Shireman on 10/13/25.
//

import SwiftUI
import EventTicketingSDK

struct EventListView: View {
    @EnvironmentObject var router: NavigationRouter
    @State var viewModel: EventListViewModel = EventListViewModel()

    var body: some View {
        VStack {
            if !viewModel.isSearching {
                if viewModel.searchResults.count == 0 {
                    Text(viewModel.emptyTitle)
                        .font(.title)
                    Text(viewModel.emptySubtitle)
                        .font(.subheadline)
                } else {
                    List {
                        ForEach(viewModel.searchResults, id: \.id) { event in
                            EventCard(event: event)
                                .listRowSeparator(.hidden)
                                .listRowSpacing(0)
                                .onTapGesture {
                                    router.navigate(to: .eventDetail(event: event))
                                }
                        }
                    }
                    .listStyle(.plain)
                    .padding(.vertical, 10)
                }
            } else {
                ProgressView("Searching...")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchQuery, placement: .automatic, prompt: "Search Events by Name or Artist")
        .onAppear() {
            viewModel.loadEvents()
        }
        .onSubmit(of: .search) {
            viewModel.searchEvents()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Search Events")
                    .foregroundColor(.black)
                    .font(.largeTitle)
                    .padding()
            }
        }
        .alert(viewModel.errorMessage, isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        }
    }
}

#Preview {
    EventListView()
}
