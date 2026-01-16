@MainActor
final class DraftViewModel: ObservableObject {
    @Published var text: String = ""
    private var debounceTask: Task<Void, Never>?
    private let store: DraftStore
    private let api: DraftAPI

    init(store: DraftStore, api: DraftAPI) {
        self.store = store
        self.api = api
    }

    func userTyped(_ newText: String) {
        text = newText
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000) // 400ms debounce
            if Task.isCancelled { return }
            await store.saveLocal(text: newText)
            try? await api.sync(text: newText) // best effort
        }
    }
}

protocol DraftStore { func saveLocal(text: String) async }
protocol DraftAPI { func sync(text: String) async throws }
