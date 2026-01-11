//
//  PokemonListView.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import SwiftUI

// MARK: - UI

//struct PokemonListView: View {
//    @State private var viewModel = PokemonListViewModel()
//
//    var body: some View {
//        Group {
//            if let errorMessage = viewModel.errorMessage {
//                Text(errorMessage)
//                    .lineLimit(5)
//                    .padding(16)
//            } else if let pokemon = viewModel.pokemon {
//                ScrollView {
//                    LazyVStack(spacing: 8) {
//                        ForEach(pokemon.results, id: \.id) { result in
//                            PokemonRowView(for: result)
//                        }
//                    }
//                    .padding(.vertical, 8)
//                }
//                .environment(viewModel)
//            } else {
//                ProgressView()
//            }
//        }
//        .task {
//            await viewModel.fetchPokemons()
//        }
//    }
//}
//
//struct PokemonRowView: View {
//    let pokemon: PokemonResult
//    @Environment(PokemonListViewModel.self) private var viewModel
//
//    init(for pokemon: PokemonResult) {
//        self.pokemon = pokemon
//    }
//
//    var body: some View {
//        HStack(spacing: 20) {
//            let spriteURL = viewModel.spriteURLByDetailURL[pokemon.url] ?? ""
//            PokemonRemoteImage(url: spriteURL.isEmpty ? pokemon.url : spriteURL)
//
//            Text(pokemon.name.capitalized)
//                .frame(height: 60)
//            Spacer()
//        }
//        .padding(.horizontal, 10)
//        .frame(maxWidth: .infinity)
//        .foregroundColor(Color.white)
//        .background(
//            RoundedRectangle(cornerRadius: 14, style: .continuous)
//                .fill(Color.green)
//        )
//        .padding(.horizontal, 10)
//    }
//}
//
//struct PokemonRemoteImage: View {
//    let url: String
//
//    @State private var imageURL: String?
//    @State private var uiImage: UIImage?
//
//    var body: some View {
//        Group {
//            if let uiImage {
//                Image(uiImage: uiImage)
//                    .resizable()
//                    .scaledToFit()
//            } else {
//                Image(systemName: "globe.fill")
//                    .resizable()
//                    .scaledToFit()
//                    .opacity(0.7)
//            }
//        }
//        .frame(width: 34, height: 34)
//        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
//        .task(id: url) {
//            await load()
//        }
//    }
//
//    private func load() async {
//        // if caller passed sprite URL already, just use it
//        if url.contains("raw.githubusercontent.com") || url.contains("pokeapi") && url.contains(".png") {
//            await loadImage(from: url)
//            return
//        }
//
//        // otherwise treat as detail URL -> decode -> get sprites.front_default
//        do {
//            let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)
//            let detail = try JSONDecoder().decode(PokemonDetail.self, from: data)
//            guard let sprite = detail.sprites.frontDefault else { return }
//            await loadImage(from: sprite)
//        } catch {
//            // ignore -> keep placeholder
//        }
//    }
//
//    private func loadImage(from urlString: String) async {
//        guard let u = URL(string: urlString) else { return }
//        do {
//            let (data, _) = try await URLSession.shared.data(from: u)
//            guard let img = UIImage(data: data) else { return }
//            await MainActor.run { self.uiImage = img }
//        } catch {
//            // ignore
//        }
//    }
//}
//
//// MARK: - ViewModel (UPDATED: TaskGroup + Mapping)
//
//@Observable
//class PokemonListViewModel {
//    var pokemon: Pokemon?
//    var errorMessage: String?
//
//    /// Cache: detail URL -> image URL (front_default)
//    /// You can use this later if you want the row to show real sprite URLs.
//    var spriteURLByDetailURL: [String: String] = [:]
//
//    let service = PokemonService()
//    private var isLoading = false
//
//    @MainActor
//    func fetchPokemons() async {
//        guard !isLoading else { return }
//        isLoading = true
//        defer { isLoading = false }
//
//        do {
//            let pokemonObj = try await service.fetchPokemons()
//            self.pokemon = pokemonObj
//
//            // Fetch details concurrently (TaskGroup)
//            let results = pokemonObj.results
//
//            // Only fetch those we don't already have
//            let missing = results.filter { spriteURLByDetailURL[$0.url] == nil }
//            guard !missing.isEmpty else { return }
//
//            try await withThrowingTaskGroup(of: (String, PokemonDetail).self) { group in
//                for item in missing {
//                    group.addTask {
//                        let detail = try await self.service.fetchPokemon(from: item.url)
//                        return (item.url, detail) // key = detail URL
//                    }
//                }
//
//                for try await (detailURL, detail) in group {
//                    // Store sprite URL for later use
//                    if let sprite = detail.sprites.frontDefault {
//                        await MainActor.run {
//                            self.spriteURLByDetailURL[detailURL] = sprite
//                        }
//                    }
//                }
//            }
//
//        } catch let err as PokeAPIError {
//            self.errorMessage = err.errorDescription
//        } catch {
//            self.errorMessage = error.localizedDescription
//        }
//    }
//}
//
//// MARK: - Errors
//
//enum PokeAPIError: Error {
//    case invalidResponse
//    case badRequestURL
//
//    var errorDescription: String {
//        switch self {
//        case .invalidResponse:
//            return "Invalid Response"
//        case .badRequestURL:
//            return "Bad Request"
//        }
//    }
//}
//
//// MARK: - Service
//
//final class PokemonService {
//
//    func fetchPokemons() async throws -> Pokemon {
//        guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon") else {
//            throw PokeAPIError.badRequestURL
//        }
//
//        let (data, response) = try await URLSession.shared.data(from: url)
//
//        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
//            throw PokeAPIError.invalidResponse
//        }
//
//        return try JSONDecoder().decode(Pokemon.self, from: data)
//    }
//
//    func fetchPokemon(from pokemon: String) async throws -> PokemonDetail {
//        guard let url = URL(string: pokemon) else {
//            throw PokeAPIError.badRequestURL
//        }
//
//        let (data, response) = try await URLSession.shared.data(from: url)
//
//        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
//            throw PokeAPIError.invalidResponse
//        }
//
//        return try JSONDecoder().decode(PokemonDetail.self, from: data)
//    }
//}
//
//// MARK: - Models
//
//struct Pokemon: Codable, Hashable {
//    let next: String?
//    let results: [PokemonResult]
//}
//
//struct PokemonDetail: Codable, Hashable {
//    let id: Int
//    let name: String
//    let sprites: Sprites
//}
//
//struct Sprites: Codable, Hashable {
//    let frontDefault: String?
//
//    enum CodingKeys: String, CodingKey {
//        case frontDefault = "front_default"
//    }
//}
//
//struct PokemonResult: Codable, Identifiable, Hashable {
//    let name: String
//    let url: String
//
//    var id: String { url }
//}
//
//#Preview {
//    PokemonListView()
//}

