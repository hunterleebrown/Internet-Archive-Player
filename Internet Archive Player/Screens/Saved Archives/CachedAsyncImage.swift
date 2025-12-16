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
        
        // Check if image is in cache first
        let cache = URLCache.shared
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
        
        if let cachedResponse = cache.cachedResponse(for: request),
           let cachedImage = UIImage(data: cachedResponse.data) {
            self.image = cachedImage
            self.isLoading = false
            return
        }
        
        // Load from network
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Cache the response
                let cachedData = CachedURLResponse(response: response, data: data)
                cache.storeCachedResponse(cachedData, for: request)
                
                if let loadedImage = UIImage(data: data) {
                    await MainActor.run {
                        self.image = loadedImage
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                    }
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

/// Image cache manager for Internet Archive images
actor ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private init() {
        configureCache()
    }
    
    nonisolated func configureCache() {
        // Configure URLCache with larger memory and disk capacity
        // 50MB memory cache, 200MB disk cache
        let cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: "ia_image_cache"
        )
        URLCache.shared = cache
    }
    
    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
    }
    
    func cacheSize() -> Int {
        return URLCache.shared.currentDiskUsage
    }
}
