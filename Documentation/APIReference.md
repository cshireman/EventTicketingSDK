# EventTicketingSDK API Reference

## Table of Contents

1. [EventTicketingClient](#eventticketingclient)
2. [Configuration](#configuration)
3. [Models](#models)
4. [Errors](#errors)
5. [Async Streams](#async-streams)

## EventTicketingClient

The main entry point for the EventTicketingSDK. This class provides a clean, async/await API for all event ticketing operations.

### Class Declaration

```swift
@MainActor
public final class EventTicketingClient: Sendable
```

### Properties

#### `shared`

```swift
public static var shared: EventTicketingClient
```

The shared singleton instance of the client.

### Methods

#### `configure(_:)`

```swift
public static func configure(_ config: Configuration)
```

Configures the SDK with the provided configuration.

**Parameters:**
- `config`: The configuration object containing API settings.

**Example:**
```swift
let config = Configuration(
    baseURL: URL(string: "https://api.example.com")!,
    apiKey: "your_api_key",
    environment: .production
)
EventTicketingClient.configure(config)
```

#### `fetchEvents()`

```swift
public func fetchEvents() async throws -> [Event]
```

Fetches all available events. Results are cached for improved performance.

**Returns:** An array of `Event` objects.

**Throws:** `NetworkError` if the request fails.

**Example:**
```swift
do {
    let events = try await client.fetchEvents()
    print("Found \(events.count) events")
} catch {
    print("Failed to fetch events: \(error)")
}
```

#### `getEvent(id:)`

```swift
public func getEvent(id: String) async throws -> Event
```

Retrieves detailed information for a specific event.

**Parameters:**
- `id`: The unique identifier for the event.

**Returns:** An `Event` object with detailed information.

**Throws:** `NetworkError` if the request fails or event is not found.

**Example:**
```swift
let event = try await client.getEvent(id: "evt_123")
print("Event: \(event.title)")
```

#### `searchEvents(query:)`

```swift
public func searchEvents(query: String) async throws -> [Event]
```

Searches for events matching the provided query string.

**Parameters:**
- `query`: The search query string.

**Returns:** An array of matching `Event` objects.

**Throws:** `NetworkError` if the request fails.

**Example:**
```swift
let results = try await client.searchEvents(query: "concert")
print("Found \(results.count) concerts")
```

#### `getAvailableTickets(eventID:)`

```swift
public func getAvailableTickets(eventID: String) async throws -> [Ticket]
```

Retrieves available tickets for a specific event.

**Parameters:**
- `eventID`: The unique identifier for the event.

**Returns:** An array of available `Ticket` objects.

**Throws:** `NetworkError` if the request fails.

**Example:**
```swift
let tickets = try await client.getAvailableTickets(eventID: "evt_123")
for ticket in tickets {
    print("Ticket: \(ticket.name) - $\(ticket.price)")
}
```

#### `reserveTickets(ticketIDs:eventID:)`

```swift
public func reserveTickets(ticketIDs: [String], eventID: String) async throws -> TicketReservation
```

Reserves tickets for a specified time period (typically 10-15 minutes).

**Parameters:**
- `ticketIDs`: Array of ticket identifiers to reserve.
- `eventID`: The unique identifier for the event.

**Returns:** A `TicketReservation` object containing reservation details.

**Throws:** `NetworkError` if the request fails or tickets are unavailable.

**Example:**
```swift
let reservation = try await client.reserveTickets(
    ticketIDs: ["tkt_123", "tkt_124"],
    eventID: "evt_123"
)
print("Reservation expires at: \(reservation.expiresAt)")
```

#### `purchaseTickets(reservation:paymentMethod:)`

```swift
public func purchaseTickets(reservation: TicketReservation, paymentMethod: PaymentMethod) async throws -> Order
```

Purchases previously reserved tickets using the provided payment method.

**Parameters:**
- `reservation`: The ticket reservation to purchase.
- `paymentMethod`: The payment method to use for the purchase.

**Returns:** An `Order` object containing purchase details.

**Throws:** `NetworkError` if the purchase fails.

**Example:**
```swift
let paymentMethod = PaymentMethod(type: .applePay, token: "tok_123")
let order = try await client.purchaseTickets(
    reservation: reservation,
    paymentMethod: paymentMethod
)
print("Order confirmed: \(order.id)")
```

#### `eventUpdates(for:)`

```swift
public func eventUpdates(for eventID: String) async -> AsyncStream<EventUpdate>
```

Creates a stream of real-time updates for a specific event.

**Parameters:**
- `eventID`: The unique identifier for the event.

**Returns:** An `AsyncStream<EventUpdate>` for receiving updates.

**Example:**
```swift
for await update in await client.eventUpdates(for: "evt_123") {
    switch update.type {
    case .ticketAvailabilityChanged:
        print("Ticket availability changed")
    case .eventDetailsUpdated:
        print("Event details updated")
    }
}
```

## Configuration

Configuration object for customizing SDK behavior.

### Struct Declaration

```swift
public struct Configuration: Sendable
```

### Properties

#### `baseURL`

```swift
public let baseURL: URL
```

The base URL for API requests.

#### `webSocketURL`

```swift
public let webSocketURL: URL
```

The WebSocket URL for real-time updates. If not provided, automatically derived from `baseURL`.

#### `apiKey`

```swift
public let apiKey: String
```

The API key for authentication.

#### `environment`

```swift
public let environment: Environment
```

The deployment environment.

#### `timeout`

```swift
public let timeout: TimeInterval
```

Request timeout in seconds. Default is 30 seconds.

### Nested Types

#### `Environment`

```swift
public enum Environment: Sendable {
    case development
    case staging
    case production
}
```

### Initializers

#### `init(baseURL:webSocketURL:apiKey:environment:timeout:)`

```swift
public init(
    baseURL: URL,
    webSocketURL: URL? = nil,
    apiKey: String,
    environment: Environment = .production,
    timeout: TimeInterval = 30
)
```

Creates a new configuration object.

### Static Properties

#### `default`

```swift
public static let `default`: Configuration
```

Default configuration for development with localhost endpoints.

## Models

### Event

Represents an event with ticketing information.

```swift
public struct Event: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let startDate: Date
    public let endDate: Date
    public let venue: Venue
    public let imageURL: URL?
    public let ticketPriceRange: PriceRange
    public let availableTicketCount: Int
    public let category: EventCategory
}
```

### Ticket

Represents an available ticket for an event.

```swift
public struct Ticket: Codable, Identifiable, Sendable {
    public let id: String
    public let eventID: String
    public let name: String
    public let description: String
    public let price: Decimal
    public let currency: String
    public let section: String?
    public let row: String?
    public let seat: String?
    public let isAvailable: Bool
}
```

### TicketReservation

Represents a temporary reservation of tickets.

```swift
public struct TicketReservation: Codable, Identifiable, Sendable {
    public let id: String
    public let eventID: String
    public let ticketIDs: [String]
    public let totalPrice: Decimal
    public let currency: String
    public let expiresAt: Date
    public let reservedAt: Date
}
```

### Order

Represents a completed ticket purchase.

```swift
public struct Order: Codable, Identifiable, Sendable {
    public let id: String
    public let eventID: String
    public let ticketIDs: [String]
    public let totalPrice: Decimal
    public let currency: String
    public let status: OrderStatus
    public let purchasedAt: Date
    public let paymentMethod: PaymentMethod
}
```

#### `OrderStatus`

```swift
public enum OrderStatus: String, Codable, Sendable {
    case pending
    case confirmed
    case cancelled
    case refunded
}
```

### PaymentMethod

Represents a payment method for ticket purchases.

```swift
public struct PaymentMethod: Codable, Sendable {
    public let type: PaymentType
    public let token: String
    
    public enum PaymentType: String, Codable, Sendable {
        case creditCard
        case applePay
        case googlePay
        case paypal
    }
}
```

### EventUpdate

Represents a real-time update for an event.

```swift
public struct EventUpdate: Codable, Sendable {
    public let eventID: String
    public let type: UpdateType
    public let timestamp: Date
    public let data: [String: AnyCodable]
    
    public enum UpdateType: String, Codable, Sendable {
        case ticketAvailabilityChanged
        case eventDetailsUpdated
        case priceChanged
        case eventCancelled
        case eventPostponed
    }
}
```

### Supporting Types

#### `Venue`

```swift
public struct Venue: Codable, Sendable {
    public let id: String
    public let name: String
    public let address: String
    public let city: String
    public let state: String
    public let zipCode: String
    public let country: String
    public let capacity: Int?
}
```

#### `PriceRange`

```swift
public struct PriceRange: Codable, Sendable {
    public let min: Decimal
    public let max: Decimal
    public let currency: String
}
```

#### `EventCategory`

```swift
public enum EventCategory: String, Codable, Sendable, CaseIterable {
    case concert
    case sports
    case theater
    case comedy
    case conference
    case festival
    case other
}
```

## Errors

### NetworkError

The primary error type for network-related failures.

```swift
public enum NetworkError: Error, Sendable {
    case invalidURL
    case noData
    case decodingError(Error)
    case httpError(Int, String)
    case networkError(URLError)
    case authenticationFailed
    case rateLimited
    case serverMaintenance
}
```

#### Cases

- **`invalidURL`**: The provided URL is invalid or malformed.
- **`noData`**: The server returned no data.
- **`decodingError(Error)`**: Failed to decode the response JSON.
- **`httpError(Int, String)`**: HTTP error with status code and message.
- **`networkError(URLError)`**: Underlying network connectivity error.
- **`authenticationFailed`**: API key is invalid or expired.
- **`rateLimited`**: Too many requests, retry after specified time.
- **`serverMaintenance`**: Server is temporarily unavailable.

### LocalizedError Conformance

```swift
extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provided URL is invalid."
        case .noData:
            return "No data received from server."
        case .decodingError(let error):
            return "Failed to parse server response: \(error.localizedDescription)"
        case .httpError(let code, let message):
            return "Server error \(code): \(message)"
        case .networkError(let urlError):
            return "Network error: \(urlError.localizedDescription)"
        case .authenticationFailed:
            return "Authentication failed. Please check your API key."
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .serverMaintenance:
            return "Server is temporarily unavailable for maintenance."
        }
    }
}
```

## Async Streams

The SDK uses `AsyncStream` for real-time data updates.

### EventUpdate Stream

```swift
let stream = await client.eventUpdates(for: eventID)
```

#### Usage Pattern

```swift
Task {
    for await update in await client.eventUpdates(for: "evt_123") {
        DispatchQueue.main.async {
            // Update UI based on the event update
            handleEventUpdate(update)
        }
    }
}
```

#### Cancellation

```swift
let task = Task {
    for await update in await client.eventUpdates(for: eventID) {
        // Handle updates
    }
}

// Cancel when done
task.cancel()
```

## Best Practices

### Error Handling

Always handle potential errors when calling SDK methods:

```swift
do {
    let events = try await client.fetchEvents()
    // Handle success
} catch let networkError as NetworkError {
    // Handle specific network errors
    switch networkError {
    case .networkError(let urlError):
        // Handle connectivity issues
    case .authenticationFailed:
        // Handle authentication issues
    default:
        // Handle other network errors
    }
} catch {
    // Handle unexpected errors
}
```

### Concurrent Operations

The SDK is designed to handle concurrent operations safely:

```swift
async let events = client.fetchEvents()
async let tickets = client.getAvailableTickets(eventID: "evt_123")

let (eventList, ticketList) = try await (events, tickets)
```

### Memory Management

Streams automatically clean up when cancelled or when the task is deallocated:

```swift
class EventViewController {
    private var updateTask: Task<Void, Never>?
    
    func startListening() {
        updateTask = Task {
            for await update in await client.eventUpdates(for: eventID) {
                // Handle updates
            }
        }
    }
    
    func stopListening() {
        updateTask?.cancel()
        updateTask = nil
    }
}
```

This API reference provides complete coverage of the EventTicketingSDK's public interface, making it easy for developers to integrate event ticketing functionality into their applications.