//
//  CryptoListViewModel.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import Foundation

@Observable
class CryptoListViewModel {
    var cryptos: [Crypto] = []
    var errorMessage: String?
    
    init() {
        Task {
            await fetchAllCoins()
        }
    }
    
    func fetchAllCoins() async {
//        try? await Task.sleep(nanoseconds: 2_000_000_000)
//        self.cryptos = Crypto.mocks
//        return
        let allCoinsUrl = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=20&page=1&sparkline=false&locale=en"
        guard let url = URL(string: allCoinsUrl) else {
            self.errorMessage = "Invalid URL"
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let result = try decoder.decode([Crypto].self, from: data)
            self.cryptos = result
        } catch {
            print("Decoding error:", error)
            dump(error)
        }
        
    }
}
