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
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
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

## 11. AsyncStream (Delegate -> Async)

Bridge legacy delegate patterns (like CoreLocation) into modern async for-loops.

```swift
import CoreLocation

class LocationManager {
    // 1. Create a Stream
    lazy var locationStream: AsyncStream<CLLocation> = {
        AsyncStream { continuation in
             self.continuation = continuation
        }
    }()
    
    private var continuation: AsyncStream<CLLocation>.Continuation?
    private let manager = CLLocationManager()
    
    init() {
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        
        // Ensure stream is cleaned up
        continuation?.onTermination = { @Sendable _ in
            // Stop updates if needed
        }
    }
    
    func start() {
        manager.startUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        // 2. Yield values
        continuation?.yield(loc)
    }
}

// Usage
// for await location in locationManager.locationStream { ... }
```

## 12. CheckedContinuation (Callback -> Async)

Wrap older callback-based APIs into `async throws` functions. ALWAYS resume exactly once!

```swift
func fetchLegacyData(completion: @escaping (Result<Data, Error>) -> Void) {
    // Legacy SDK call
}

func fetchModernData() async throws -> Data {
    return try await withCheckedThrowingContinuation { continuation in
        fetchLegacyData { result in
            switch result {
            case .success(let data):
                continuation.resume(returning: data)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}
```

## 13. Task.detached & Priorities

Use `Task` (inherits priority/context) by default. Use `detached` ONLY for background work unrelated to current context (like analytics logging).

```swift
func performWork() async {
    // 1. Inherits priority (e.g. .userInitiated)
    Task {
        await expensiveOperation()
    }
    
    // 2. Specific Priority
    Task(priority: .background) {
        await prefetchImages() 
    }
    
    // 3. Detached (Does NOT inherit Actor context or Priority)
    Task.detached(priority: .utility) {
        await specializedLogger.log("Action performed")
    }
}
```

## 14. Property Wrap (Quick Ref)

Correct usage of SwiftUI data flow.

| Wrapper | Usage |
| :--- | :--- |
| `@State` | Local private value (Int, Bool, String). Ownership stay in View. |
| `@StateObject` | Initialize a ViewModel/Object **once**. `_ = StateObject(wrappedValue: VM())` |
| `@ObservedObject` | Watch an object passed from parent. **Do NOT init here.** |
| `@EnvironmentObject` | Globals injected via `.environmentObject()`. |
| `@Binding` | Read/Write access to a value owned by a parent. |

## 15. GeometryReader (Size & Frames)

Get parent size or coordinate space frames.

```swift
GeometryReader { geo in
   // Parent Size
   let width = geo.size.width
   
   // Frame in Global (Screen) Space
   let frame = geo.frame(in: .global)
   
   // Frame in Local Space
   let local = geo.frame(in: .local)
   
   Text("Width: \(width)")
}
.frame(height: 200) // GeometryReader fills available space, so limit it!
```

## 16. MatchedGeometryEffect (Hero Animations)

Smoothly transition views between hierarchies.

```swift
struct HeroView: View {
    @Namespace var ns
    @State var isZoomed = false
    
    var body: some View {
        VStack {
            if isZoomed {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.red)
                    .matchedGeometryEffect(id: "shape", in: ns)
                    .frame(width: 300, height: 300)
                    .onTapGesture { withAnimation { isZoomed.toggle() } }
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.red)
                    .matchedGeometryEffect(id: "shape", in: ns)
                    .frame(width: 50, height: 50)
                    .onTapGesture { withAnimation { isZoomed.toggle() } }
            }
        }
    }
}
```

## 17. PreferenceKey (Child -> Parent Data)

Pass data UP the view hierarchy (opposite of Environment).

```swift
// 1. Define Key
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// 2. Child (emit value)
GeometryReader { geo in
    Color.clear.preference(key: ScrollOffsetKey.self, value: geo.frame(in: .global).minY)
}

// 3. Parent (read value)
.onPreferenceChange(ScrollOffsetKey.self) { value in
    print("Scroll Offset: \(value)")
}
```
