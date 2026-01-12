//
//  PokedexAppView.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/12/26.
//

import SwiftUI
import Foundation
import UIKit
import Observation
import SharedKit

// MARK: - ✅ ONE-FILE POKEDEX (List + Search + Pagination + Hero + Detail Sheet + Sort/Filter working)

struct PokedexAppView: View {
    @State private var vm = PokedexViewModel()
    @Namespace private var heroNS
    @State private var selected: PokemonListItem?

    var body: some View {
        NavigationStack {
            ZStack {
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
                                .onTapGesture { selected = item }
                                .onAppear { vm.loadMoreIfNeeded(currentItem: item) }
                            }

                            if vm.isLoadingPage {
                                ProgressView().padding(.vertical, 20)
                            } else if vm.hasMorePages == false {
                                Text("End of list")
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 20)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }
                    .refreshable { await vm.refresh() }
                }
            }
            .task { await vm.loadInitial() }
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

            Button { } label: {
                Image(systemName: "gearshape")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
    }

    // ✅ Uses VM enums (PokedexTypeFilter / PokedexSortOption) so the UI ACTUALLY updates VM state
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

            // ✅ Filter menu
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

            // ✅ Sort menu
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

// MARK: - Sort / Filter enums (single source of truth)

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
    var apiValueLowercased: String { rawValue.lowercased() }
}

// MARK: - Row Card (gradient, hero animation)

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

                Button { } label: {
                    Image(systemName: "heart")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.65))
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

// MARK: - Detail Screen (hero header + manual sheet with close button)

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
                            .foregroundStyle(.white)
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
            .task { await fetchDetail() }
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

            Button { } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.18),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button { } label: {
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

    private var headerRow: some View {
        HStack(spacing: 12) {
            Spacer()
            Capsule()
                .fill(Color.gray.opacity(0.25))
                .frame(width: 44, height: 6)
                .padding(.leading, 44)
            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color(.secondarySystemBackground)))
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) { selectedTab = tab }
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

            HStack(spacing: 12) {
                metricCard(title: "Height", value: heightString(detail?.height), systemImage: "ruler")
                metricCard(title: "Weight", value: weightString(detail?.weight), systemImage: "scalemass")
                metricCard(title: "ID", value: "\(detail?.id ?? 0)", systemImage: "number")
            }

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
                let pct = min(max(CGFloat(value) / 160.0, 0), 1)
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

// MARK: - ViewModel (Pagination + Search + Sort + Filter + TaskGroup detail)

@Observable
final class PokedexViewModel {
    // UI state
    var searchText: String = ""
    var errorMessage: String?
    var isLoadingPage: Bool = false

    // ✅ sort + filter state
    var sortOption: PokedexSortOption = .dexAsc
    var typeFilter: PokedexTypeFilter = .all

    // Pagination
    private(set) var nextURL: String? = "https://pokeapi.co/api/v2/pokemon?offset=0&limit=20"
    var hasMorePages: Bool { nextURL != nil }

    // Data
    private(set) var items: [PokemonListItem] = []
    private(set) var detailByURL: [String: PokemonDetail] = [:]

    private let api = PokeAPIClient()

    // ✅ UI should always render this
    var visibleItems: [PokemonListItem] {
        var list = items

        // 1) SEARCH
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter { item in
                if item.name.lowercased().contains(q) { return true }
                if let id = detailByURL[item.url]?.id, String(id).contains(q) { return true }
                return false
            }
        }

        // 2) FILTER (by type)
        if typeFilter != .all {
            let wanted = typeFilter.apiValueLowercased
            list = list.filter { item in
                // ✅ If you want filter to visibly work immediately, hide items without detail
                guard let detail = detailByURL[item.url] else { return false }
                return detail.types.contains(where: { $0.type.name.lowercased() == wanted })
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

            let existing = Set(items.map(\.url))
            let newItems = page.results.filter { !existing.contains($0.url) }
            items.append(contentsOf: newItems)

            // Fetch details concurrently for new page items
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
                    await MainActor.run { self.detailByURL[url] = detail }
                }
            }
        } catch {
            // ignore individual failures
        }
    }
}

// MARK: - API Client

struct PokeAPIClient {
    private let decoder: JSONDecoder = JSONDecoder()

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
        case .badURL: return "Bad URL"
        case .http(let code, let body): return "HTTP \(code): \(body)"
        }
    }
}

// MARK: - Models

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

    var dexNumberGuess: Int {
        let digits = url.split(separator: "/").last(where: { !$0.isEmpty }) ?? ""
        return Int(digits) ?? 0
    }
}

struct PokemonDetail: Codable, Hashable {
    let id: Int
    let name: String
    let height: Int
    let weight: Int
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
        case "grass": return .green
        case "poison": return .purple
        case "fire": return .orange
        case "water": return .blue
        case "electric": return .yellow
        case "ice": return .cyan
        case "fighting": return .red.opacity(0.8)
        case "ground": return .brown
        case "flying": return .indigo.opacity(0.8)
        case "psychic": return .pink
        case "bug": return .green.opacity(0.75)
        case "rock": return .gray
        case "ghost": return .indigo
        case "dark": return .black.opacity(0.8)
        case "dragon": return .indigo.opacity(0.9)
        case "steel": return .gray.opacity(0.7)
        case "fairy": return .pink.opacity(0.75)
        case "normal": return .gray.opacity(0.6)
        default: return .gray.opacity(0.6)
        }
    }
}

// MARK: - Remote Image (simple in-memory cache, no AsyncImage)

final class ImageMemoryCache {
    static let shared = ImageMemoryCache()
    private let cache = NSCache<NSString, UIImage>()
    private init() { cache.countLimit = 300 }

    func image(for key: String) -> UIImage? { cache.object(forKey: key as NSString) }
    func set(_ image: UIImage, for key: String) { cache.setObject(image, forKey: key as NSString) }
}

//struct RemoteImageView: View {
//    let urlString: String
//    let size: CGFloat
//
//    @State private var uiImage: UIImage?
//    @State private var isLoading = false
//
//    var body: some View {
//        Group {
//            if let uiImage {
//                Image(uiImage: uiImage)
//                    .resizable()
//                    .scaledToFit()
//            } else {
//                Image(systemName: "photo")
//                    .resizable()
//                    .scaledToFit()
//                    .foregroundStyle(.white.opacity(0.7))
//                    .padding(12)
//            }
//        }
//        .frame(width: size, height: size)
//        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
//        .task(id: urlString) { await load() }
//    }
//
//    private func load() async {
//        guard !urlString.isEmpty else { return }
//        if let cached = ImageMemoryCache.shared.image(for: urlString) {
//            uiImage = cached
//            return
//        }
//
//        guard !isLoading else { return }
//        guard let url = URL(string: urlString) else { return }
//
//        isLoading = true
//        defer { isLoading = false }
//
//        do {
//            let (data, _) = try await URLSession.shared.data(from: url)
//            guard let image = UIImage(data: data) else { return }
//            ImageMemoryCache.shared.set(image, for: urlString)
//            await MainActor.run { uiImage = image }
//        } catch {
//            // ignore
//        }
//    }
//}

// MARK: - Preview

#Preview {
    PokedexAppView()
}
