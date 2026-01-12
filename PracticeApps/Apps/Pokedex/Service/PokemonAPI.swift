//
//  PokemonAPI.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/12/26.
//

import Foundation

// MARK: - API (Real Service)
struct PokemonAPI: PokemonServicing {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func list(url: URL? = nil) async throws -> PokemonResponse {
        let u = url ?? URL(string: "https://pokeapi.co/api/v2/pokemon")!
        return try await request(u)
    }

    func detail(url: URL) async throws -> PokemonDetailResponse {
        try await request(url)
    }

    private func request<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
