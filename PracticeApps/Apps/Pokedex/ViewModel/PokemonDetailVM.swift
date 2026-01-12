//
//  PokemonDetailVM.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/12/26.
//

import Foundation
import SharedKit

@Observable
final class PokemonDetailVM {
    private let service: PokemonServicing

    private(set) var state: LoadState<PokemonDetailResponse> = .idle

    private static var cache: [String: PokemonDetailResponse] = [:]

    init(service: PokemonServicing = PokemonAPI()) {
        self.service = service
    }

    @MainActor
    func load(item: PokemonListItem) async {
        if case .success = state { return }

        if let cached = Self.cache[item.url] {
            state = .success(cached)
            return
        }

        guard let url = URL(string: item.url) else {
            state = .failure("Invalid URL")
            return
        }

        state = .loading
        do {
            let d = try await service.detail(url: url)
            Self.cache[item.url] = d
            state = .success(d)
        } catch {
            state = .failure("Failed to load detail.")
        }
    }
}
