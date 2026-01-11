//
//  CoinMarket.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import SwiftUI

struct CoinRowView: View {
    let coin: CoinMarket
    @Bindable var favorites: FavoritesStore

    var body: some View {
        HStack(spacing: 12) {

            // Icon (fixed)
            RemoteImageView(urlString: coin.image, size: 36)
                .frame(width: 36, height: 36)

            // Name + Symbol (flexible, but protected)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(coin.name)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if let rank = coin.marketCapRank {
                        Text("#\(rank)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Text(coin.symbol.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(2) // ✅ give this priority so it doesn't collapse

            // Sparkline (fixed width)
//            if let prices = coin.sparklineIn7d?.price, !prices.isEmpty {
//                SparklineView(prices: prices, isUp: coin.hasIncreasedPrice)
//                    .frame(width: 88, height: 28)
//                    .layoutPriority(0)
//            }

            // Price + Change (fixed-ish, aligned)
            VStack(alignment: .trailing, spacing: 4) {
                Text(coin.currentPrice, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(coin.hasIncreasedPrice ? .green : .red)
                    .monospacedDigit()
                    .lineLimit(1)

                Text(coin.priceChange24h, format: .number.precision(.fractionLength(2)))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .frame(width: 92, alignment: .trailing) // ✅ prevents weird squeezing
            .layoutPriority(0)

            // Favorite button (fixed)
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                    favorites.toggle(coin.id)
                }
            } label: {
                Image(systemName: favorites.isFavorite(coin.id) ? "star.fill" : "star")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(favorites.isFavorite(coin.id) ? .yellow : .secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }
}
