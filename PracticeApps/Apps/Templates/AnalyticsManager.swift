import Foundation
// MARK: - Event

struct AnalyticsEvent: Sendable, Equatable {
    let name: String
    let params: [String: String]
}

// MARK: - Provider boundary

protocol AnalyticsProvider: Sendable {
    func track(_ event: AnalyticsEvent)
}

// MARK: - Manager

final class AnalyticsManager: Sendable {
    private let providers: [AnalyticsProvider]

    init(providers: [AnalyticsProvider]) {
        self.providers = providers
    }

    func track(name: String, params: [String: String] = [:]) {
        let event = AnalyticsEvent(name: name, params: params)
        providers.forEach { $0.track(event) }
    }
}

// MARK: - Example providers (in real app these wrap SDKs)

// Firebase-like wrapper
final class FirebaseAnalyticsProvider: AnalyticsProvider {
    func track(_ event: AnalyticsEvent) {
        // Analytics.logEvent(event.name, parameters: event.params)
        print("🔥 Firebase track:", event.name, event.params)
    }
}

// New Relic-like wrapper
final class NewRelicAnalyticsProvider: AnalyticsProvider {
    func track(_ event: AnalyticsEvent) {
        // NewRelic.recordCustomEvent(event.name, attributes: event.params)
        print("🟩 NewRelic track:", event.name, event.params)
    }
}

// MARK: - Tests

final class AnalyticsManagerTests: XCTestCase {

    private final class SpyProvider: AnalyticsProvider {
        private(set) var events: [AnalyticsEvent] = []
        func track(_ event: AnalyticsEvent) { events.append(event) }
    }

    func test_fansOutToAllProviders() {
        let p1 = SpyProvider()
        let p2 = SpyProvider()
        let manager = AnalyticsManager(providers: [p1, p2])

        manager.track(name: "offer_opened", params: ["id": "123"])

        XCTAssertEqual(p1.events, [AnalyticsEvent(name: "offer_opened", params: ["id": "123"])])
        XCTAssertEqual(p2.events.count, 1)
    }
}
