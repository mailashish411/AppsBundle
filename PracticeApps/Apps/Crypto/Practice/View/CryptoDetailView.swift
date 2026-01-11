//
//  File.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//
import SwiftUI

struct CryptoDetailView: View {
    let crypto: Crypto
    @State private var viewModel: CryptoDetailViewModel
    init(crypto: Crypto) {
        self.crypto = crypto
        self._viewModel = State(wrappedValue: CryptoDetailViewModel(crypto: crypto))
    }
    var body: some View {
        VStack (alignment: .leading){
            RemoteImageView(urlString: crypto.image, size: 100)
            Text(crypto.name)
            Text("\(crypto.currentPrice)")
            
            if let description = viewModel.crytoDetail?.description.text {
                Text(description)
            } else {
                ProgressView()
            }
        }
        .padding()
        .task {
            await viewModel.fetchDetail(for: crypto)
        }
        
    }
}

@Observable
class CryptoDetailViewModel {
    let crypto: Crypto
    var crytoDetail: CryptoDetail?
    init(crypto: Crypto) {
        self.crypto = crypto
    }
    
    @MainActor
    func fetchDetail(for crypto: Crypto) async {
        guard let detailUrl = URL(string: "https://api.coingecko.com/api/v3/coins/\(crypto.id)?localization=false") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: detailUrl)
            let result = try JSONDecoder().decode(CryptoDetail.self, from: data)
            self.crytoDetail = result
        } catch {
            // placeholder for error
        }
    }
}

struct CryptoDetail: Codable, Identifiable, Hashable {
    let id: String
    let symbol: String
    let description: Description
}

struct Description: Codable, Identifiable, Hashable {
    let text: String
    let id = UUID().uuidString
    
    enum CodingKeys: String, CodingKey {
        case text = "en"
    }
}
