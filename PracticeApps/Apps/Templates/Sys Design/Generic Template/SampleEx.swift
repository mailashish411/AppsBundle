"// MARK: 1) Domain (pure)

public struct ThingRequest: Sendable, Equatable { /* ... */ }
public struct ThingResult: Sendable, Equatable { /* ... */ }
public enum ThingError: Error, Sendable, Equatable { /* ... */ }

// MARK: 2) Boundary (protocol app depends on)

public protocol ThingServicing: Sendable {
    func perform(_ request: ThingRequest) async -> Result<ThingResult, ThingError>
}

// MARK: 3) Dependencies (interfaces / ports)

public protocol ThingClient: Sendable {
    func call(_ request: ThingRequest) async throws -> ThingResult
}

public protocol ThingStore: Sendable {
    func save(_ value: ThingResult) async
    func load(for request: ThingRequest) async -> ThingResult?
}

// MARK: 4) Orchestrator (use case/service)

public struct ThingService: ThingServicing {
    private let client: ThingClient
    private let store: ThingStore?

    public init(client: ThingClient, store: ThingStore? = nil) {
        self.client = client
        self.store = store
    }

    public func perform(_ request: ThingRequest) async -> Result<ThingResult, ThingError> {
        if let cached = await store?.load(for: request) {
            return .success(cached)
        }

        do {
            let result = try await client.call(request)
            await store?.save(result)
            return .success(result)
        } catch {
            return .failure(.init(/* map error */))
        }
    }
}

// MARK: 5) Infrastructure implementations (real world)

public final class URLSessionThingClient: ThingClient {
    public init() {}
    public func call(_ request: ThingRequest) async throws -> ThingResult {
        // URLSession call, decode
        fatalError(""implement"")
    }
}

public actor InMemoryThingStore: ThingStore {
    private var cache: [ThingRequest: ThingResult] = [:]
    public init() {}
    public func save(_ value: ThingResult) async { /* ... */ }
    public func load(for request: ThingRequest) async -> ThingResult? { /* ... */ nil }
}

// MARK: 6) Presentation (ViewModel)

@MainActor
public final class ThingViewModel: ObservableObject {
    private let service: ThingServicing

    @Published public private(set) var state: ViewState = .idle

    public init(service: ThingServicing) {
        self.service = service
    }

    public func load() {
        state = .loading
        Task {
            let res = await service.perform(.init(/*...*/))
            switch res {
            case .success(let value): state = .loaded(value)
            case .failure(let error): state = .error(error)
            }
        }
    }

    public enum ViewState: Equatable {
        case idle
        case loading
        case loaded(ThingResult)
        case error(ThingError)
    }
}"