//-----------------------------2-------------------------------------------------------------

//import SwiftUI
//import Foundation
//import UIKit
//
//// MARK: - App Entry
//
//// MARK: - Screens
//
//struct PokemonListScreen: View {
//    @StateObject private var vm = PokemonListViewModel()
//    @Namespace private var heroNS
//
//    @State private var searchText: String = ""
//    @State private var selected: PokemonListItem?
//
//    private var filteredItems: [PokemonListItem] {
//        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
//        guard !q.isEmpty else { return vm.items }
//        return vm.items.filter { $0.name.lowercased().contains(q) }
//    }
//
//    var body: some View {
//        NavigationStack {
//            Group {
//                if let error = vm.errorMessage {
//                    VStack(spacing: 12) {
//                        Text("Error")
//                            .font(.title2.bold())
//                        Text(error)
//                            .multilineTextAlignment(.center)
//                            .foregroundStyle(.secondary)
//                        Button("Retry") {
//                            Task { await vm.refresh() }
//                        }
//                        .buttonStyle(.borderedProminent)
//                    }
//                    .padding()
//                } else {
//                    ScrollView {
//                        LazyVStack(spacing: 10) {
//                            ForEach(filteredItems) { item in
//                                PokemonRowView(
//                                    item: item,
//                                    spriteURL: vm.spriteByDetailURL[item.detailURL],
//                                    ns: heroNS
//                                )
//                                .contentShape(Rectangle())
//                                .onTapGesture {
//                                    selected = item
//                                }
//                                .onAppear {
//                                    // Pagination trigger (when you hit near bottom)
//                                    if item == filteredItems.last {
//                                        Task { await vm.loadNextPageIfNeeded() }
//                                    }
//                                }
//                            }
//
//                            if vm.isLoadingPage {
//                                HStack {
//                                    Spacer()
//                                    ProgressView()
//                                        .padding(.vertical, 16)
//                                    Spacer()
//                                }
//                            }
//                        }
//                        .padding(.vertical, 10)
//                    }
//                }
//            }
//            .navigationTitle("Pokédex")
//            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
//            .refreshable {
//                await vm.refresh()
//            }
//            .task {
//                await vm.loadInitialIfNeeded()
//            }
//            .navigationDestination(item: $selected) { item in
//                PokemonDetailScreen(
//                    item: item,
//                    spriteURL: vm.spriteByDetailURL[item.detailURL],
//                    detail: vm.detailByDetailURL[item.detailURL],
//                    ns: heroNS
//                )
//            }
//        }
//    }
//}
//
//// MARK: - Row
//
//struct PokemonRowView: View {
//    let item: PokemonListItem
//    let spriteURL: String?
//    let ns: Namespace.ID
//
//    var body: some View {
//        HStack(spacing: 14) {
//            RemoteImageView(urlString: spriteURL ?? "", size: 52)
//                .matchedGeometryEffect(id: "img-\(item.id)", in: ns)
//
//            VStack(alignment: .leading, spacing: 2) {
//                Text(item.name.capitalized)
//                    .font(.headline.weight(.semibold))
//                    .foregroundColor(.white)
//
//                Text("#\(item.dexNumber ?? 0)")
//                    .font(.subheadline)
//                    .foregroundColor(.white.opacity(0.75))
//            }
//
//            Spacer()
//
//            Image(systemName: "chevron.right")
//                .font(.subheadline.weight(.semibold))
//                .foregroundColor(.white.opacity(0.75))
//        }
//        .padding(.horizontal, 14)
//        .frame(height: 82)
//        .frame(maxWidth: .infinity)
//        .background(
//            RoundedRectangle(cornerRadius: 18, style: .continuous)
//                .fill(Color.green)
//                .matchedGeometryEffect(id: "card-\(item.id)", in: ns)
//        )
//        .padding(.horizontal, 12)
//    }
//}
//
//// MARK: - Detail Screen (matched hero + sheet slide-up)
//
//struct PokemonDetailScreen: View {
//    let item: PokemonListItem
//    let spriteURL: String?
//    let detail: PokemonDetail?
//    let ns: Namespace.ID
//
//    @Environment(\.dismiss) private var dismiss
//    @State private var showSheet = false
//
//    var body: some View {
//        ZStack(alignment: .top) {
//
//            // Hero background expands from row card
//            RoundedRectangle(cornerRadius: 0, style: .continuous)
//                .fill(Color.green)
//                .matchedGeometryEffect(id: "card-\(item.id)", in: ns)
//                .frame(height: 340)
//                .ignoresSafeArea()
//
//            VStack(spacing: 12) {
//                HStack {
//                    Button {
//                        dismiss()
//                    } label: {
//                        Image(systemName: "chevron.left")
//                            .font(.headline.weight(.semibold))
//                            .foregroundColor(.white)
//                            .padding(12)
//                            .background(.white.opacity(0.15), in: Circle())
//                    }
//
//                    Spacer()
//                }
//                .padding(.top, 6)
//
//                RemoteImageView(urlString: spriteURL ?? "", size: 170)
//                    .matchedGeometryEffect(id: "img-\(item.id)", in: ns)
//
//                Text(item.name.capitalized)
//                    .font(.largeTitle.bold())
//                    .foregroundColor(.white)
//
//                if let id = detail?.id {
//                    Text("Pokémon ID: \(id)")
//                        .foregroundColor(.white.opacity(0.8))
//                        .font(.subheadline)
//                }
//
//                Spacer()
//            }
//            .padding(.horizontal, 16)
//            .frame(height: 340)
//
//            // Sheet slides up like the video
//            if showSheet {
//                VStack(alignment: .leading, spacing: 16) {
//                    HStack {
//                        Spacer()
//                        Capsule()
//                            .fill(.gray.opacity(0.35))
//                            .frame(width: 44, height: 6)
//                        Spacer()
//                    }
//                    .padding(.top, 10)
//
//                    Text("Details")
//                        .font(.title2.bold())
//
//                    if let detail {
//                        VStack(alignment: .leading, spacing: 10) {
//                            Text("Name: \(detail.name.capitalized)")
//                            Text("Height: \(detail.height)")
//                            Text("Weight: \(detail.weight)")
//                        }
//                        .font(.body)
//                        .foregroundStyle(.secondary)
//                    } else {
//                        HStack(spacing: 10) {
//                            ProgressView()
//                            Text("Loading details…")
//                                .foregroundStyle(.secondary)
//                        }
//                    }
//
//                    Spacer()
//                }
//                .padding(.horizontal, 18)
//                .frame(maxWidth: .infinity)
//                .frame(minHeight: 520)
//                .background(
//                    RoundedRectangle(cornerRadius: 30, style: .continuous)
//                        .fill(Color.white)
//                )
//                .padding(.top, 300)
//                .transition(.move(edge: .bottom).combined(with: .opacity))
//            }
//        }
//        .toolbar(.hidden, for: .navigationBar)
//        .onAppear {
//            withAnimation(.spring(response: 0.58, dampingFraction: 0.88)) {
//                showSheet = true
//            }
//        }
//    }
//}
//
//// MARK: - ViewModel (pagination + search support + TaskGroup sprite prefetch)
//import Combine
//final class PokemonListViewModel: ObservableObject {
//    @Published var items: [PokemonListItem] = []
//    @Published var isLoadingPage: Bool = false
//    @Published var errorMessage: String?
//
//    /// detailURL -> sprite url (front_default)
//    @Published var spriteByDetailURL: [String: String] = [:]
//
//    /// detailURL -> detail (so the detail screen can show content instantly)
//    @Published var detailByDetailURL: [String: PokemonDetail] = [:]
//
//    private let service = PokemonService()
//    private var nextURL: String? = "https://pokeapi.co/api/v2/pokemon?offset=0&limit=20"
//
//    func loadInitialIfNeeded() async {
//        guard items.isEmpty else { return }
//        await loadNextPageIfNeeded()
//    }
//
//    func refresh() async {
//        await MainActor.run {
//            errorMessage = nil
//            items = []
//            spriteByDetailURL = [:]
//            detailByDetailURL = [:]
//            nextURL = "https://pokeapi.co/api/v2/pokemon?offset=0&limit=20"
//        }
//        await loadNextPageIfNeeded()
//    }
//
//    func loadNextPageIfNeeded() async {
//        guard !isLoadingPage else { return }
//        guard let nextURL else { return }
//
//        await MainActor.run {
//            isLoadingPage = true
//            errorMessage = nil
//        }
//        defer { Task { @MainActor in self.isLoadingPage = false } }
//
//        do {
//            let page = try await service.fetchPokemonPage(urlString: nextURL)
//
//            // Convert API items into list items (and also derive dex number from URL)
//            let newItems: [PokemonListItem] = page.results.map { api in
//                PokemonListItem(
//                    name: api.name,
//                    detailURL: api.url,
//                    dexNumber: PokemonListItem.extractDexNumber(from: api.url)
//                )
//            }
//
//            await MainActor.run {
//                self.items.append(contentsOf: newItems)
//                self.nextURL = page.next
//            }
//
//            // Prefetch sprites + detail concurrently for ONLY the new items
//            await prefetchDetailsAndSprites(for: newItems)
//
//        } catch {
//            await MainActor.run {
//                self.errorMessage = (error as? PokeAPIError)?.errorDescription ?? error.localizedDescription
//            }
//        }
//    }
//
//    private func prefetchDetailsAndSprites(for newItems: [PokemonListItem]) async {
//        // only fetch missing
//        let missing = newItems.filter { detailByDetailURL[$0.detailURL] == nil }
//        guard !missing.isEmpty else { return }
//
//        do {
//            try await withThrowingTaskGroup(of: (String, PokemonDetail).self) { group in
//                for item in missing {
//                    group.addTask { [service] in
//                        let detail = try await service.fetchPokemonDetail(urlString: item.detailURL)
//                        return (item.detailURL, detail) // map back to row via detailURL
//                    }
//                }
//
//                for try await (detailURL, detail) in group {
//                    await MainActor.run {
//                        self.detailByDetailURL[detailURL] = detail
//                        if let sprite = detail.sprites.frontDefault {
//                            self.spriteByDetailURL[detailURL] = sprite
//                        }
//                    }
//                }
//            }
//        } catch {
//            // If some fail, we still keep the list usable.
//        }
//    }
//}
//
//// MARK: - Networking
//
//enum PokeAPIError: Error {
//    case badRequestURL
//    case invalidResponse(Int)
//    case decodeFailed(String)
//
//    var errorDescription: String {
//        switch self {
//        case .badRequestURL:
//            return "Bad Request URL"
//        case .invalidResponse(let code):
//            return "Invalid Response (HTTP \(code))"
//        case .decodeFailed(let msg):
//            return "Decode failed: \(msg)"
//        }
//    }
//}
//
//final class PokemonService {
//    private let decoder = JSONDecoder()
//
//    func fetchPokemonPage(urlString: String) async throws -> PokemonPageResponse {
//        guard let url = URL(string: urlString) else { throw PokeAPIError.badRequestURL }
//        let (data, response) = try await URLSession.shared.data(from: url)
//
//        guard let http = response as? HTTPURLResponse else { throw PokeAPIError.invalidResponse(-1) }
//        guard (200...299).contains(http.statusCode) else { throw PokeAPIError.invalidResponse(http.statusCode) }
//
//        do {
//            return try decoder.decode(PokemonPageResponse.self, from: data)
//        } catch {
//            throw PokeAPIError.decodeFailed(error.localizedDescription)
//        }
//    }
//
//    func fetchPokemonDetail(urlString: String) async throws -> PokemonDetail {
//        guard let url = URL(string: urlString) else { throw PokeAPIError.badRequestURL }
//        let (data, response) = try await URLSession.shared.data(from: url)
//
//        guard let http = response as? HTTPURLResponse else { throw PokeAPIError.invalidResponse(-1) }
//        guard (200...299).contains(http.statusCode) else { throw PokeAPIError.invalidResponse(http.statusCode) }
//
//        do {
//            return try decoder.decode(PokemonDetail.self, from: data)
//        } catch {
//            throw PokeAPIError.decodeFailed(error.localizedDescription)
//        }
//    }
//}
//
//// MARK: - Models
//
//// API page response
//struct PokemonPageResponse: Codable, Hashable {
//    let count: Int
//    let next: String?
//    let previous: String?
//    let results: [PokemonAPIResult]
//}
//
//struct PokemonAPIResult: Codable, Hashable {
//    let name: String
//    let url: String
//}
//
//// UI list item (what your views use)
//struct PokemonListItem: Identifiable, Hashable {
//    let name: String
//    let detailURL: String
//    let dexNumber: Int?
//
//    var id: String { detailURL }
//
//    static func extractDexNumber(from detailURL: String) -> Int? {
//        // Example: https://pokeapi.co/api/v2/pokemon/1/
//        let trimmed = detailURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
//        return Int(trimmed.split(separator: "/").last ?? "")
//    }
//}
//
//// Detail response (minimal)
//struct PokemonDetail: Codable, Hashable {
//    let id: Int
//    let name: String
//    let height: Int
//    let weight: Int
//    let sprites: Sprites
//}
//
//struct Sprites: Codable, Hashable {
//    let frontDefault: String?
//
//    enum CodingKeys: String, CodingKey {
//        case frontDefault = "front_default"
//    }
//}
//
//// MARK: - Remote Image (simple cache)
//
//final class ImageMemoryCache {
//    static let shared = ImageMemoryCache()
//    private let cache = NSCache<NSString, UIImage>()
//
//    func get(_ key: String) -> UIImage? {
//        cache.object(forKey: key as NSString)
//    }
//
//    func set(_ image: UIImage, for key: String) {
//        cache.setObject(image, forKey: key as NSString)
//    }
//}

