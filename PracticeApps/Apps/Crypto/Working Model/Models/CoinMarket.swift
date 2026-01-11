//
//  CoinMarket.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import Foundation

struct CoinMarket: Identifiable, Codable, Hashable {
    let id: String
    let symbol: String
    let name: String
    let image: String
    let currentPrice: Double
    let priceChange24h: Double
    let high24h: Double
    let low24h: Double
    let marketCapRank: Int?
    let sparklineIn7d: SparklineIn7D?

    var hasIncreasedPrice: Bool { priceChange24h >= 0 }

    enum CodingKeys: String, CodingKey {
        case id, symbol, name, image
        case currentPrice = "current_price"
        case priceChange24h = "price_change_24h"
        case high24h = "high_24h"
        case low24h = "low_24h"
        case marketCapRank = "market_cap_rank"
        case sparklineIn7d = "sparkline_in_7d"
    }
}

struct SparklineIn7D: Codable, Hashable {
    let price: [Double]
}
