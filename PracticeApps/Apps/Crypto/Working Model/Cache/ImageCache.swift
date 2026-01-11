//
//  CoinMarket.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import UIKit

final class ImageCache {
    static let shared = ImageCache()
    private init() {}

    private let memory = NSCache<NSString, UIImage>()
    private let fm = FileManager.default

    private var dir: URL {
        fm.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CoinImages", isDirectory: true)
    }

    private func ensureDir() {
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    private func fileURL(for key: String) -> URL {
        ensureDir()
        // safe filename
        let safe = key.replacingOccurrences(of: "/", with: "_")
        return dir.appendingPathComponent(safe)
    }

    func get(_ key: String) -> UIImage? {
        if let img = memory.object(forKey: key as NSString) { return img }
        let url = fileURL(for: key)
        if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
            memory.setObject(img, forKey: key as NSString)
            return img
        }
        return nil
    }

    func set(_ image: UIImage, for key: String) {
        memory.setObject(image, forKey: key as NSString)
        let url = fileURL(for: key)
        if let data = image.pngData() {
            try? data.write(to: url, options: .atomic)
        }
    }
}
