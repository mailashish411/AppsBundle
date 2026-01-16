"The rule of thumb

Protocols = boundaries

Use protocols to define what you need, not how it’s done.
    •    XServicing / XRepository / XClient / XStoring / XTracking
    •    The app/features depend on protocols, not concrete types.

Structs = pure data + pure logic

Use structs for:
    •    Models (User, Event, PaymentIntent)
    •    Config objects (Options, Request, Policy)
    •    Mappers / pure functions
    •    Stateless services that just transform inputs → outputs (no shared mutable state)

Classes / Actors = state + identity + side effects

Use when you need:
    •    Mutable state (cache, in-flight tasks, queue)
    •    Identity/lifecycle (observers, delegates, KVO)
    •    Reference semantics (shared instance across many consumers)
    •    Thread-safety / concurrency (use actor over class for shared state)

Enums = finite states + variants
    •    Method types: .card, .applePay
    •    Event names (sometimes)
    •    State machine states: .idle, .loading, .success
    •    Error types

⸻

Generic Clean Architecture Template (works for almost everything)

Think in 4 rings:

1) Domain (pure Swift)

✅ struct, enum
    •    Entities + value objects
    •    Errors
    •    Request/Response types

No imports like UIKit/Firebase.

⸻

2) Application / Use Cases (or “Service layer”)

✅ protocols + orchestrators
    •    protocol FooServicing { ... }
    •    struct FooService (if stateless) or actor FooService (if stateful)
    •    Coordinates multiple dependencies

⸻

3) Infrastructure (SDK/network/database wrappers)

✅ concrete implementations
    •    struct FirebaseAnalyticsDestination: AnalyticsDestination
    •    final class URLSessionAPIClient: APIClient
    •    actor DiskEventStore: EventStore

Only place where you import 3rd party SDKs.

⸻

4) Presentation (SwiftUI / UIKit)

✅ ViewModels and Views
    •    @MainActor final class ViewModel
    •    Views only depend on protocols (injected)

⸻

How to decide: protocol vs struct vs class vs actor (cheat sheet)

Use a protocol when:
    •    You want to swap implementation (real vs mock)
    •    You need testability
    •    You need to separate layers

Naming:
XClient, XService, XRepository, XStore, XDestination

⸻

Use a struct when:
    •    It’s data
    •    It’s stateless logic
    •    It’s configuration
    •    You want value semantics

Examples:
    •    AnalyticsEvent, PaymentIntent, Endpoint, Request
    •    RetryPolicy, AnalyticsOptions

⸻

Use a final class when:
    •    You need identity + lifecycle
    •    You deal with delegates/observers/NotificationCenter
    •    You’re in UIKit / @MainActor ViewModel
    •    You must interop with ObjC APIs

Examples:
    •    final class URLSessionAPIClient
    •    @MainActor final class PaymentViewModel

⸻

Use an actor when:
    •    Shared mutable state across tasks
    •    You need thread-safety
    •    You maintain queues / caches / in-flight maps

Examples:
    •    actor AnalyticsManager (queue)
    •    actor TokenStore (refresh lock)
    •    actor ImagePipelineConfig (configure once)"
