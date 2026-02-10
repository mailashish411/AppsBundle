///*
//============================================================
//iOS Networking Template — INTERVIEW FINAL (Staff iOS, 75 min)
//============================================================
//
//GOAL (say this in 15–20 sec):
//"I’ll build a networking layer with clean separation of concerns:
//Endpoint for URL construction, HTTPClient for execution, APIClient for
//validation+decoding, Feature Clients for domain endpoints, and a ViewModel
//for UI state. It’ll be testable via protocol seams, production-friendly
//error mapping, and extensible with retry/auth/caching when needed."
//
//WHAT YOU’LL BUILD (core):
//✅ AppError + NSURLError mapping (user-friendly)
//✅ HTTPClient protocol (test seam)
//✅ URLSessionHTTPClient (thin class wrapper)
//✅ Endpoint (type-safe request builder)
//✅ APIClient (execute + validate + decode)
//✅ Feature client (UsersClient)
//✅ ViewModel + SwiftUI view (loading/empty/error)
//✅ DI wiring
//✅ MockHTTPClient for unit tests
//
//EXTENSIONS (pick 1–2 if time):
//✅ Retry (idempotent + backoff)
//✅ Auth header injection
//✅ Actor discussion: token refresh / dedup / caching
//✅ Multipart (optional)
//
//============================================================
//*/
//
//import Foundation
//import SwiftUI
//
//// MARK: =====================================================
//// STEP 1) AppError + Mapping (2–4 min)
//// PURPOSE: Unified error handling + user-friendly messages
//// WHAT TO SAY:
//// "I map all URLSession/NSError failures into AppError at the boundary.
//// Feature layers only deal with AppError, keeping UI clean and testable."
//// MARK: =====================================================
//
//enum AppError: Error, Equatable {
//    // Infrastructure
//    case invalidURL
//    case noConnection
//    case timeout
//    case cancelled
//    case transport(String)
//
//    // HTTP
//    case httpStatus(Int)
//
//    // Serialization
//    case encodingFailed
//    case decodingFailed(String)
//
//    var message: String {
//        switch self {
//        case .invalidURL: return "Invalid URL"
//        case .noConnection: return "No internet connection"
//        case .timeout: return "Request timed out"
//        case .cancelled: return "Request was cancelled"
//        case .transport(let details): return "Network error: \(details)"
//        case .httpStatus(let code): return httpMessage(for: code)
//        case .encodingFailed: return "Failed to encode request"
//        case .decodingFailed: return "Failed to parse response"
//        }
//    }
//
//    private func httpMessage(for code: Int) -> String {
//        switch code {
//        case 401: return "Unauthorized — please log in again"
//        case 403: return "Forbidden — access denied"
//        case 404: return "Not found"
//        case 408: return "Request timeout"
//        case 429: return "Too many requests — try again soon"
//        case 500...599: return "Server error (\(code))"
//        default: return "Request failed (\(code))"
//        }
//    }
//}
//
//private extension AppError {
//    static func from(_ error: Error) -> AppError {
//        // Cancellation (Swift Concurrency)
//        if error is CancellationError { return .cancelled }
//
//        let nsError = error as NSError
//
//        // URLSession errors
//        if nsError.domain == NSURLErrorDomain {
//            switch nsError.code {
//            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
//                return .noConnection
//            case NSURLErrorTimedOut:
//                return .timeout
//            case NSURLErrorCancelled:
//                return .cancelled
//            case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
//                return .transport("Cannot reach server")
//            default:
//                return .transport(nsError.localizedDescription)
//            }
//        }
//
//        return .transport(String(describing: error))
//    }
//}
//
//// MARK: =====================================================
//// STEP 2) HTTPClient Protocol (1 min)
//// PURPOSE: Test seam
//// WHAT TO SAY:
//// "Everything above HTTPClient is testable without real networking."
//// MARK: =====================================================
//
//protocol HTTPClient {
//    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
//}
//
//// MARK: =====================================================
//// STEP 3) URLSessionHTTPClient (5 min)
//// PURPOSE: Thin wrapper that is easy to mock/replace
//// WHY CLASS (not actor):
//// - no shared mutable state
//// - URLSession is thread-safe
//// WHAT TO SAY:
//// "If we later add token refresh coordination, request dedup, or caching,
//// I’d evolve to an actor. Starting as a class keeps it simple."
//// MARK: =====================================================
//
//final class URLSessionHTTPClient: HTTPClient {
//    private let session: URLSession
//
//    init(session: URLSession = .shared) {
//        self.session = session
//    }
//
//    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
//        do {
//            let (data, response) = try await session.data(for: request)
//            guard let httpResponse = response as? HTTPURLResponse else {
//                throw AppError.transport("Invalid response type")
//            }
//            return (data, httpResponse)
//        } catch {
//            throw AppError.from(error)
//        }
//    }
//}
//
//// MARK: =====================================================
//// STEP 4) HTTPMethod (30 sec)
//// MARK: =====================================================
//
//enum HTTPMethod: String { case GET, POST, PUT, PATCH, DELETE }
//
//// MARK: =====================================================
//// STEP 5) Endpoint (5 min)
//// PURPOSE: Centralized request construction, no string concat in features
//// WHAT TO SAY:
//// "Endpoint encapsulates url, method, headers, query, body, and timeout."
//// MARK: =====================================================
//
//struct Endpoint {
//    let baseURL: URL
//    let path: String
//    var method: HTTPMethod = .GET
//    var queryItems: [URLQueryItem] = []
//    var headers: [String: String] = [:]
//    var body: Data? = nil
//    var timeout: TimeInterval = 30
//
//    func makeRequest() throws -> URLRequest {
//        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
//            throw AppError.invalidURL
//        }
//
//        // Ensure path joins correctly
//        let cleanedBasePath = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
//        let cleanedEndpointPath = path.hasPrefix("/") ? path : "/" + path
//        components.path = cleanedBasePath + cleanedEndpointPath
//
//        if !queryItems.isEmpty { components.queryItems = queryItems }
//        guard let url = components.url else { throw AppError.invalidURL }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = method.rawValue
//        request.httpBody = body
//        request.timeoutInterval = timeout
//
//        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
//
//        return request
//    }
//}
//
//extension Endpoint {
//    func withQuery(name: String, value: String) -> Endpoint {
//        var copy = self
//        copy.queryItems.append(URLQueryItem(name: name, value: value))
//        return copy
//    }
//
//    func withQueries(_ parameters: [String: String]) -> Endpoint {
//        var copy = self
//        copy.queryItems.append(contentsOf: parameters.map { URLQueryItem(name: $0.key, value: $0.value) })
//        return copy
//    }
//}
//
//// MARK: =====================================================
//// STEP 6) APIClient (5–7 min)
//// PURPOSE: Execute + validate + decode (centralized)
//// WHAT TO SAY:
//// "APIClient owns the mechanical work; feature clients stay tiny."
//// MARK: =====================================================
//
//struct APIClient {
//    let httpClient: HTTPClient
//    let decoder: JSONDecoder
//    let encoder: JSONEncoder
//
//    init(
//        httpClient: HTTPClient,
//        decoder: JSONDecoder = JSONDecoder(),
//        encoder: JSONEncoder = JSONEncoder()
//    ) {
//        self.httpClient = httpClient
//        self.decoder = decoder
//        self.encoder = encoder
//
//        // Optional:
//        // decoder.keyDecodingStrategy = .convertFromSnakeCase
//        // decoder.dateDecodingStrategy = .iso8601
//    }
//
//    func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
//        let urlRequest = try endpoint.makeRequest()
//        let (data, response) = try await httpClient.data(for: urlRequest)
//
//        guard (200...299).contains(response.statusCode) else {
//            throw AppError.httpStatus(response.statusCode)
//        }
//
//        do {
//            return try decoder.decode(T.self, from: data)
//        } catch {
//            throw AppError.decodingFailed(String(describing: error))
//        }
//    }
//
//    func requestNoResponseBody(_ endpoint: Endpoint) async throws {
//        let urlRequest = try endpoint.makeRequest()
//        let (_, response) = try await httpClient.data(for: urlRequest)
//
//        guard (200...299).contains(response.statusCode) else {
//            throw AppError.httpStatus(response.statusCode)
//        }
//    }
//}
//
//// MARK: =====================================================
//// STEP 7) Models (1–2 min)
//// NOTE: Separate request body from response model (real-world pattern)
//// MARK: =====================================================
//
//struct User: Codable, Identifiable, Equatable {
//    let id: Int
//    let name: String
//    let email: String
//    let username: String?
//}
//
//struct CreateUserRequest: Encodable, Equatable {
//    let name: String
//    let email: String
//    let username: String?
//}
//
//// MARK: =====================================================
//// STEP 8) Feature Client (UsersClient) (6–8 min)
//// WHAT TO SAY:
//// "Feature client exposes domain methods and hides URLs/endpoints."
//// MARK: =====================================================
//
//struct UsersClient {
//    private let apiClient: APIClient
//    private let baseURL: URL
//
//    init(apiClient: APIClient, baseURL: URL) {
//        self.apiClient = apiClient
//        self.baseURL = baseURL
//    }
//
//    func fetchUsers() async throws -> [User] {
//        let endpoint = Endpoint(
//            baseURL: baseURL,
//            path: "/users",
//            method: .GET,
//            headers: ["Accept": "application/json"]
//        )
//        return try await apiClient.request(endpoint, as: [User].self)
//    }
//
//    func fetchUser(id: Int) async throws -> User {
//        let endpoint = Endpoint(
//            baseURL: baseURL,
//            path: "/users/\(id)",
//            method: .GET,
//            headers: ["Accept": "application/json"]
//        )
//        return try await apiClient.request(endpoint, as: User.self)
//    }
//
//    func createUser(_ requestBody: CreateUserRequest) async throws -> User {
//        let body: Data
//        do {
//            body = try apiClient.encoder.encode(requestBody)
//        } catch {
//            throw AppError.encodingFailed
//        }
//
//        let endpoint = Endpoint(
//            baseURL: baseURL,
//            path: "/users",
//            method: .POST,
//            headers: [
//                "Content-Type": "application/json",
//                "Accept": "application/json"
//            ],
//            body: body
//        )
//
//        return try await apiClient.request(endpoint, as: User.self)
//    }
//
//    func deleteUser(id: Int) async throws {
//        let endpoint = Endpoint(
//            baseURL: baseURL,
//            path: "/users/\(id)",
//            method: .DELETE
//        )
//        try await apiClient.requestNoResponseBody(endpoint)
//    }
//}
//
//// MARK: =====================================================
//// STEP 9) ViewModel (8–10 min)
//// WHAT TO SAY:
//// "ViewModel owns UI state and translates AppError to user messaging."
//// MARK: =====================================================
//
//@MainActor
//final class UsersViewModel: ObservableObject {
//    @Published private(set) var users: [User] = []
//    @Published private(set) var isLoading: Bool = false
//    @Published var errorMessage: String?
//
//    private let usersClient: UsersClient
//
//    init(usersClient: UsersClient) {
//        self.usersClient = usersClient
//    }
//
//    func loadUsers() async {
//        isLoading = true
//        errorMessage = nil
//        defer { isLoading = false }
//
//        do {
//            users = try await usersClient.fetchUsers()
//        } catch let error as AppError {
//            errorMessage = error.message
//        } catch {
//            errorMessage = AppError.from(error).message
//        }
//    }
//
//    func refresh() async {
//        await loadUsers()
//    }
//
//    func deleteUser(_ user: User) async {
//        do {
//            try await usersClient.deleteUser(id: user.id)
//            users.removeAll { $0.id == user.id }
//        } catch let error as AppError {
//            errorMessage = error.message
//        } catch {
//            errorMessage = AppError.from(error).message
//        }
//    }
//}
//
//// MARK: =====================================================
//// STEP 10) SwiftUI View (8–10 min)
//// WHAT TO SAY:
//// "View handles success/loading/empty/error. Uses .task and .refreshable."
//// MARK: =====================================================
//
//struct UsersView: View {
//    @StateObject private var viewModel: UsersViewModel
//
//    init(viewModel: UsersViewModel) {
//        _viewModel = StateObject(wrappedValue: viewModel)
//    }
//
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                if viewModel.users.isEmpty && !viewModel.isLoading {
//                    ContentUnavailableView(
//                        "No Users",
//                        systemImage: "person.slash",
//                        description: Text("Pull to refresh")
//                    )
//                } else {
//                    List {
//                        ForEach(viewModel.users) { user in
//                            UserRow(user: user)
//                        }
//                        .onDelete { indexSet in
//                            Task {
//                                for index in indexSet {
//                                    await viewModel.deleteUser(viewModel.users[index])
//                                }
//                            }
//                        }
//                    }
//                    .refreshable { await viewModel.refresh() }
//                }
//
//                if viewModel.isLoading {
//                    ProgressView()
//                        .scaleEffect(1.2)
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        .background(.black.opacity(0.15))
//                }
//            }
//            .navigationTitle("Users")
//            .alert(
//                "Error",
//                isPresented: Binding(
//                    get: { viewModel.errorMessage != nil },
//                    set: { isPresented in
//                        if !isPresented { viewModel.errorMessage = nil }
//                    }
//                )
//            ) {
//                Button("OK", role: .cancel) { }
//            } message: {
//                Text(viewModel.errorMessage ?? "")
//            }
//            .task { await viewModel.loadUsers() }
//        }
//    }
//}
//
//struct UserRow: View {
//    let user: User
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(user.name).font(.headline)
//            Text(user.email).font(.subheadline).foregroundStyle(.secondary)
//            if let username = user.username {
//                Text("@\(username)").font(.caption).foregroundStyle(.tertiary)
//            }
//        }
//        .padding(.vertical, 4)
//    }
//}
//
//// MARK: =====================================================
//// STEP 11) DI Wiring (1–2 min)
//// WHAT TO SAY:
//// "Composition root wires dependencies. Easy to swap baseURL/env."
//// MARK: =====================================================
//
//extension UsersView {
//    static func create() -> UsersView {
//        let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!
//
//        let httpClient = URLSessionHTTPClient()
//        let apiClient = APIClient(httpClient: httpClient)
//        let usersClient = UsersClient(apiClient: apiClient, baseURL: baseURL)
//        let viewModel = UsersViewModel(usersClient: usersClient)
//
//        return UsersView(viewModel: viewModel)
//    }
//}
//
//// MARK: =====================================================
//// STEP 12) Testing Support (4–6 min)
//// WHAT TO SAY:
//// "MockHTTPClient tests APIClient + Feature client + ViewModel quickly."
//// MARK: =====================================================
//
//struct MockHTTPClient: HTTPClient {
//    var result: Result<(Data, HTTPURLResponse), Error>
//
//    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
//        switch result {
//        case .success(let payload): return payload
//        case .failure(let error): throw error
//        }
//    }
//}
//
//extension MockHTTPClient {
//    static func success<T: Encodable>(_ object: T, statusCode: Int = 200) throws -> MockHTTPClient {
//        let data = try JSONEncoder().encode(object)
//        let url = URL(string: "https://test.com")!
//        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
//        return MockHTTPClient(result: .success((data, response)))
//    }
//
//    static func failure(_ error: AppError) -> MockHTTPClient {
//        MockHTTPClient(result: .failure(error))
//    }
//}
//
///*
//EXAMPLE UNIT TEST (pseudo):
//
//func testLoadUsersSuccess() async throws {
//    let mockUsers = [User(id: 1, name: "Alice", email: "alice@test.com", username: "alice")]
//    let mockHTTP = try MockHTTPClient.success(mockUsers)
//    let apiClient = APIClient(httpClient: mockHTTP)
//    let usersClient = UsersClient(apiClient: apiClient, baseURL: URL(string:"https://test.com")!)
//    let viewModel = UsersViewModel(usersClient: usersClient)
//
//    await viewModel.loadUsers()
//
//    XCTAssertEqual(viewModel.users.count, 1)
//    XCTAssertNil(viewModel.errorMessage)
//    XCTAssertFalse(viewModel.isLoading)
//}
//*/
//
//// MARK: =====================================================
//// EXTENSION A) Retry (Idempotent GET) (optional 5 min)
//// WHAT TO SAY:
//// "I retry only idempotent requests and skip client errors (4xx)."
//// MARK: =====================================================
//
//extension APIClient {
//    func requestWithRetry<T: Decodable>(
//        _ endpoint: Endpoint,
//        as type: T.Type,
//        maxRetries: Int = 3
//    ) async throws -> T {
//        var lastError: AppError?
//
//        for attempt in 0..<maxRetries {
//            do {
//                return try await request(endpoint, as: type)
//            } catch {
//                let appError = (error as? AppError) ?? AppError.from(error)
//                lastError = appError
//
//                // Do not retry 4xx (client errors)
//                if case .httpStatus(let code) = appError, (400...499).contains(code) {
//                    throw appError
//                }
//
//                if attempt < maxRetries - 1 {
//                    let delaySeconds = pow(2.0, Double(attempt)) // 1s, 2s, 4s
//                    try? await Task.sleep(for: .seconds(delaySeconds))
//                }
//            }
//        }
//
//        throw lastError ?? .transport("Unknown error after retries")
//    }
//}
//
//// MARK: =====================================================
//// EXTENSION B) Auth Header Injection (optional 3–5 min)
//// WHAT TO SAY:
//// "I inject auth at the boundary. For refresh coordination, I’d use an actor."
//// MARK: =====================================================
//
//struct AuthenticatedEndpoint {
//    private let endpoint: Endpoint
//    private let tokenProvider: () -> String?
//
//    init(endpoint: Endpoint, tokenProvider: @escaping () -> String?) {
//        self.endpoint = endpoint
//        self.tokenProvider = tokenProvider
//    }
//
//    func makeRequest() throws -> URLRequest {
//        var request = try endpoint.makeRequest()
//        if let token = tokenProvider() {
//            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//        }
//        return request
//    }
//}
//
//// MARK: =====================================================
//// DISCUSSION (Actor vs Class) — say this (no need to code fully):
////
//// "I start with a class because URLSession is thread-safe and there’s no
//// shared mutable state. I refactor to an actor when I introduce shared state:
////
//// 1) Token refresh coordination: ensure only one refresh happens,
////    other requests await it.
//// 2) Request deduplication: share in-flight tasks to avoid duplicates.
//// 3) Caching dictionaries with TTL: actor protects mutation.
////
//// That evolution keeps the initial design simple while scaling safely."
//// MARK: =====================================================
//
//// MARK: =====================================================
//// 75-MINUTE TIME BREAKDOWN (use as your mental checklist)
//// 0–2   : Explain approach
//// 2–6   : AppError + mapping
//// 6–8   : HTTPClient protocol
//// 8–15  : URLSessionHTTPClient + Endpoint
//// 15–22 : APIClient
//// 22–30 : UsersClient + Models
//// 30–40 : ViewModel
//// 40–50 : SwiftUI view
//// 50–55 : DI wiring
//// 55–62 : Testing mock + quick test discussion
//// 62–75 : Add ONE: retry or auth + trade-offs + actor evolution
//// MARK: =====================================================
