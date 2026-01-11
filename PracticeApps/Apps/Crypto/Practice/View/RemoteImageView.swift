//
//  RemoteImageView.swift
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
            } else {
                Image(systemName: "globe.fill")
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .task(id: urlString) {
            await load()
        }
    }
    
    func load() async {
        guard !isLoading else { return }
        guard let url = URL(string: urlString) else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return }
            await MainActor.run {
                self.uiImage = image
            }
        } catch {
            // placeholder for failure
        }
    }
}
