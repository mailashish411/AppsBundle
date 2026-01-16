import UIKit

actor ImageLoader {
    enum Entry {
        case inProgress(Task<UIImage?, Never>)
        case ready(UIImage)
    }
    private var mem: [URL: Entry] = [:]
    private let disk: DiskCache
    private let session: URLSession = .shared

    init(disk: DiskCache) { self.disk = disk }

    func load(_ url: URL) async -> UIImage? {
        if let e = mem[url] {
            switch e {
            case .ready(let img): return img
            case .inProgress(let t): return await t.value
            }
        }

        if let data = try? await disk.read(url), let img = UIImage(data: data) {
            mem[url] = .ready(img)
            return img
        }

        let task = Task<UIImage?, Never> { [session, disk] in
            do {
                let (data, _) = try await session.data(from: url)
                if let img = UIImage(data: data) {
                    try? await disk.write(url, data: data)
                    return img
                }
                return nil
            } catch { return nil }
        }

        mem[url] = .inProgress(task)
        let img = await task.value
        if let img { mem[url] = .ready(img) } else { mem[url] = nil }
        return img
    }

    func clearMemory() { mem.removeAll() }
}

actor DiskCache {
    private let dir: URL
    init() {
        dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImageDiskCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    func read(_ url: URL) async throws -> Data? {
        let path = dir.appendingPathComponent(urlKey(url))
        return try? Data(contentsOf: path)
    }

    func write(_ url: URL, data: Data) async throws {
        let path = dir.appendingPathComponent(urlKey(url))
        try data.write(to: path, options: [.atomic])
    }

    private func urlKey(_ url: URL) -> String {
        // simple stable filename
        String(url.absoluteString.hashValue)
    }
}
