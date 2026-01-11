//
//  CoinMarket.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import Foundation

struct CoinDetail: Identifiable, Codable, Hashable {
    let id: String
    let symbol: String
    let name: String
    let description: [String: String]
}
