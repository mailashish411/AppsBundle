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
