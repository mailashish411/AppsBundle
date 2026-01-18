//
//  APIClientProtocol.swift
//  SharedKit
//
//  Created by Ashish Shaik on 1/12/26.
//

import Foundation

public protocol APIClientProtocol {
    var session: URLSession { get }
    var decoder: JSONDecoder { get }
    func request<T: Decodable>(_ url: URL, as type: T.Type) async throws -> T
}

public extension APIClientProtocol {
    func request<T: Decodable>(_ url: URL, as type: T.Type) async throws -> T {
        let (data, response) = try await session.data(from: url)
        try validateHTTP(response: response, data: data)
        return try decode(type, from: data)
    }

    func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let url = try endpoint.url()
        return try await request(url, as: type)
    }

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            let snippet = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            throw APIError.decodingFailed(underlying: error, bodySnippet: String(snippet.prefix(400)))
        }
    }

    func validateHTTP(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(statusCode: http.statusCode, bodySnippet: String(body.prefix(400)))
        }
    }
}


import Foundation
import SharedKit

protocol CoinAPIClientProtocol {
    func fetchMarkets(page: Int, perPage: Int) async throws -> [CoinMarket]
    func fetchDetail(id: String) async throws -> CoinDetail
}

final class CoinGeckoClient: CoinAPIClientProtocol, APIClientProtocol {
    let session: URLSession
    let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func fetchMarkets(page: Int, perPage: Int) async throws -> [CoinMarket] {
        try await request(CoinGeckoEndpoint.markets(page: page, perPage: perPage), as: [CoinMarket].self)
    }

    func fetchDetail(id: String) async throws -> CoinDetail {
        try await request(CoinGeckoEndpoint.coinDetail(id: id), as: CoinDetail.self)
    }
}

public protocol Endpoint {
    var scheme: String { get }
    var host: String { get }
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
}

public extension Endpoint {
    var scheme: String { "https" }
    var queryItems: [URLQueryItem] { [] }

    func url() throws -> URL {
        var c = URLComponents()
        c.scheme = scheme
        c.host = host
        c.path = path
        c.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = c.url else { throw URLError(.badURL) }
        return url
    }
}

//
//  CoinGeckoEndpoint.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//
import Foundation
import SharedKit

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
    
    var host: String {
        return "api.coingecko.com"
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
