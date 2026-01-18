# iOS Interview Cheat Sheet & Patterns

A collection of "drag-and-drop" patterns and snippets for coding interviews and take-home assignments.

## 1. Generic Networking (Async/Await)

A protocol-oriented network layer that handles generics and standard HTTP validation.

```swift
import Foundation

// MARK: - API Client Protocol
protocol APIClientProtocol {
    var session: URLSession { get }
    var decoder: JSONDecoder { get }
    func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T
}

// MARK: - Implementation
extension APIClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let url = try endpoint.url()
        let (data, response) = try await session.data(from: url)
        
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try decoder.decode(type, from: data)
    }
}

// MARK: - Helper: Endpoint
protocol Endpoint {
    var scheme: String { get }
    var host: String { get }
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
}

extension Endpoint {
    var scheme: String { "https" }
    func url() throws -> URL {
        var c = URLComponents()
        c.scheme = scheme; c.host = host; c.path = path
        c.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = c.url else { throw URLError(.badURL) }
        return url
    }
}
```

## 2. Image Loading & Caching (Actor + Disk)

Handles in-flight deduplication (so you don't download the same URL twice simultaneously) and caching.

```swift
import UIKit

actor ImageLoader {
    private var cache: [URL: UIImage] = [:]
    private var inProgress: [URL: Task<UIImage, Error>] = [:]
    
    func image(from url: URL) async throws -> UIImage {
        if let cached = cache[url] { return cached }
        
        if let existingInfo = inProgress[url] {
            return try await existingInfo.value
        }
        
        let task = Task<UIImage, Error> {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { throw URLError(.cannotDecodeContentData) }
            return image
        }
        
        inProgress[url] = task
        
        do {
            let image = try await task.value
            cache[url] = image
            inProgress[url] = nil
            return image
        } catch {
            inProgress[url] = nil
            throw error
        }
    }
}
```

## 3. MVVM State Management

Standard pattern for managing UI state (Loading, Success, Error).

```swift
import SwiftUI

enum ViewState<T> {
    case idle
    case loading
    case success(T)
    case error(Error)
}

@MainActor
class ViewModel: ObservableObject {
    @Published var state: ViewState<[String]> = .idle
    private let service: APIClientProtocol

    init(service: APIClientProtocol) {
        self.service = service
    }

    func fetchData() async {
        state = .loading
        do {
            // Simulate API call
            let data = ["Item 1", "Item 2"] 
            state = .success(data)
        } catch {
            state = .error(error)
        }
    }
}
```

## 4. Coordinator Pattern (Navigation)

Decouples navigation logic from Views/ViewControllers.

```swift
import SwiftUI

// MARK: - Coordinator Protocol
protocol Coordinator: ObservableObject {
    var navigationPath: NavigationPath { get set }
    func start()
}

// MARK: - App Coordinator
class AppCoordinator: Coordinator {
    @Published var navigationPath = NavigationPath()
    
    enum Destination: Hashable {
        case detail(id: String)
        case settings
    }
    
    func start() {
        // Initial setup if needed
    }
    
    func navigate(to destination: Destination) {
        navigationPath.append(destination)
    }
}

// MARK: - Root View Usage
struct RootView: View {
    @StateObject private var coordinator = AppCoordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            HomeView()
                .environmentObject(coordinator)
                .navigationDestination(for: AppCoordinator.Destination.self) { destination in
                    switch destination {
                    case .detail(let id): DetailView(id: id)
                    case .settings: SettingsView()
                    }
                }
        }
    }
}
```

## 5. Core Data Stack (Boilerplate)

Modern Core Data setup (NSPersistentContainer).

```swift
import CoreData

class CoreDataProvider {
    static let shared = CoreDataProvider()
    
    let container: NSPersistentContainer
    
    var context: NSManagedObjectContext { container.viewContext }
    
    private init() {
        container = NSPersistentContainer(name: "ModelName")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Save failed: \(error)")
        }
    }
}
```

## 6. Concurrent Task Group (Parallel Execution)

Fetch multiple resources in parallel and aggregate results.

```swift
func fetchAllData() async throws -> [Data] {
    let urls = [URL(string: "https://a.com")!, URL(string: "https://b.com")!]
    
    return try await withThrowingTaskGroup(of: Data.self) { group in
        for url in urls {
            group.addTask {
                let (data, _) = try await URLSession.shared.data(from: url)
                return data
            }
        }
        
        var results: [Data] = []
        for try await data in group {
            results.append(data)
        }
        return results
    }
}
```

## 7. Search Debounce (Task-based)

Essential for search bars to avoid spamming APIs. Cancel the previous task when new input arrives.

```swift
@MainActor
class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [String] = []
    
    private var searchTask: Task<Void, Never>?
    
    func onSearchChanges(newValue: String) {
        searchTask?.cancel()
        searchTask = Task {
            // Wait for user to stop typing (e.g., 0.5s)
            try? await Task.sleep(nanoseconds: 500_000_000)
            if Task.isCancelled { return }
            
            await performSearch(newValue)
        }
    }
    
    private func performSearch(_ query: String) async {
        // API Call
    }
}
```

## 8. Pagination (Infinite Scroll)

Trigger `loadMore` when the last item appears.

```swift
struct ListView: View {
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        List(viewModel.items) { item in
            Text(item.title)
                .onAppear {
                    if item == viewModel.items.last {
                        Task { await viewModel.loadNextPage() }
                    }
                }
        }
    }
}

// ViewModel Logic
func loadNextPage() async {
    guard !isLoading && hasMorePages else { return }
    isLoading = true
    // Fetch Next Page...
    isLoading = false
}
```

## 9. Unit Test Mocking (Protocol-based)

How to mock a dependency to test your ViewModel isolated from the network.

```swift
// 1. Protocol
protocol ServiceProtocol {
    func fetchData() async throws -> [String]
}

// 2. Mock
class MockService: ServiceProtocol {
    var result: Result<[String], Error> = .success([])
    var callCount = 0
    
    func fetchData() async throws -> [String] {
        callCount += 1
        return try result.get()
    }
}

// 3. Test
@MainActor
class ViewModelTests: XCTestCase {
    func testLoadingState() async {
        let mock = MockService()
        mock.result = .success(["Test Data"])
        let viewModel = ViewModel(service: mock)
        
        await viewModel.fetchData()
        
        XCTAssertEqual(viewModel.state, .success(["Test Data"]))
        XCTAssertEqual(mock.callCount, 1)
    }
}
```

## 10. UI Helpers (Hex Color & Modifiers)

Quick utilities to show polish.

```swift
import SwiftUI

// Hex Color Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Usability: Dismiss Keyboard on Drag
struct ResignKeyboardOnDragGesture: ViewModifier {
    var gesture = DragGesture().onChanged { _ in
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    func body(content: Content) -> some View {
        content.gesture(gesture)
    }
}
```
