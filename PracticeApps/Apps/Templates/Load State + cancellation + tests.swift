import Foundation


// MARK: - Domain

struct Offer: Equatable, Sendable {
    let id: String
    let title: String
}

// MARK: - Load State

enum LoadState<T: Sendable>: Sendable, Equatable where T: Equatable {
    case idle
    case loading
    case success(T)
    case failure(String) // keep error equatable for tests
}

// MARK: - Service Boundary

protocol OffersService: Sendable {
    func fetchOffers() async throws -> [Offer]
}

// MARK: - ViewModel (testable, no SwiftUI needed)

@MainActor
final class OffersViewModel {
    private let service: OffersService
    private var task: Task<Void, Never>?

    private(set) var state: LoadState<[Offer]> = .idle

    init(service: OffersService) {
        self.service = service
    }

    func load() {
        // Cancel any in-flight load (common UI behavior)
        task?.cancel()

        state = .loading
        task = Task { [service] in
            do {
                let offers = try await service.fetchOffers()
                if Task.isCancelled { return }
                self.state = .success(offers)
            } catch {
                if Task.isCancelled { return }
                self.state = .failure(String(describing: error))
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

// MARK: - Tests

final class OffersViewModelTests: XCTestCase {

    private struct StubService: OffersService {
        let result: Result<[Offer], Error>
        let delayNanos: UInt64

        func fetchOffers() async throws -> [Offer] {
            if delayNanos > 0 { try await Task.sleep(nanoseconds: delayNanos) }
            return try result.get()
        }
    }

    func test_load_success() async {
        let vm = await MainActor.run {
            OffersViewModel(service: StubService(
                result: .success([Offer(id: "1", title: "10% back")]),
                delayNanos: 0
            ))
        }

        await MainActor.run { vm.load() }

        // Allow task to run
        await Task.yield()

        let state = await MainActor.run { vm.state }
        XCTAssertEqual(state, .success([Offer(id: "1", title: "10% back")]))
    }

    func test_load_failure() async {
        enum E: Error { case boom }

        let vm = await MainActor.run {
            OffersViewModel(service: StubService(result: .failure(E.boom), delayNanos: 0))
        }

        await MainActor.run { vm.load() }
        await Task.yield()

        let state = await MainActor.run { vm.state }
        switch state {
        case .failure: XCTAssertTrue(true)
        default: XCTFail("Expected failure")
        }
    }

    func test_cancel_doesNotOverwriteState() async {
        // Simulate slow fetch then cancel
        let vm = await MainActor.run {
            OffersViewModel(service: StubService(
                result: .success([Offer(id: "1", title: "late")]),
                delayNanos: 200_000_000 // 0.2s
            ))
        }

        await MainActor.run { vm.load() }
        await MainActor.run { vm.cancel() }

        // Wait longer than delay; state should NOT become success
        try? await Task.sleep(nanoseconds: 250_000_000)

        let state = await MainActor.run { vm.state }
        // After cancel we left state as .loading in this simple VM; acceptable in interview.
        // If you prefer, set to .idle in cancel().
        XCTAssertEqual(state, .loading)
    }
}
