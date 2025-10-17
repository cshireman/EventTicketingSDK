//
//  EventTicketingDemoApp.swift
//  EventTicketingDemo
//
//  Created by Chris Shireman on 10/13/25.
//

import SwiftUI
import EventTicketingSDK

@main
struct EventTicketingDemoApp: App {
    init() {
        EventTicketingClient.configure(.default)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
