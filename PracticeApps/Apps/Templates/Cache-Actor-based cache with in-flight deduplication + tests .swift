import Foundation


// MARK: - Boundary

protocol RemoteDataStore: Sendable {
    func read(_ key: String) async throws -> Data
}

// MARK: - Actor cache (dedupes in-flight)

actor DataCache {
    enum Entry {
        case inProgress(Task<Data, Error>)
        case ready(Data)
    }

    private var storage: [String: Entry] = [:]
    private let remote: RemoteDataStore

    init(remote: RemoteDataStore) {
        self.remote = remote
    }

    func read(_ key: String) async throws -> Data {
        if let entry = storage[key] {
            switch entry {
            case .ready(let data):
                return data
            case .inProgress(let task):
                return try await task.value
            }
        }

        let task = Task<Data, Error> { [remote] in
            try await remote.read(key)
        }

        storage[key] = .inProgress(task)

        do {
            let data = try await task.value
            storage[key] = .ready(data)
            return data
        } catch {
            storage[key] = nil // allow retry next time
            throw error
        }
    }

    func write(_ key: String, data: Data) {
        storage[key] = .ready(data)
    }

    func invalidate(_ key: String) {
        storage[key] = nil
    }

    func invalidateAll() {
        storage.removeAll()
    }
}

// MARK: - Tests

final class DataCacheTests: XCTestCase {

    private actor StubRemote: RemoteDataStore {
        var calls: [String] = []
        let delayNanos: UInt64
        let payload: Data

        init(delayNanos: UInt64 = 150_000_000, payload: Data = Data("ok".utf8)) {
            self.delayNanos = delayNanos
            self.payload = payload
        }

        func read(_ key: String) async throws -> Data {
            calls.append(key)
            try await Task.sleep(nanoseconds: delayNanos)
            return payload
        }

        func callCount(for key: String) async -> Int {
            calls.filter { $0 == key }.count
        }
    }

    func test_dedupesConcurrentReads() async throws {
        let remote = StubRemote()
        let cache = DataCache(remote: remote)

        async let a = cache.read("A")
        async let b = cache.read("A")
        async let c = cache.read("A")

        let (ra, rb, rc) = try await (a, b, c)
        XCTAssertEqual(ra, rb)
        XCTAssertEqual(rb, rc)

        let count = await remote.callCount(for: "A")
        XCTAssertEqual(count, 1, "Should only hit remote once for concurrent reads")
    }

    func test_cachedAfterFirstRead() async throws {
        let remote = StubRemote(delayNanos: 10_000_000)
        let cache = DataCache(remote: remote)

        _ = try await cache.read("A")
        _ = try await cache.read("A")

        let count = await remote.callCount(for: "A")
        XCTAssertEqual(count, 1, "Second read should be served from cache")
    }

    func test_invalidateForcesRefetch() async throws {
        let remote = StubRemote(delayNanos: 10_000_000)
        let cache = DataCache(remote: remote)

        _ = try await cache.read("A")
        await cache.invalidate("A")
        _ = try await cache.read("A")

        let count = await remote.callCount(for: "A")
        XCTAssertEqual(count, 2)
    }
}
