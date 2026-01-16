import Foundation

actor AsyncSemaphore {
    private var value: Int
    init(_ value: Int) { self.value = value }
    func acquire() async {
        while value == 0 { await Task.yield() }
        value -= 1
    }
    func release() { value += 1 }
}

struct DownloadItem { let id: String; let url: URL }

final class AttachmentDownloader {
    private let sem: AsyncSemaphore
    init(maxConcurrent: Int) { sem = AsyncSemaphore(maxConcurrent) }

    func downloadAll(_ items: [DownloadItem]) async -> [String: Data] {
        var results: [String: Data] = [:]

        await withTaskGroup(of: (String, Data)?.self) { group in
            for item in items {
                group.addTask {
                    await self.sem.acquire()
                    defer { self.sem.release() }

                    // retry 2 times
                    for attempt in 0..<3 {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: item.url)
                            return (item.id, data)
                        } catch {
                            if attempt == 2 { return nil }
                            try? await Task.sleep(nanoseconds: 200_000_000)
                        }
                    }
                    return nil
                }
            }

            for await pair in group {
                if let (id, data) = pair { results[id] = data }
            }
        }
        return results
    }
}
