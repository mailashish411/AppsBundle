//
//  CrytpoListView.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import SwiftUI
import Foundation

struct CryptoListView: View {
    @State private var viewModel = CryptoListViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.cryptos) { crypto in
                    NavigationLink(value: crypto) {
                        HStack(spacing: 30) {
                            RemoteImageView(urlString: crypto.image, size: 34)

                            VStack(alignment: .leading) {
                                Text(crypto.name.capitalized)
                                    .font(.body)
                                    .fontWeight(.bold)

                                Text(crypto.symbol.uppercased())
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            Text("$\(crypto.currentPrice, specifier: "%.2f")")
                                .foregroundColor(crypto.hasIncreasedPrice ? .green : .red)
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle("Cryptos")
            .navigationDestination(for: Crypto.self) { crypto in
                VStack {
                    RemoteImageView(urlString: crypto.image, size: 100)
                    Text(crypto.name)
                    Text("\(crypto.currentPrice)")
                }
                .navigationTitle(crypto.name)
            }
        }
    }
}

#Preview {
    CryptoListView()
}
