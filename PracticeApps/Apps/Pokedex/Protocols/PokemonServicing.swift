//
//  PokemonServicing.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/12/26.
//

import Foundation

protocol PokemonServicing: Sendable {
    func list(url: URL?) async throws -> PokemonResponse
    func detail(url: URL) async throws -> PokemonDetailResponse
}

