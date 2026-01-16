final class LRUCache<Key: Hashable, Value> {

    final class Node {
        let key: Key
        var value: Value
        var prev: Node?
        var next: Node?
        init(key: Key, value: Value) { self.key = key; self.value = value }
    }

    private let capacity: Int
    private var dict: [Key: Node] = [:]
    private var head: Node? // most recent
    private var tail: Node? // least recent

    init(capacity: Int) { self.capacity = max(1, capacity) }

    func get(_ key: Key) -> Value? {
        guard let node = dict[key] else { return nil }
        moveToHead(node)
        return node.value
    }

    func put(_ key: Key, _ value: Value) {
        if let node = dict[key] {
            node.value = value
            moveToHead(node)
            return
        }
        let node = Node(key: key, value: value)
        dict[key] = node
        insertAtHead(node)

        if dict.count > capacity {
            evictTail()
        }
    }

    func clear() {
        dict.removeAll()
        head = nil
        tail = nil
    }

    // MARK: - DLL helpers
    private func insertAtHead(_ node: Node) {
        node.prev = nil
        node.next = head
        head?.prev = node
        head = node
        if tail == nil { tail = node }
    }

    private func moveToHead(_ node: Node) {
        guard head !== node else { return }
        remove(node)
        insertAtHead(node)
    }

    private func remove(_ node: Node) {
        let p = node.prev
        let n = node.next
        p?.next = n
        n?.prev = p
        if tail === node { tail = p }
        if head === node { head = n }
        node.prev = nil
        node.next = nil
    }

    private func evictTail() {
        guard let t = tail else { return }
        dict[t.key] = nil
        remove(t)
    }
}
