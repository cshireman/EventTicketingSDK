# EventTicketingSDK Getting Started Guide

This guide will help you integrate EventTicketingSDK into your iOS application quickly and efficiently.

## Table of Contents

1. [Requirements](#requirements)
2. [Installation](#installation)
3. [Initial Setup](#initial-setup)
4. [Basic Usage](#basic-usage)
5. [SwiftUI Integration](#swiftui-integration)
6. [Advanced Features](#advanced-features)
7. [Testing Your Integration](#testing-your-integration)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

## Requirements

- **iOS**: 17.0 or later
- **Swift**: 6.0 or later  
- **Xcode**: 16.0 or later
- Valid API key from your event ticketing provider

## Installation

### Swift Package Manager (Recommended)

1. In Xcode, go to **File → Add Package Dependencies**
2. Enter the repository URL:
   ```
   https://github.com/cshireman/EventTicketingSDK.git
   ```
3. Select **Up to Next Major Version** and enter `1.0.0`
4. Click **Add Package**
5. Select **EventTicketingSDK** and click **Add Package**

### Manual Integration

If you prefer to add the SDK manually:

1. Clone the repository:
   ```bash
   git clone https://github.com/cshireman/EventTicketingSDK.git
   ```
2. Drag the `Sources/EventTicketingSDK` folder into your Xcode project
3. Ensure "Copy items if needed" is checked

## Initial Setup

### 1. Import the SDK

Add the import statement to your Swift files:

```swift
import EventTicketingSDK
```

### 2. Configure the SDK

Configure the SDK early in your app's lifecycle, typically in `App.swift` or `AppDelegate.swift`:

```swift
import SwiftUI
import EventTicketingSDK

@main
struct MyEventApp: App {
    
    init() {
        configureEventSDK()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func configureEventSDK() {
        let config = Configuration(
            baseURL: URL(string: "https://api.youreventprovider.com")!,
            apiKey: "your_api_key_here", // Replace with your actual API key
            environment: .production // Use .development for testing
        )
        
        EventTicketingClient.configure(config)
    }
}
```

### 3. Handle Configuration for Different Environments

Create a configuration helper for managing different environments:

```swift
struct EventSDKConfig {
    static func configure() {
        #if DEBUG
        let config = Configuration(
            baseURL: URL(string: "http://localhost:8080")!,
            apiKey: "dev_api_key",
            environment: .development
        )
        #else
        let config = Configuration(
            baseURL: URL(string: "https://api.youreventprovider.com")!,
            apiKey: Bundle.main.apiKey, // Store in app bundle or keychain
            environment: .production
        )
        #endif
        
        EventTicketingClient.configure(config)
    }
}

// Extension for secure API key storage
extension Bundle {
    var apiKey: String {
        guard let key = infoDictionary?["EVENT_API_KEY"] as? String else {
            fatalError("API key not found in bundle")
        }
        return key
    }
}
```

## Basic Usage

### Fetching Events

```swift
class EventManager: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let client = EventTicketingClient.shared
    
    @MainActor
    func loadEvents() async {
        isLoading = true
        errorMessage = nil
        
        do {
            events = try await client.fetchEvents()
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
```

### Getting Event Details

```swift
@MainActor
func loadEventDetails(eventID: String) async -> Event? {
    do {
        let event = try await EventTicketingClient.shared.getEvent(id: eventID)
        return event
    } catch {
        print("Failed to load event: \(error)")
        return nil
    }
}
```

### Searching Events

```swift
@MainActor
func searchEvents(query: String) async {
    guard !query.isEmpty else { 
        events = []
        return 
    }
    
    isLoading = true
    
    do {
        events = try await EventTicketingClient.shared.searchEvents(query: query)
    } catch {
        errorMessage = "Search failed: \(error.localizedDescription)"
        events = []
    }
    
    isLoading = false
}
```

### Ticket Reservation and Purchase Flow

```swift
class TicketPurchaseManager: ObservableObject {
    @Published var availableTickets: [Ticket] = []
    @Published var currentReservation: TicketReservation?
    @Published var purchaseStatus: PurchaseStatus = .idle
    
    enum PurchaseStatus {
        case idle
        case loadingTickets
        case reserving
        case purchasing
        case completed(Order)
        case error(String)
    }
    
    private let client = EventTicketingClient.shared
    
    // Step 1: Load available tickets
    @MainActor
    func loadAvailableTickets(for eventID: String) async {
        purchaseStatus = .loadingTickets
        
        do {
            availableTickets = try await client.getAvailableTickets(eventID: eventID)
            purchaseStatus = .idle
        } catch {
            purchaseStatus = .error("Failed to load tickets: \(error.localizedDescription)")
        }
    }
    
    // Step 2: Reserve selected tickets
    @MainActor
    func reserveTickets(ticketIDs: [String], eventID: String) async {
        purchaseStatus = .reserving
        
        do {
            currentReservation = try await client.reserveTickets(
                ticketIDs: ticketIDs,
                eventID: eventID
            )
            purchaseStatus = .idle
        } catch {
            purchaseStatus = .error("Failed to reserve tickets: \(error.localizedDescription)")
        }
    }
    
    // Step 3: Complete the purchase
    @MainActor
    func purchaseTickets(paymentMethod: PaymentMethod) async {
        guard let reservation = currentReservation else {
            purchaseStatus = .error("No active reservation")
            return
        }
        
        purchaseStatus = .purchasing
        
        do {
            let order = try await client.purchaseTickets(
                reservation: reservation,
                paymentMethod: paymentMethod
            )
            purchaseStatus = .completed(order)
        } catch {
            purchaseStatus = .error("Purchase failed: \(error.localizedDescription)")
        }
    }
}
```

## SwiftUI Integration

### Event List View

```swift
struct EventListView: View {
    @StateObject private var eventManager = EventManager()
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if eventManager.isLoading {
                    ProgressView("Loading events...")
                } else if eventManager.events.isEmpty {
                    ContentUnavailableView(
                        "No Events Found",
                        systemImage: "calendar.badge.exclamationmark"
                    )
                } else {
                    eventList
                }
            }
            .navigationTitle("Events")
            .searchable(text: $searchText)
            .task {
                await eventManager.loadEvents()
            }
            .onChange(of: searchText) { oldValue, newValue in
                Task {
                    await eventManager.searchEvents(query: newValue)
                }
            }
            .alert("Error", isPresented: .constant(eventManager.errorMessage != nil)) {
                Button("OK") {
                    eventManager.errorMessage = nil
                }
            } message: {
                Text(eventManager.errorMessage ?? "")
            }
        }
    }
    
    private var eventList: some View {
        List(eventManager.events) { event in
            NavigationLink(destination: EventDetailView(event: event)) {
                EventRowView(event: event)
            }
        }
    }
}
```

### Event Detail View

```swift
struct EventDetailView: View {
    let event: Event
    @StateObject private var ticketManager = TicketPurchaseManager()
    @State private var selectedTickets: Set<String> = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                eventHeader
                eventDescription
                ticketSection
                purchaseButton
            }
            .padding()
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await ticketManager.loadAvailableTickets(for: event.id)
        }
    }
    
    private var eventHeader: some View {
        VStack(alignment: .leading) {
            if let imageURL = event.imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.3))
                }
                .frame(height: 200)
                .clipped()
                .cornerRadius(12)
            }
            
            Text(event.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(event.startDate, style: .date)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(event.venue.name)
                .font(.headline)
        }
    }
    
    private var eventDescription: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
            
            Text(event.description)
                .font(.body)
        }
    }
    
    private var ticketSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Tickets")
                .font(.headline)
            
            if ticketManager.availableTickets.isEmpty {
                Text("No tickets available")
                    .foregroundColor(.secondary)
            } else {
                ForEach(ticketManager.availableTickets) { ticket in
                    TicketRowView(
                        ticket: ticket,
                        isSelected: selectedTickets.contains(ticket.id)
                    ) {
                        toggleTicketSelection(ticket.id)
                    }
                }
            }
        }
    }
    
    private var purchaseButton: some View {
        Button(action: handlePurchase) {
            HStack {
                switch ticketManager.purchaseStatus {
                case .idle:
                    Text("Reserve Tickets")
                case .loadingTickets, .reserving:
                    ProgressView()
                        .controlSize(.mini)
                    Text("Processing...")
                case .purchasing:
                    ProgressView()
                        .controlSize(.mini)
                    Text("Purchasing...")
                default:
                    Text("Reserve Tickets")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(selectedTickets.isEmpty || ticketManager.purchaseStatus != .idle)
    }
    
    private func toggleTicketSelection(_ ticketID: String) {
        if selectedTickets.contains(ticketID) {
            selectedTickets.remove(ticketID)
        } else {
            selectedTickets.insert(ticketID)
        }
    }
    
    private func handlePurchase() {
        Task {
            await ticketManager.reserveTickets(
                ticketIDs: Array(selectedTickets),
                eventID: event.id
            )
            
            if case .idle = ticketManager.purchaseStatus {
                // Show payment method selection
                // This would typically present a payment sheet
                let paymentMethod = PaymentMethod(type: .applePay, token: "mock_token")
                await ticketManager.purchaseTickets(paymentMethod: paymentMethod)
            }
        }
    }
}
```

### Ticket Row View

```swift
struct TicketRowView: View {
    let ticket: Ticket
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(ticket.name)
                    .font(.headline)
                
                if let section = ticket.section {
                    Text("Section \(section)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(ticket.price, format: .currency(code: ticket.currency))
                .font(.headline)
                .fontWeight(.semibold)
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onTapGesture(perform: onTap)
    }
}
```

## Advanced Features

### Real-Time Event Updates

```swift
class EventUpdateManager: ObservableObject {
    @Published var latestUpdate: EventUpdate?
    private var updateTask: Task<Void, Never>?
    
    func startListening(to eventID: String) {
        updateTask?.cancel()
        
        updateTask = Task { @MainActor in
            for await update in await EventTicketingClient.shared.eventUpdates(for: eventID) {
                latestUpdate = update
                handleUpdate(update)
            }
        }
    }
    
    func stopListening() {
        updateTask?.cancel()
        updateTask = nil
    }
    
    private func handleUpdate(_ update: EventUpdate) {
        switch update.type {
        case .ticketAvailabilityChanged:
            // Refresh ticket availability
            NotificationCenter.default.post(
                name: .ticketAvailabilityChanged,
                object: update
            )
            
        case .priceChanged:
            // Update displayed prices
            NotificationCenter.default.post(
                name: .ticketPricesChanged,
                object: update
            )
            
        case .eventCancelled, .eventPostponed:
            // Show important alerts
            showEventChangeAlert(update)
            
        default:
            break
        }
    }
    
    private func showEventChangeAlert(_ update: EventUpdate) {
        // Implementation for showing alerts
    }
}

extension Notification.Name {
    static let ticketAvailabilityChanged = Notification.Name("ticketAvailabilityChanged")
    static let ticketPricesChanged = Notification.Name("ticketPricesChanged")
}
```

### Offline Support with Caching

The SDK automatically handles caching, but you can implement additional offline features:

```swift
class OfflineEventManager: ObservableObject {
    @Published var events: [Event] = []
    @Published var isOffline = false
    
    private let client = EventTicketingClient.shared
    private let networkMonitor = NWPathMonitor()
    
    init() {
        startNetworkMonitoring()
    }
    
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOffline = path.status != .satisfied
            }
        }
        networkMonitor.start(queue: DispatchQueue.global())
    }
    
    @MainActor
    func loadEvents() async {
        do {
            // The SDK will automatically use cache if offline
            events = try await client.fetchEvents()
        } catch {
            if isOffline {
                // Handle offline gracefully
                print("Using cached data while offline")
            } else {
                print("Error loading events: \(error)")
            }
        }
    }
}
```

## Testing Your Integration

### Unit Testing with MockClient

Create a mock client for testing:

```swift
import XCTest
@testable import YourApp
@testable import EventTicketingSDK

class EventManagerTests: XCTestCase {
    
    func testEventLoading() async throws {
        // Configure SDK with test configuration
        let config = Configuration(
            baseURL: URL(string: "https://test.api.com")!,
            apiKey: "test_key",
            environment: .development
        )
        EventTicketingClient.configure(config)
        
        let eventManager = EventManager()
        
        await eventManager.loadEvents()
        
        // Add assertions based on your expected behavior
        XCTAssertFalse(eventManager.isLoading)
    }
}
```

### Integration Testing

```swift
class IntegrationTests: XCTestCase {
    
    override func setUp() async throws {
        // Use a test backend for integration tests
        let config = Configuration(
            baseURL: URL(string: "https://staging.api.com")!,
            apiKey: "integration_test_key",
            environment: .staging
        )
        EventTicketingClient.configure(config)
    }
    
    func testFullPurchaseFlow() async throws {
        let client = EventTicketingClient.shared
        
        // Fetch events
        let events = try await client.fetchEvents()
        XCTAssertFalse(events.isEmpty)
        
        let firstEvent = events[0]
        
        // Get tickets
        let tickets = try await client.getAvailableTickets(eventID: firstEvent.id)
        XCTAssertFalse(tickets.isEmpty)
        
        // Reserve tickets
        let reservation = try await client.reserveTickets(
            ticketIDs: [tickets[0].id],
            eventID: firstEvent.id
        )
        XCTAssertEqual(reservation.eventID, firstEvent.id)
        
        // Note: Don't actually purchase in tests unless using a test payment method
    }
}
```

## Best Practices

### Error Handling

Always provide meaningful error messages to users:

```swift
extension NetworkError {
    var userFriendlyMessage: String {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again."
        case .authenticationFailed:
            return "There was a problem with authentication. Please contact support."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .serverMaintenance:
            return "The service is temporarily unavailable. Please try again later."
        default:
            return "Something went wrong. Please try again."
        }
    }
}
```

### Memory Management

Properly manage resources and cancel tasks:

```swift
class EventViewController: UIViewController {
    private var loadingTask: Task<Void, Never>?
    private var updateManager: EventUpdateManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadEvents()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanup()
    }
    
    private func loadEvents() {
        loadingTask = Task {
            // Load events
        }
    }
    
    private func cleanup() {
        loadingTask?.cancel()
        updateManager?.stopListening()
    }
}
```

### Performance Optimization

- Use caching effectively by avoiding unnecessary network calls
- Implement pagination for large event lists
- Use lazy loading for images
- Cancel unnecessary network requests

```swift
struct EventListView: View {
    @StateObject private var eventManager = EventManager()
    @State private var loadingTask: Task<Void, Never>?
    
    var body: some View {
        // Your view implementation
    }
    .onDisappear {
        loadingTask?.cancel()
    }
    .task {
        loadingTask = Task {
            await eventManager.loadEvents()
        }
    }
}
```

## Troubleshooting

### Common Issues

#### SDK Not Configured
**Error**: "EventTicketingClient not configured"
**Solution**: Ensure you call `EventTicketingClient.configure()` before using the SDK.

#### API Key Issues
**Error**: "Authentication failed"
**Solution**: Verify your API key is correct and hasn't expired.

#### Network Connectivity
**Error**: Various network errors
**Solution**: Implement proper offline handling and user feedback.

#### Reservation Expiry
**Error**: "Reservation expired"  
**Solution**: Implement timer-based UI updates to show reservation countdown.

### Debug Logging

Enable debug logging during development:

```swift
#if DEBUG
// Add custom logging if needed
func debugLog(_ message: String) {
    print("[EventSDK] \(message)")
}
#endif
```

### Support Resources

- **GitHub Issues**: [Report bugs or request features](https://github.com/cshireman/EventTicketingSDK/issues)
- **Documentation**: [Full API documentation](https://github.com/cshireman/EventTicketingSDK/blob/main/Documentation)
- **Example App**: Check out the complete sample application in the SDK repository

This guide should get you up and running with EventTicketingSDK. For more advanced usage patterns and complete API documentation, refer to the API Reference guide.