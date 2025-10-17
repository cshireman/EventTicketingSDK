//
//  EventListViewModel.swift
//  EventTicketingDemo
//
//  Created by Chris Shireman on 10/13/25.
//

import SwiftUI
import Combine
import EventTicketingSDK

@Observable
class EventListViewModel {
    var searchQuery = ""
    var searchResults: [Event] = []
    var hasSearched: Bool = false
    var isSearching: Bool = false

    var showError: Bool = false
    var errorMessage: String = ""

    var emptyTitle: String {
        return hasSearched ? "No Results Available" : "Enter Your Search"
    }

    var emptySubtitle: String {
        return hasSearched ? "Please try your search again." : "Results will appear here."
    }

    func searchEvents() {
        if searchQuery.trimmed().isEmpty {
            searchResults = []
        } else {
            Task {
                do {
                    isSearching = true
                    searchResults = try await EventTicketingClient.shared.searchEvents(query: searchQuery)
                    isSearching = false
                } catch {
                    isSearching = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    func loadEvents() {
        Task {
            do {
                isSearching = true
                searchResults = try await EventTicketingClient.shared.fetchEvents()
                isSearching = false
            } catch {
                isSearching = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
