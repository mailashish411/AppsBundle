//
//  PokemonListVM.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/12/26.
//

import Foundation

// MARK: - ViewModels
@Observable
final class PokemonListVM {
    let service: PokemonServicing

    // State the view renders from
    private(set) var state: LoadState<[PokemonListItem]> = .idle

    // Paging
    private var nextURL: URL?
    var isLoadingMore = false

    init(service: PokemonServicing = PokemonAPI()) {
        self.service = service
    }

    @MainActor
    func loadInitial() async {
        // If we already loaded, don't reload
        if case .success = state { return }

        state = .loading
        do {
            let res = try await service.list(url: nil)
            nextURL = res.next.flatMap(URL.init(string:))
            state = .success(res.results)
        } catch {
            state = .failure("Failed to load list.")
        }
    }

    func loadMoreIfNeeded(current: PokemonListItem) async {
        guard case .success(let items) = state else { return }
        guard let idx = items.firstIndex(of: current) else { return }

        let triggerIndex = max(items.count - 5, 0)
        guard idx >= triggerIndex else { return }

        guard !isLoadingMore else { return }
        guard let url = nextURL else { return }

        await MainActor.run { isLoadingMore = true }
        defer { Task { @MainActor in isLoadingMore = false } }

        do {
            let res = try await service.list(url: url)
            let newNext = res.next.flatMap(URL.init(string:))
            let newItems = res.results.filter { !items.contains($0) }

            await MainActor.run {
                nextURL = newNext
                state = .success(items + newItems)
            }
        } catch {
            // For paging failure, you could keep existing content and show a toast.
            // Keeping it simple: expose as error state only if you want.
            await MainActor.run {
                // keep existing items and just ignore error (or store another pagingError string)
            }
        }
    }
}