//-----------------------------3-------------------------------------------------------------

import SwiftUI
import Foundation
import UIKit

// MARK: - ✅ ONE-FILE POKEDEX (List + Search + Pagination + Hero Animation + Detail UI)

struct PokedexAppView: View {
    @State private var vm = PokedexViewModel()
    @Namespace private var heroNS
    @State private var selected: PokemonListItem?

    var body: some View {
        NavigationStack {
            ZStack {
                // Soft app background like your screenshot
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 12) {
                    headerBar

                    searchBar

                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(vm.visibleItems) { item in
                                let detail = vm.detailByURL[item.url]

                                PokemonCardRow(
                                    item: item,
                                    detail: detail,
                                    ns: heroNS
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selected = item
                                }
                                .onAppear {
                                    vm.loadMoreIfNeeded(currentItem: item)
                                }
                            }

                            if vm.isLoadingPage {
                                ProgressView().padding(.vertical, 20)
                            } else if vm.hasMorePages == false {
                                Text("End of list").foregroundStyle(.secondary).padding(.vertical, 20)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }
                    .refreshable {
                        await vm.refresh()
                    }
                }
            }
            .task {
                await vm.loadInitial()
            }
            .navigationDestination(item: $selected) { item in
                PokemonDetailScreen(
                    item: item,
                    ns: heroNS,
                    detailProvider: { vm.detailByURL[item.url] },
                    fetchDetail: { await vm.ensureDetail(for: item) }
                )
            }
        }
    }

    private var headerBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Pokédex")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color.red)

                    Image(systemName: "chevron.down")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Text("Search & explore Pokémon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                // placeholder
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search for a Pokémon…", text: $vm.searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            // ✅ Filter menu (uses PokedexTypeFilter)
            Menu {
                Picker("Filter", selection: $vm.typeFilter) {
                    ForEach(PokedexTypeFilter.allCases) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            // ✅ Sort menu (uses PokedexSortOption)
            Menu {
                Picker("Sort", selection: $vm.sortOption) {
                    ForEach(PokedexSortOption.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(.horizontal, 14)
    }
}

//enum SortOption: String, CaseIterable, Identifiable {
//    case dexAsc = "Dex ↑"
//    case dexDesc = "Dex ↓"
//    case nameAsc = "Name A→Z"
//    case nameDesc = "Name Z→A"
//
//    var id: String { rawValue }
//}
//
//enum TypeFilter: String, CaseIterable, Identifiable {
//    case all = "All"
//    case grass = "Grass"
//    case poison = "Poison"
//    case fire = "Fire"
//    case water = "Water"
//    case electric = "Electric"
//    case normal = "Normal"
//    case ground = "Ground"
//    case flying = "Flying"
//    case psychic = "Psychic"
//    case bug = "Bug"
//    case rock = "Rock"
//    case ghost = "Ghost"
//    case ice = "Ice"
//    case dragon = "Dragon"
//    case dark = "Dark"
//    case steel = "Steel"
//    case fairy = "Fairy"
//    case fighting = "Fighting"
//
//    var id: String { rawValue }
//}

// MARK: - Row Card (matches your screenshot style)

private struct PokemonCardRow: View {
    let item: PokemonListItem
    let detail: PokemonDetail?
    let ns: Namespace.ID

    private var numberText: String {
        let num = detail?.id ?? item.dexNumberGuess
        return String(format: "#%03d", num)
    }

    private var types: [String] {
        detail?.types.map(\.type.name) ?? []
    }

    private var spriteURL: String? {
        detail?.sprites.other?.officialArtwork.frontDefault ?? detail?.sprites.frontDefault
    }

    private var gradient: LinearGradient {
        let base = (types.first ?? "normal")
        let c1 = PokeTypeColor.color(for: base).opacity(0.85)
        let c2 = PokeTypeColor.color(for: base).opacity(0.40)
        return LinearGradient(colors: [c1, c2], startPoint: .leading, endPoint: .trailing)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(gradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .matchedGeometryEffect(id: "card-\(item.id)", in: ns)

            // faint big number on right
            HStack {
                Spacer()
                Text(numberText)
                    .font(.system(size: 54, weight: .heavy))
                    .foregroundStyle(Color.white.opacity(0.18))
                    .padding(.trailing, 14)
            }

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 64, height: 64)

                    RemoteImageView(urlString: spriteURL ?? "", size: 60)
                        .matchedGeometryEffect(id: "img-\(item.id)", in: ns)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name.capitalized)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(.white)

                    HStack(spacing: 6) {
                        ForEach(types.prefix(2), id: \.self) { t in
                            TypeChip(type: t)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Button {
                        // placeholder favorite
                    } label: {
                        Image(systemName: "heart")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.65))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .frame(height: 110)
    }
}

private struct TypeChip: View {
    let type: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(PokeTypeColor.color(for: type))
                .frame(width: 10, height: 10)
            Text(type.capitalized)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.95))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.16), in: Capsule())
    }
}

