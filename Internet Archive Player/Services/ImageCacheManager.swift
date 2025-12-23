//
//  ImageCacheManager.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/23/24.
//

import UIKit

/// Image cache manager for Internet Archive images
/// Provides a centralized, thread-safe way to load and cache images across the app
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
    
    /// Load an image from cache or network
    /// - Parameter url: The URL of the image to load
    /// - Returns: A UIImage if successful, nil otherwise
    /// - Throws: Network or decoding errors
    nonisolated func loadImage(from url: URL) async throws -> UIImage {
        let cache = URLCache.shared
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
        
        // Check cache first
        if let cachedResponse = cache.cachedResponse(for: request),
           let cachedImage = UIImage(data: cachedResponse.data) {
            return cachedImage
        }
        
        // Load from network
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Cache the response
        let cachedData = CachedURLResponse(response: response, data: data)
        cache.storeCachedResponse(cachedData, for: request)
        
        // Decode image
        guard let image = UIImage(data: data) else {
            throw ImageCacheError.invalidImageData
        }
        
        return image
    }
    
    /// Load an image with a completion handler (for compatibility with non-async code)
    /// - Parameters:
    ///   - url: The URL of the image to load
    ///   - completion: Called with the result on the main thread
    /// - Returns: A task that can be cancelled
    @discardableResult
    nonisolated func loadImage(
        from url: URL,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) -> Task<Void, Never> {
        Task {
            do {
                let image = try await loadImage(from: url)
                await MainActor.run {
                    completion(.success(image))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
}

/// Errors that can occur during image loading and caching
enum ImageCacheError: LocalizedError {
    case invalidImageData
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Failed to decode image data"
        case .invalidURL:
            return "Invalid image URL"
        }
    }
}
