//
//  CoinMarket.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import Foundation

@Observable
final class FavoritesStore {
    private let key = "favorite_coin_ids"

    var ids: Set<String> = []

    init() {
        if let arr = UserDefaults.standard.array(forKey: key) as? [String] {
            ids = Set(arr)
        }
    }

    func isFavorite(_ id: String) -> Bool {
        ids.contains(id)
    }

    func toggle(_ id: String) {
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
}