// MARK: - Detail Screen (hero + sliding white sheet)
private struct PokemonDetailScreen: View {
    let item: PokemonListItem
    let ns: Namespace.ID
    let detailProvider: () -> PokemonDetail?
    let fetchDetail: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showSheet = false

    private var detail: PokemonDetail? { detailProvider() }
    private var types: [String] { detail?.types.map(\.type.name) ?? [] }

    private var spriteURL: String? {
        detail?.sprites.other?.officialArtwork.frontDefault ?? detail?.sprites.frontDefault
    }

    private var numberText: String {
        let num = detail?.id ?? item.dexNumberGuess
        return String(format: "#%03d", num)
    }

    private var headerGradient: LinearGradient {
        let base = types.first ?? "normal"
        let c1 = PokeTypeColor.color(for: base).opacity(0.95)
        let c2 = PokeTypeColor.color(for: base).opacity(0.55)
        return LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let safeBottom = geo.safeAreaInsets.bottom
            let screenH = geo.size.height

            let headerH = max(260, min(360, screenH * 0.42))
            let sheetTop = headerH - 34

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 0, style: .continuous)
                    .fill(headerGradient)
                    .matchedGeometryEffect(id: "card-\(item.id)", in: ns)
                    .frame(height: headerH + safeTop)
                    .ignoresSafeArea()

