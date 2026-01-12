//
//  APIModel.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/12/26.
//
import Foundation

struct PokemonResponse: Decodable {
    let next: String?
    let results: [PokemonListItem]
}

struct PokemonListItem: Decodable, Hashable, Identifiable, Equatable {
    let name: String
    let url: String
    var id: String { url }
}

struct PokemonDetailResponse: Decodable, Hashable, Equatable {
    let height: Double
    let weight: Double
}

enum LoadState<Value>: Equatable where Value: Equatable {
    case idle
    case loading
    case success(Value)
    case failure(String)
}
