//
//  CachedAsyncImage.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/16/24.
//

import SwiftUI

/// A custom image loader that caches images using URLCache
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard let url = url, !isLoading else { return }
        
        isLoading = true
        
        // Use the shared ImageCacheManager
        Task {
            do {
                let loadedImage = try await ImageCacheManager.shared.loadImage(from: url)
                await MainActor.run {
                    self.image = loadedImage
                    self.isLoading = false
                }
            } catch {
                print("Error loading image from \(url): \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

// Convenience initializer to match AsyncImage API
extension CachedAsyncImage where Content == Image, Placeholder == Color {
    init(url: URL?) {
        self.url = url
        self.content = { image in image }
        self.placeholder = { Color(.systemGray5) }
    }
}

