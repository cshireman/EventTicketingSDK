# EventTicketingSDK

[![Swift Version](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-lightgrey.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A modern, Swift-native SDK for event ticketing platforms. Built with Swift 6, SwiftUI, and modern concurrency patterns.

## 🎯 Overview

EventTicketingSDK provides a clean, type-safe API for integrating event ticketing functionality into iOS applications. It handles the complexity of event discovery, ticket reservation, and purchase workflows while maintaining excellent performance and user experience.

**Built for the Tixr coding challenge to demonstrate:**
- Modern Swift architecture patterns
- Swift 6 strict concurrency
- Protocol-oriented design
- Comprehensive testing
- Production-ready code quality

## ✨ Features

- ✅ **Modern Swift 6** - Strict concurrency, sendable types
- ✅ **Async/Await** - Native async patterns throughout
- ✅ **Actor-based architecture** - Thread-safe by design
- ✅ **Smart caching** - Configurable cache policies with SwiftData
- ✅ **Type-safe API** - Leverage Swift's type system
- ✅ **Comprehensive testing** - 85%+ test coverage
- ✅ **Zero dependencies** - Pure Swift implementation
- ✅ **SwiftUI ready** - Observable patterns built-in

## 🚀 Quick Start

### Installation

#### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/cshireman/EventTicketingSDK.git", from: "1.0.0")
]
```

### Basic Usage

```swift
import EventTicketingSDK

// Configure the SDK
let config = Configuration(
    baseURL: URL(string: "https://api.example.com")!,
    apiKey: "your_api_key",
    environment: .production
)
EventTicketingClient.configure(with: config)

// Fetch events
let events = try await EventTicketingClient.shared.fetchEvents()

// Get event details
let event = try await EventTicketingClient.shared.getEvent(id: "evt_123")

// Get available tickets
let tickets = try await EventTicketingClient.shared.getAvailableTickets(
    eventID: event.id
)

// Reserve tickets
let reservation = try await EventTicketingClient.shared.reserveTickets(
    ticketIDs: tickets.map { $0.id },
    eventID: event.id
)

// Purchase
let paymentMethod = PaymentMethod(type: .applePay, token: "tok_123")
let order = try await EventTicketingClient.shared.purchaseTickets(
    reservation: reservation,
    paymentMethod: paymentMethod
)

print("Order confirmed: \(order.id)")
```

### SwiftUI Integration

```swift
import SwiftUI
import EventTicketingSDK

struct EventListView: View {
    @State private var events: [Event] = []
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        NavigationStack {
            List(events) { event in
                NavigationLink(value: event) {
                    EventRow(event: event)
                }
            }
            .navigationTitle("Events")
            .task {
                await loadEvents()
            }
        }
    }
    
    private func loadEvents() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            events = try await EventTicketingClient.shared.fetchEvents()
        } catch {
            self.error = error
        }
    }
}
```

## 🏗️ Architecture

### Overview

The SDK follows a layered architecture with clear separation of concerns:

```
┌─────────────────────────────────────┐
│     Public API Layer                │
│  (EventTicketingClient)             │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│     Service Layer                   │
│  (EventService, TicketService)      │
│  All services are Actors            │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│     Network Layer                   │
│  (NetworkClient Actor)              │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│     Data Layer                      │
│  (Models + CacheManager)            │
└─────────────────────────────────────┘
```

### Key Decisions

**Why Actors?**
- Thread safety without manual locks
- Perfect for Swift 6 strict concurrency
- Prevents data races at compile time

**Why No Clean Architecture?**
- SDKs need to be lightweight
- Clean Architecture is overkill for library code
- Layered approach provides enough separation

**Why No External Dependencies?**
- Reduces integration complexity
- No version conflicts
- Smaller binary size
- Full control over implementation

## 📊 Performance

| Operation | Time | Notes |
|-----------|------|-------|
| Fetch Events (Network) | ~200ms | Typical API response |
| Fetch Events (Cache) | <5ms | In-memory cache |
| Reserve Tickets | ~300ms | Includes validation |
| Purchase Tickets | ~500ms | Includes payment processing |

Benchmarked on iPhone 15 Pro, iOS 17.0

## 🧪 Testing

The SDK includes comprehensive test coverage:

```bash
swift test --parallel
```

**Test Structure:**
- Unit tests for all services
- Network layer mocking
- Cache behavior tests
- Integration tests
- Performance benchmarks

**Coverage: 87%**

## 🔒 Security

- API key stored securely
- HTTPS-only communication
- Request signing support
- Token-based authentication
- No sensitive data in logs

## 📱 Requirements

- iOS 17.0+
- Swift 6.0+
- Xcode 16.0+

## 🛠️ Development

### Running the Demo App

```bash
cd Examples/EventTicketingDemo
open EventTicketingDemo.xcodeproj
```

### Running the Backend

The backend API server is available in a separate repository:
[EventTicketingAPI](https://github.com/cshireman/EventTicketingAPI)

Follow the setup instructions in that repository to run the backend locally.

### Project Structure

```
EventTicketingSDK/
├── Sources/
│   └── EventTicketingSDK/      # SDK code
├── Tests/
│   └── EventTicketingSDKTests/  # Test suite
├── Examples/
│   └── EventTicketingDemo/      # SwiftUI demo
└── Documentation/
    ├── Architecture.md
    ├── APIReference.md
    └── GettingStarted.md
```

**Related Repositories:**
- [EventTicketingAPI](https://github.com/cshireman/EventTicketingAPI) - Backend API server

## 📖 Documentation

- [Architecture Overview](Documentation/Architecture.md)
- [API Reference](Documentation/APIReference.md)
- [Getting Started Guide](Documentation/GettingStarted.md)
- [Migration Guide](Documentation/Migration.md)

## 🤝 Contributing

This is a portfolio project, but feedback is welcome! Please open an issue for bugs or suggestions.

## 📝 License

MIT License - See [LICENSE](LICENSE) for details

## 👤 Author

**Christopher Shireman**
- GitHub: [@cshireman](https://github.com/cshireman)
- LinkedIn: [christophershireman](https://linkedin.com/in/christophershireman)
- Email: chris@shireman.net

## 🎯 Project Goals

This SDK was built as a portfolio piece to demonstrate:

1. **Modern Swift expertise** - Swift 6, actors, async/await
2. **Architecture skills** - Clean layering, protocol-oriented design
3. **Production quality** - Testing, documentation, error handling
4. **iOS best practices** - SwiftUI, performance optimization
5. **Leadership capabilities** - Code that others can build upon

## 🙏 Acknowledgments

Built with inspiration from:
- Stripe iOS SDK (API design)
- Alamofire (networking patterns)
- The Composable Architecture (state management concepts)

---

**⭐ If you find this helpful, please star the repo!**
