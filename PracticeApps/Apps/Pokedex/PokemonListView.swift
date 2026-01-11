//
//  PokemonListView.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import SwiftUI

// MARK: - UI

struct PokemonListView: View {
    @State private var viewModel = PokemonListViewModel()

    var body: some View {
        Group {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .lineLimit(5)
                    .padding(16)
            } else if let pokemon = viewModel.pokemon {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(pokemon.results, id: \.id) { result in
                            PokemonRowView(for: result)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .environment(viewModel)
            } else {
                ProgressView()
            }
        }
        .task {
            await viewModel.fetchPokemons()
        }
    }
}

struct PokemonRowView: View {
    let pokemon: PokemonResult
    @Environment(PokemonListViewModel.self) private var viewModel

    init(for pokemon: PokemonResult) {
        self.pokemon = pokemon
    }

    var body: some View {
        HStack(spacing: 20) {
            let spriteURL = viewModel.spriteURLByDetailURL[pokemon.url] ?? ""
            PokemonRemoteImage(url: spriteURL.isEmpty ? pokemon.url : spriteURL)

            Text(pokemon.name.capitalized)
                .frame(height: 60)
            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .foregroundColor(Color.white)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.green)
        )
        .padding(.horizontal, 10)
    }
}

struct PokemonRemoteImage: View {
    let url: String

    @State private var imageURL: String?
    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "globe.fill")
                    .resizable()
                    .scaledToFit()
                    .opacity(0.7)
            }
        }
        .frame(width: 34, height: 34)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .task(id: url) {
            await load()
        }
    }

    private func load() async {
        // if caller passed sprite URL already, just use it
        if url.contains("raw.githubusercontent.com") || url.contains("pokeapi") && url.contains(".png") {
            await loadImage(from: url)
            return
        }

        // otherwise treat as detail URL -> decode -> get sprites.front_default
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)
            let detail = try JSONDecoder().decode(PokemonDetail.self, from: data)
            guard let sprite = detail.sprites.frontDefault else { return }
            await loadImage(from: sprite)
        } catch {
            // ignore -> keep placeholder
        }
    }

    private func loadImage(from urlString: String) async {
        guard let u = URL(string: urlString) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: u)
            guard let img = UIImage(data: data) else { return }
            await MainActor.run { self.uiImage = img }
        } catch {
            // ignore
        }
    }
}

// MARK: - ViewModel (UPDATED: TaskGroup + Mapping)

@Observable
class PokemonListViewModel {
    var pokemon: Pokemon?
    var errorMessage: String?

    /// Cache: detail URL -> image URL (front_default)
    /// You can use this later if you want the row to show real sprite URLs.
    var spriteURLByDetailURL: [String: String] = [:]

    let service = PokemonService()
    private var isLoading = false

    @MainActor
    func fetchPokemons() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let pokemonObj = try await service.fetchPokemons()
            self.pokemon = pokemonObj

            // Fetch details concurrently (TaskGroup)
            let results = pokemonObj.results

            // Only fetch those we don't already have
            let missing = results.filter { spriteURLByDetailURL[$0.url] == nil }
            guard !missing.isEmpty else { return }

            try await withThrowingTaskGroup(of: (String, PokemonDetail).self) { group in
                for item in missing {
                    group.addTask {
                        let detail = try await self.service.fetchPokemon(from: item.url)
                        return (item.url, detail) // key = detail URL
                    }
                }

                for try await (detailURL, detail) in group {
                    // Store sprite URL for later use
                    if let sprite = detail.sprites.frontDefault {
                        await MainActor.run {
                            self.spriteURLByDetailURL[detailURL] = sprite
                        }
                    }
                }
            }

        } catch let err as PokeAPIError {
            self.errorMessage = err.errorDescription
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Errors

enum PokeAPIError: Error {
    case invalidResponse
    case badRequestURL

    var errorDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid Response"
        case .badRequestURL:
            return "Bad Request"
        }
    }
}

// MARK: - Service

final class PokemonService {

    func fetchPokemons() async throws -> Pokemon {
        guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon") else {
            throw PokeAPIError.badRequestURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw PokeAPIError.invalidResponse
        }

        return try JSONDecoder().decode(Pokemon.self, from: data)
    }

    func fetchPokemon(from pokemon: String) async throws -> PokemonDetail {
        guard let url = URL(string: pokemon) else {
            throw PokeAPIError.badRequestURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw PokeAPIError.invalidResponse
        }

        return try JSONDecoder().decode(PokemonDetail.self, from: data)
    }
}

// MARK: - Models

struct Pokemon: Codable, Hashable {
    let next: String?
    let results: [PokemonResult]
}

struct PokemonDetail: Codable, Hashable {
    let id: Int
    let name: String
    let sprites: Sprites
}

struct Sprites: Codable, Hashable {
    let frontDefault: String?

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}

struct PokemonResult: Codable, Identifiable, Hashable {
    let name: String
    let url: String

    var id: String { url }
}

#Preview {
    PokemonListView()
}