                Circle()
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 420, height: 420)
                    .offset(x: 160, y: -160)
                    .allowsHitTesting(false)

                // Header content
                VStack(spacing: 0) {
                    topBar
                        .padding(.top, safeTop + 8)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(numberText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.85))

                        Text(item.name.capitalized)
                            .font(.system(size: 40, weight: .heavy))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        HStack(spacing: 8) {
                            ForEach(types.prefix(3), id: \.self) { t in
                                TypeChip(type: t)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                    RemoteImageView(urlString: spriteURL ?? "", size: min(240, geo.size.width * 0.62))
                        .matchedGeometryEffect(id: "img-\(item.id)", in: ns)
                        .padding(.top, 8)

                    // ✅ Show details button (only when sheet is hidden)
                    if !showSheet {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                                showSheet = true
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                Text("Show details")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.18),
                                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .padding(.top, 10)
                    }

                    Spacer(minLength: 0)
                }
                .frame(height: headerH + safeTop)

                // ✅ Bottom sheet (only when showSheet == true)
                if showSheet {
                    DetailSheet(
                        detail: detail,
                        fallbackName: item.name,
                        onClose: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                                showSheet = false
                            }
                        }
                    )
                    .frame(height: max(260, screenH - sheetTop))
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: -6)
                    .padding(.top, sheetTop)
                    .padding(.bottom, safeBottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                // ✅ Fetch detail data in background, but DO NOT auto-show sheet
                await fetchDetail()
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.18),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Spacer()

            Button {
                // placeholder
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.18),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button {
                // favorite placeholder
            } label: {
                Image(systemName: "heart")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.18),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(.horizontal, 14)
    }
}

