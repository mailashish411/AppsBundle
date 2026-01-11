//
//  CoinMarket.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import SwiftUI

struct CoinListView: View {
    @State private var viewModel = CoinListViewModel()
    @State private var favorites = FavoritesStore()

    var body: some View {
        NavigationStack {
            List {
                // Controls
                Section {
                    Toggle("Favorites only", isOn: $viewModel.showFavoritesOnly)

                    Picker("Sort", selection: $viewModel.sort) {
                        ForEach(CoinSort.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // List
                Section {
                    ForEach(viewModel.filteredCoins(favorites: favorites)) { coin in
                        NavigationLink(value: coin) {
                            CoinRowView(coin: coin, favorites: favorites)
                                .contentShape(Rectangle())
                        }
                        .onAppear {
                            Task { await viewModel.loadMoreIfNeeded(current: coin) }
                        }
                    }

                    if viewModel.isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Coins")
            .searchable(text: $viewModel.searchText, prompt: "Search name or symbol")
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.initialLoad()
            }
            .overlay {
                if viewModel.isLoading && viewModel.coins.isEmpty {
                    ProgressView()
                }
            }
            .navigationDestination(for: CoinMarket.self) { coin in
                CoinDetailView(coin: coin, favorites: favorites)
            }
        }
    }
}

#Preview {
    CoinListView()
}
