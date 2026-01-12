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

struct PokemonDetailResponse: Decodable, Hashable, Equatable {
    let height: Double
    let weight: Double
}


//struct PokemonListItem: Decodable, Hashable, Identifiable, Equatable {
//    let name: String
//    let url: String
//    var id: String { url }
//}