private struct DetailSheet: View {
    let detail: PokemonDetail?
    let fallbackName: String
    let onClose: () -> Void

    @State private var selectedTab: Tab = .about

    enum Tab: String, CaseIterable {
        case about = "About"
        case stats = "Stats"
        case moves = "Moves"
        case other = "Other"
    }

    private var displayName: String {
        (detail?.name ?? fallbackName).capitalized
    }

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            tabBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case .about: aboutSection
                    case .stats: statsSection
                    case .moves: movesSection
                    case .other: otherSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
        }
        .background(
            // subtle sheet background
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground).opacity(0.45)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 12) {
            Spacer()

            Capsule()
                .fill(Color.gray.opacity(0.25))
                .frame(width: 44, height: 6)
                .padding(.leading, 44) // balances the close button size

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().fill(Color(.secondarySystemBackground))
                    )
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Tabs

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 10) {
                        Text(tab.rawValue)
                            .font(.subheadline.weight(selectedTab == tab ? .bold : .regular))
                            .foregroundStyle(selectedTab == tab ? Color.primary : Color.secondary)

                        Capsule()
                            .fill(selectedTab == tab ? Color.orange.opacity(0.85) : Color.clear)
                            .frame(height: 3)
                            .padding(.horizontal, 18)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 12)
    }

    // MARK: - Sections

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Title + subtitle card
            VStack(alignment: .leading, spacing: 6) {
                Text("About")
                    .font(.title2.weight(.heavy))

                Text("Basic profile and measurements")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)

            // Metrics row
            HStack(spacing: 12) {
                metricCard(
                    title: "Height",
                    value: heightString(detail?.height),
                    systemImage: "ruler"
                )
                metricCard(
                    title: "Weight",
                    value: weightString(detail?.weight),
                    systemImage: "scalemass"
                )
                metricCard(
                    title: "ID",
                    value: "\(detail?.id ?? 0)",
                    systemImage: "number"
                )
            }

            // Types
            VStack(alignment: .leading, spacing: 10) {
                Text("Types")
                    .font(.headline.weight(.bold))

                if let types = detail?.types.map({ $0.type.name }) {
                    HStack(spacing: 8) {
                        ForEach(types, id: \.self) { t in
                            TypeChip(type: t)
                        }
                    }
                } else {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Loading types…")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)

            // Name card
            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.headline.weight(.bold))
                Text(displayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Stats")
                    .font(.title2.weight(.heavy))
                Text("Base stats for this Pokémon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)

            if let stats = detail?.stats {
                ForEach(stats, id: \.stat.name) { s in
                    statRow(name: s.stat.name, value: s.baseStat)
                }
            } else {
                ProgressView().padding(.top, 8)
            }
        }
    }

    private var movesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Moves")
                    .font(.title2.weight(.heavy))
                Text("Some popular moves")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)

            if let moves = detail?.moves.prefix(18) {
                LazyVStack(spacing: 10) {
                    ForEach(moves, id: \.move.name) { m in
                        Text(m.move.name.replacingOccurrences(of: "-", with: " ").capitalized)
                            .font(.subheadline.weight(.semibold))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(cardBackground)
                    }
                }
            } else {
                ProgressView().padding(.top, 8)
            }
        }
    }

    private var otherSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Other")
                    .font(.title2.weight(.heavy))
                Text("You can add abilities, species, evolution, etc.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)

            Text("Placeholder section")
                .foregroundStyle(.secondary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
        }
    }

    // MARK: - Reusable UI

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(.secondarySystemBackground))
    }

    private func metricCard(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.headline.weight(.bold))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func statRow(name: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name.replacingOccurrences(of: "-", with: " ").capitalized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(value)")
                    .font(.subheadline.weight(.bold))
            }

            GeometryReader { geo in
                let w = geo.size.width
                let pct = min(max(CGFloat(value) / 160.0, 0), 1) // normalize a bit
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.18))
                    Capsule().fill(Color.orange.opacity(0.8))
                        .frame(width: w * pct)
                }
            }
            .frame(height: 10)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Unit formatting

    // PokeAPI: height in decimeters, weight in hectograms
    private func heightString(_ dm: Int?) -> String {
        guard let dm else { return "—" }
        let meters = Double(dm) / 10.0
        let feet = meters * 3.28084
        let feetInt = Int(feet)
        let inches = Int((feet - Double(feetInt)) * 12.0)
        return String(format: "%.1f m  •  %d'%d\"", meters, feetInt, inches)
    }

    private func weightString(_ hg: Int?) -> String {
        guard let hg else { return "—" }
        let kg = Double(hg) / 10.0
        let lbs = kg * 2.20462
        return String(format: "%.1f kg  •  %.1f lb", kg, lbs)
    }
}




