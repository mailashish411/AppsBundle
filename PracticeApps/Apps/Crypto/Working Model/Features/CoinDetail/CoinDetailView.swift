//
//  CoinMarket.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import SwiftUI

struct CoinDetailView: View {
    @State private var viewModel: CoinDetailViewModel
    @Bindable var favorites: FavoritesStore

    init(coin: CoinMarket, favorites: FavoritesStore) {
        _viewModel = State(wrappedValue: CoinDetailViewModel(coin: coin))
        self.favorites = favorites
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    RemoteImageView(urlString: viewModel.coin.image, size: 64)

                    VStack(alignment: .leading) {
                        Text(viewModel.coin.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(viewModel.coin.currentPrice, format: .currency(code: "USD"))
                            .font(.headline)
                            .foregroundColor(viewModel.coin.hasIncreasedPrice ? .green : .red)
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                            favorites.toggle(viewModel.coin.id)
                        }
                    } label: {
                        Image(systemName: favorites.isFavorite(viewModel.coin.id) ? "star.fill" : "star")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(favorites.isFavorite(viewModel.coin.id) ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                if let prices = viewModel.coin.sparklineIn7d?.price, !prices.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("7D Trend")
                            .font(.headline)
                        SparklineView(prices: prices, isUp: viewModel.coin.hasIncreasedPrice)
                            .frame(height: 50)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Group {
                    if let text = viewModel.detail?.description["en"],
                       !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("About")
                            .font(.headline)
                        Text(text)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .transition(.opacity)
                    } else if viewModel.isLoading {
                        ProgressView()
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                    } else {
                        Text("No description available.")
                            .foregroundColor(.secondary)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: viewModel.detail?.id)

                Spacer(minLength: 24)
            }
            .padding()
        }
        .navigationTitle(viewModel.coin.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }
}
