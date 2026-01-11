//
//  Crypto.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import Foundation

struct Crypto: Identifiable, Codable, Hashable {
    let id: String
    let symbol: String
    let name: String
    let image: String
    let currentPrice: Double
    let priceChange: Double
    let dayHigh: Double
    let dayLow: Double

    enum CodingKeys: String, CodingKey {
        case id, symbol, name, image
        case currentPrice = "current_price"
        case priceChange = "price_change_24h"
        case dayHigh = "high_24h"
        case dayLow = "low_24h"
    }
}

extension Crypto {
    var hasIncreasedPrice: Bool {
        return priceChange > 0
    }
}
extension Crypto {
    static let mocks: [Crypto] = [

        Crypto(
            id: "bitcoin",
            symbol: "btc",
            name: "Bitcoin",
            image: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png",
            currentPrice: 43120.55,
            priceChange: -350.75,
            dayHigh: 43800.12,
            dayLow: 42650.30
        ),

        Crypto(
            id: "ethereum",
            symbol: "eth",
            name: "Ethereum",
            image: "https://assets.coingecko.com/coins/images/279/large/ethereum.png",
            currentPrice: 3098.28,
            priceChange: 45.12,
            dayHigh: 3150.00,
            dayLow: 3012.45
        ),

        Crypto(
            id: "solana",
            symbol: "sol",
            name: "Solana",
            image: "https://assets.coingecko.com/coins/images/4128/large/solana.png",
            currentPrice: 98.75,
            priceChange: 2.80,
            dayHigh: 102.10,
            dayLow: 95.30
        ),

        Crypto(
            id: "binancecoin",
            symbol: "bnb",
            name: "BNB",
            image: "https://assets.coingecko.com/coins/images/825/large/binance-coin-logo.png",
            currentPrice: 312.40,
            priceChange: -5.65,
            dayHigh: 320.00,
            dayLow: 308.90
        ),

        Crypto(
            id: "cardano",
            symbol: "ada",
            name: "Cardano",
            image: "https://assets.coingecko.com/coins/images/975/large/cardano.png",
            currentPrice: 0.485,
            priceChange: 0.012,
            dayHigh: 0.495,
            dayLow: 0.472
        ),

        Crypto(
            id: "avalanche",
            symbol: "avax",
            name: "Avalanche",
            image: "https://assets.coingecko.com/coins/images/12559/large/Avalanche_Circle_RedWhite_Trans.png",
            currentPrice: 37.65,
            priceChange: -1.42,
            dayHigh: 39.10,
            dayLow: 36.80
        )
    ]
}