// MARK: - ViewModel (Pagination + Search + TaskGroup details)

import Foundation
import Observation

// MARK: - Sort / Filter

enum PokedexSortOption: String, CaseIterable, Identifiable {
    case dexAsc = "Dex ↑"
    case dexDesc = "Dex ↓"
    case nameAsc = "Name A→Z"
    case nameDesc = "Name Z→A"

    var id: String { rawValue }
}

enum PokedexTypeFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case grass = "Grass"
    case poison = "Poison"
    case fire = "Fire"
    case water = "Water"
    case electric = "Electric"
    case normal = "Normal"
    case ground = "Ground"
    case flying = "Flying"
    case psychic = "Psychic"
    case bug = "Bug"
    case rock = "Rock"
    case ghost = "Ghost"
    case ice = "Ice"
    case dragon = "Dragon"
    case dark = "Dark"
    case steel = "Steel"
    case fairy = "Fairy"
    case fighting = "Fighting"

    var id: String { rawValue }

    var apiValueLowercased: String {
        rawValue.lowercased()
    }
}

// MARK: - ViewModel

@Observable
final class PokedexViewModel {
    // UI state
    var searchText: String = ""
    var errorMessage: String?
    var isLoadingPage: Bool = false

    // ✅ New: sort + filter state
    var sortOption: PokedexSortOption = .dexAsc
    var typeFilter: PokedexTypeFilter = .all

    // Pagination
    private(set) var nextURL: String? = "https://pokeapi.co/api/v2/pokemon?offset=0&limit=20"
    var hasMorePages: Bool { nextURL != nil }

    // Data
    private(set) var items: [PokemonListItem] = []
    private(set) var detailByURL: [String: PokemonDetail] = [:]

    private let api = PokeAPIClient()

    // MARK: - Derived

    /// ✅ Use this in your UI instead of `filteredItems`
    var visibleItems: [PokemonListItem] {
        // 1) SEARCH
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var list = items

        if !q.isEmpty {
            list = list.filter { item in
                // match by name
                if item.name.lowercased().contains(q) { return true }

                // match by dex id if detail already loaded
                if let id = detailByURL[item.url]?.id,
                   String(id).contains(q) { return true }

                return false
            }
        }

        // 2) FILTER (by type)
        if typeFilter != .all {
            let wanted = typeFilter.apiValueLowercased
            list = list.filter { item in
                guard let detail = detailByURL[item.url] else {
                    // ✅ hide until detail is available
                    return false
                }
                return detail.types.contains { $0.type.name.lowercased() == wanted }
            }
        }

        // 3) SORT
        switch sortOption {
        case .dexAsc:
            list.sort { lhs, rhs in
                let l = detailByURL[lhs.url]?.id ?? Int.max
                let r = detailByURL[rhs.url]?.id ?? Int.max
                if l != r { return l < r }
                return lhs.name < rhs.name
            }

        case .dexDesc:
            list.sort { lhs, rhs in
                let l = detailByURL[lhs.url]?.id ?? Int.min
                let r = detailByURL[rhs.url]?.id ?? Int.min
                if l != r { return l > r }
                return lhs.name > rhs.name
            }

        case .nameAsc:
            list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        case .nameDesc:
            list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        }

        return list
    }

    // Backwards compatible if your UI still references it
    var filteredItems: [PokemonListItem] { visibleItems }

    // MARK: - Public API

    @MainActor
    func loadInitial() async {
        guard items.isEmpty else { return }
        await loadNextPage()
    }

    @MainActor
    func refresh() async {
        searchText = ""
        typeFilter = .all
        sortOption = .dexAsc
        errorMessage = nil
        nextURL = "https://pokeapi.co/api/v2/pokemon?offset=0&limit=20"
        items = []
        detailByURL = [:]
        await loadNextPage()
    }

    @MainActor
    func loadMoreIfNeeded(currentItem: PokemonListItem) {
        // prefetch when user gets near bottom
        guard let idx = items.firstIndex(of: currentItem) else { return }
        let threshold = max(items.count - 6, 0)
        if idx >= threshold {
            Task { await self.loadNextPage() }
        }
    }

