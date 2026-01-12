//
//  PokemonDetailView.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/12/26.
//

import SwiftUI

// MARK: - Detail View
struct PokemonDetailView: View {
    let item: PokemonListItem
    @State private var vm: PokemonDetailVM

    init(item: PokemonListItem, service: PokemonServicing = PokemonAPI()) {
        self.item = item
        _vm = State(wrappedValue: PokemonDetailVM(service: service))
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(item.name.capitalized)
                .font(.title.bold())

            detailBody

            Spacer()
        }
        .padding()
        .navigationTitle(item.name.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load(item: item) }
    }

    @ViewBuilder
    private var detailBody: some View {
        switch vm.state {
        case .idle, .loading:
            ProgressView("Loading details…")

        case .failure(let message):
            Text(message).foregroundStyle(.red)

        case .success(let d):
            Text("Weight: \(d.weight, specifier: "%.0f")")
            Text("Height: \(d.height, specifier: "%.0f")")
        }
    }
}

//#Preview {
//    PokemonDetailView()
//}
