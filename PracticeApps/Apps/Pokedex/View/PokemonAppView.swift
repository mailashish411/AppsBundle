//
//  PokemonAppView.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/12/26.
//
import SwiftUI
import SharedKit

// MARK: - App View
struct PokemonAppView: View {
    @State private var vm = PokemonListVM()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Pokédex")
                .task { await vm.loadInitial() }
                .navigationDestination(for: PokemonListItem.self) { item in
                    PokemonDetailView(item: item, service: vm.service)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.state {
        case .idle, .loading:
            ProgressView("Loading…")

        case .failure(let message):
            ContentUnavailableView(
                "Error",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )

        case .success(let items):
            List {
                ForEach(items) { item in
                    NavigationLink(value: item) {
                        Text(item.name.capitalized)
                            .onAppear {
                                Task { await vm.loadMoreIfNeeded(current: item) }
                            }
                    }
                }

                if vm.isLoadingMore {
                    HStack { Spacer(); ProgressView(); Spacer() }
                }
            }
            .listStyle(.plain)
        }
    }
}

#Preview {
    PokemonAppView()
}
