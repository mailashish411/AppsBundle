//
//  CoinMarket.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import Foundation

final class DiskCache {
    static let shared = DiskCache()
    private init() {}

    private let fm = FileManager.default

    private var baseURL: URL {
        fm.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CoinCache", isDirectory: true)
    }

    private func ensureDir() {
        if !fm.fileExists(atPath: baseURL.path) {
            try? fm.createDirectory(at: baseURL, withIntermediateDirectories: true)
        }
    }

    func write<T: Encodable>(_ value: T, key: String) {
        ensureDir()
        let url = baseURL.appendingPathComponent(key)
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url, options: .atomic)
        } catch { /* ignore */ }
    }

    func read<T: Decodable>(_ type: T.Type, key: String) -> T? {
        ensureDir()
        let url = baseURL.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
