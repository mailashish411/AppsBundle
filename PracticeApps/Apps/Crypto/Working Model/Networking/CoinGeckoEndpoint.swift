//
//  CoinGeckoEndpoint.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//
import Foundation
enum CoinGeckoEndpoint: Endpoint {
    case markets(page: Int, perPage: Int)
    case coinDetail(id: String)

    var path: String {
        switch self {
        case .markets:
            return "/api/v3/coins/markets"
        case .coinDetail(let id):
            return "/api/v3/coins/\(id)"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .markets(page, perPage):
            return [
                .init(name: "vs_currency", value: "usd"),
                .init(name: "order", value: "market_cap_desc"),
                .init(name: "per_page", value: String(perPage)),
                .init(name: "page", value: String(page)),
                .init(name: "sparkline", value: "true"),
                .init(name: "price_change_percentage", value: "24h"),
                .init(name: "locale", value: "en")
            ]

        case .coinDetail:
            return [
                .init(name: "localization", value: "false"),
                .init(name: "tickers", value: "false"),
                .init(name: "market_data", value: "false"),
                .init(name: "community_data", value: "false"),
                .init(name: "developer_data", value: "false"),
                .init(name: "sparkline", value: "false")
            ]
        }
    }
}
