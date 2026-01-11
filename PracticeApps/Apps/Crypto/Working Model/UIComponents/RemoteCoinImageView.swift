//
//  CoinMarket.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import SwiftUI

struct RemoteImageView: View {
    let urlString: String
    let size: CGFloat

    @State private var uiImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity)
            } else {
                Image(systemName: "bitcoinsign.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .opacity(0.35)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .task(id: urlString) {
            await load()
        }
    }

    private func load() async {
        guard !isLoading else { return }
        guard let url = URL(string: urlString) else { return }

        if let cached = ImageCache.shared.get(urlString) {
            uiImage = cached
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let img = UIImage(data: data) else { return }
            ImageCache.shared.set(img, for: urlString)
            await MainActor.run { self.uiImage = img }
        } catch { }
    }
}