    @MainActor
    func loadNextPage() async {
        guard !isLoadingPage else { return }
        guard let nextURL else { return }

        isLoadingPage = true
        defer { isLoadingPage = false }

        do {
            let page = try await api.fetchList(urlString: nextURL)
            self.nextURL = page.next

            // append new items (avoid duplicates)
            let existing = Set(items.map(\.url))
            let newItems = page.results.filter { !existing.contains($0.url) }
            items.append(contentsOf: newItems)

            // fetch details concurrently for new page items (sprite + types + id)
            await fetchDetails(for: newItems)

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func ensureDetail(for item: PokemonListItem) async {
        if detailByURL[item.url] != nil { return }
        await fetchDetails(for: [item])
    }

    // MARK: - Detail fetching

    @MainActor
    private func fetchDetails(for newItems: [PokemonListItem]) async {
        let missing = newItems.filter { detailByURL[$0.url] == nil }
        guard !missing.isEmpty else { return }

        do {
            try await withThrowingTaskGroup(of: (String, PokemonDetail).self) { group in
                for item in missing {
                    group.addTask {
                        let detail = try await self.api.fetchDetail(detailURLString: item.url)
                        return (item.url, detail)
                    }
                }

                for try await (url, detail) in group {
                    await MainActor.run {
                        self.detailByURL[url] = detail
                    }
                }
            }
        } catch {
            // don’t break the whole list if one detail fails
        }
    }
}

// MARK: - API Client

struct PokeAPIClient {
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    func fetchList(urlString: String) async throws -> PokemonListResponse {
        guard let url = URL(string: urlString) else { throw PokeError.badURL }

        let (data, response) = try await URLSession.shared.data(from: url)
        try validateHTTP(response: response, data: data)
        return try decoder.decode(PokemonListResponse.self, from: data)
    }

    func fetchDetail(detailURLString: String) async throws -> PokemonDetail {
        guard let url = URL(string: detailURLString) else { throw PokeError.badURL }

        let (data, response) = try await URLSession.shared.data(from: url)
        try validateHTTP(response: response, data: data)
        return try decoder.decode(PokemonDetail.self, from: data)
    }

    private func validateHTTP(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw PokeError.http(http.statusCode, String(body.prefix(200)))
        }
    }
}

enum PokeError: LocalizedError {
    case badURL
    case http(Int, String)

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Bad URL"
        case .http(let code, let body):
            return "HTTP \(code): \(body)"
        }
    }
}

// MARK: - Models (List + Detail)

struct PokemonListResponse: Codable, Hashable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [PokemonListItem]
}

struct PokemonListItem: Codable, Identifiable, Hashable {
    let name: String
    let url: String
    var id: String { url }

    // quick guess for #XXX before detail loads (extract /pokemon/123/)
    var dexNumberGuess: Int {
        let digits = url.split(separator: "/").last(where: { !$0.isEmpty }) ?? ""
        return Int(digits) ?? 0
    }
}

struct PokemonDetail: Codable, Hashable {
    let id: Int
    let name: String
    let height: Int      // decimeters
    let weight: Int      // hectograms
    let sprites: Sprites
    let types: [PokemonTypeSlot]
    let stats: [PokemonStat]
    let moves: [PokemonMoveSlot]
}

struct Sprites: Codable, Hashable {
    let frontDefault: String?
    let other: OtherSprites?

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
        case other
    }
}

struct OtherSprites: Codable, Hashable {
    let officialArtwork: OfficialArtwork

    enum CodingKeys: String, CodingKey {
        case officialArtwork = "official-artwork"
    }
}

struct OfficialArtwork: Codable, Hashable {
    let frontDefault: String?

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}

struct PokemonTypeSlot: Codable, Hashable {
    let slot: Int
    let type: NamedAPIResource
}

struct PokemonStat: Codable, Hashable {
    let baseStat: Int
    let stat: NamedAPIResource

    enum CodingKeys: String, CodingKey {
        case baseStat = "base_stat"
        case stat
    }
}

struct PokemonMoveSlot: Codable, Hashable {
    let move: NamedAPIResource
}

struct NamedAPIResource: Codable, Hashable {
    let name: String
    let url: String
}

// MARK: - Type Colors

enum PokeTypeColor {
    static func color(for type: String) -> Color {
        switch type.lowercased() {
        case "grass": return Color.green
        case "poison": return Color.purple
        case "fire": return Color.orange
        case "water": return Color.blue
        case "electric": return Color.yellow
        case "ice": return Color.cyan
        case "fighting": return Color.red.opacity(0.8)
        case "ground": return Color.brown
        case "flying": return Color.indigo.opacity(0.8)
        case "psychic": return Color.pink
        case "bug": return Color.green.opacity(0.75)
        case "rock": return Color.gray
        case "ghost": return Color.indigo
        case "dark": return Color.black.opacity(0.8)
        case "dragon": return Color.indigo.opacity(0.9)
        case "steel": return Color.gray.opacity(0.7)
        case "fairy": return Color.pink.opacity(0.75)
        case "normal": return Color.gray.opacity(0.6)
        default: return Color.gray.opacity(0.6)
        }
    }
}

// MARK: - Remote Image (simple in-memory cache, no AsyncImage)

final class ImageMemoryCache {
    static let shared = ImageMemoryCache()
    private let cache = NSCache<NSString, UIImage>()
    private init() { cache.countLimit = 300 }

    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func set(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

// MARK: - Preview

#Preview {
    PokedexAppView()
}
