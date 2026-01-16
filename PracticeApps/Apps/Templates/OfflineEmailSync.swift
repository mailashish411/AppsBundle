enum SyncOp: Codable {
    case markRead(id: String, isRead: Bool, clientTS: Date)
    case delete(id: String, clientTS: Date)
    case sendDraft(id: String, body: String, clientTS: Date)
}

actor SyncManager {
    private var queue: [SyncOp] = []
    private let api: SyncAPI
    private let store: QueueStore

    init(api: SyncAPI, store: QueueStore) { self.api = api; self.store = store }

    func enqueue(_ op: SyncOp) async {
        queue.append(op)
        await store.save(queue)
    }

    func onNetworkRestored() async {
        await flush()
    }

    func flush() async {
        guard !queue.isEmpty else { return }
        var remaining: [SyncOp] = []
        for op in queue {
            do { try await api.apply(op) }
            catch { remaining.append(op) } // keep for retry
        }
        queue = remaining
        await store.save(queue)
    }
}

protocol SyncAPI { func apply(_ op: SyncOp) async throws }
protocol QueueStore { func save(_ ops: [SyncOp]) async }
