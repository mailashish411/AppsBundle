//
//  CoinMarket.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import Foundation

@Observable
final class CoinDetailViewModel {
    let coin: CoinMarket
    var detail: CoinDetail?
    var isLoading = false
    var errorMessage: String?

    private let api: CoinAPIClientProtocol
    private let cache = DiskCache.shared

    init(coin: CoinMarket, api: CoinAPIClientProtocol = CoinGeckoClient()) {
        self.coin = coin
        self.api = api

        // cached detail first (offline support)
        if let cached: CoinDetail = cache.read(CoinDetail.self, key: "detail_\(coin.id).json") {
            self.detail = cached
        }
    }

    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await api.fetchDetail(id: coin.id)
            detail = result
            cache.write(result, key: "detail_\(coin.id).json")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
