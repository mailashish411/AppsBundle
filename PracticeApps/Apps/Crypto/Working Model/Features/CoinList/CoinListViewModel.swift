//
//  CoinMarket.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import Foundation

enum CoinSort: String, CaseIterable, Identifiable {
    case marketCap = "Market Cap"
    case price = "Price"

    var id: String { rawValue }
}

@Observable
final class CoinListViewModel {
    var coins: [CoinMarket] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?

    var searchText: String = ""
    var showFavoritesOnly: Bool = false
    var sort: CoinSort = .marketCap

    private let api: CoinAPIClientProtocol
    private let cache = DiskCache.shared

    private(set) var page = 1
    private let perPage = 25
    private var canLoadMore = true

    init(api: CoinAPIClientProtocol = CoinGeckoClient()) {
        self.api = api

        // Load cached list immediately for offline/fast launch
        if let cached: [CoinMarket] = cache.read([CoinMarket].self, key: "markets_page_1.json") {
            self.coins = cached
        }
    }

    @MainActor
    func initialLoad() async {
        guard coins.isEmpty else { return }
        await refresh()
    }

    @MainActor
    func refresh() async {
        isLoading = true
        errorMessage = nil
        page = 1
        canLoadMore = true
        defer { isLoading = false }

        do {
            let result = try await api.fetchMarkets(page: page, perPage: perPage)
            coins = result
            cache.write(result, key: "markets_page_1.json")
        } catch {
            errorMessage = error.localizedDescription
            // keep cached coins if available
        }
    }

    @MainActor
    func loadMoreIfNeeded(current coin: CoinMarket) async {
        guard canLoadMore else { return }
        guard !isLoadingMore else { return }

        // Trigger when user is near bottom
        let thresholdIndex = coins.index(coins.endIndex, offsetBy: -6, limitedBy: coins.startIndex) ?? coins.startIndex
        guard coins.firstIndex(where: { $0.id == coin.id }) == thresholdIndex else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let nextPage = page + 1
            let result = try await api.fetchMarkets(page: nextPage, perPage: perPage)
            page = nextPage

            if result.isEmpty { canLoadMore = false }
            coins.append(contentsOf: result)

            cache.write(result, key: "markets_page_\(nextPage).json")
        } catch {
            // don't kill the list; just stop loading more this time
        }
    }

    func filteredCoins(favorites: FavoritesStore) -> [CoinMarket] {
        var list = coins

        // Search
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter { $0.name.lowercased().contains(q) || $0.symbol.lowercased().contains(q) }
        }

        // Favorites filter
        if showFavoritesOnly {
            list = list.filter { favorites.isFavorite($0.id) }
        }

        // Sort
        switch sort {
        case .marketCap:
            // Rank smaller = higher market cap
            list.sort { ($0.marketCapRank ?? 999_999) < ($1.marketCapRank ?? 999_999) }
        case .price:
            list.sort { $0.currentPrice > $1.currentPrice }
        }

        return list
    }
}
