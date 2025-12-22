//
//  CollectionFilterCache.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/15/25.
//

import Foundation
import iaAPI
import SwiftUI

/// Codable wrapper for persisting filter data
private struct CachedFilterData: Codable {
    let audioFilters: [SearchFilter]
    let moviesFilters: [SearchFilter]
    let userFilters: [SearchFilter]
    let timestamp: Date
}

/// Cache manager for collection filters
@MainActor
class CollectionFilterCache: ObservableObject {
    static let shared = CollectionFilterCache()
    
    private let service = PlayerArchiveService()
    
    // Cached filters by collection type
    @Published private(set) var audioFilters: [SearchFilter] = []
    @Published private(set) var moviesFilters: [SearchFilter] = []
    @Published private(set) var userFilters: [SearchFilter] = []
    
    // Dictionary for fast lookup by identifier
    private var filtersByIdentifier: [String: SearchFilter] = [:]
    
    // Loading state
    @Published private(set) var isLoading = false
    @Published private(set) var hasLoadedAudio = false
    @Published private(set) var hasLoadedMovies = false
    
    // Error handling
    @Published var errorMessage: String?
    @Published var hasError: Bool = false
    
    // Cache configuration
    private let cacheExpirationInterval: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    private let cacheFileName = "collection-filters-cache.json"
    
    private var cacheFileURL: URL {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cacheDirectory.appendingPathComponent(cacheFileName)
    }
    
    private init() {
        loadFromDisk()
    }
    
    /// Preload both audio and movies filters at app startup
    func preloadFilters() async {
        guard !isLoading else { return }
        
        isLoading = true
        
        // Check if disk cache is still valid
        if isCacheValid() {
            // Cache is still valid, just use what's loaded
            isLoading = false
            return
        }
        
        // Cache expired or doesn't exist, fetch fresh data
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadFilters(for: .audio) }
            group.addTask { await self.loadFilters(for: .movies) }
        }
        
        // Save fresh data to disk
        saveToDisk()
        
        isLoading = false
    }
    
    // MARK: - Disk Persistence
    
    /// Load cached filters from disk
    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: cacheFileURL)
            let cachedData = try JSONDecoder().decode(CachedFilterData.self, from: data)
            
            // Restore filters
            audioFilters = cachedData.audioFilters
            moviesFilters = cachedData.moviesFilters
            userFilters = cachedData.userFilters
            
            // Rebuild lookup dictionary
            filtersByIdentifier = [:]
            for filter in (audioFilters + moviesFilters + userFilters) {
                if !filter.identifier.isEmpty {
                    filtersByIdentifier[filter.identifier] = filter
                }
            }
            
            // Mark as loaded if we have data
            hasLoadedAudio = !audioFilters.isEmpty
            hasLoadedMovies = !moviesFilters.isEmpty
            
            print("Loaded filters from disk cache")
        } catch {
            print("Error loading filters from disk: \(error)")
            // If loading fails, delete corrupted cache
            try? FileManager.default.removeItem(at: cacheFileURL)
        }
    }
    
    /// Save current filters to disk
    private func saveToDisk() {
        let cacheData = CachedFilterData(
            audioFilters: audioFilters,
            moviesFilters: moviesFilters,
            userFilters: userFilters,
            timestamp: Date()
        )
        
        do {
            let data = try JSONEncoder().encode(cacheData)
            try data.write(to: cacheFileURL, options: .atomic)
            print("Saved filters to disk cache")
        } catch {
            print("Error saving filters to disk: \(error)")
        }
    }
    
    /// Check if the disk cache is still valid (not expired)
    private func isCacheValid() -> Bool {
        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else {
            return false
        }
        
        do {
            let data = try Data(contentsOf: cacheFileURL)
            let cachedData = try JSONDecoder().decode(CachedFilterData.self, from: data)
            
            let age = Date().timeIntervalSince(cachedData.timestamp)
            let isValid = age < cacheExpirationInterval
            
            if !isValid {
                print("Cache expired (age: \(Int(age/86400)) days)")
            }
            
            return isValid
        } catch {
            return false
        }
    }
    
    /// Load filters for a specific collection type
    private func loadFilters(for type: ArchiveTopCollectionType) async {
        do {
            let data = try await service.getCollections(from: type)
            
            var filters = data.response.docs.map { doc in
                SearchFilter(
                    name: doc.archiveTitle ?? "title",
                    identifier: doc.identifier ?? "zero",
                    iconUrl: doc.iconUrl
                )
            }
            
            // Add "All" filter at the beginning
            let iconName = type == .movies ? "video" : "hifispeaker"
            let allFilter = SearchFilter(
                name: "All \(type.rawValue.capitalized)",
                identifier: "",
                image: Image(systemName: iconName),
                systemImageName: iconName
            )
            filters.insert(allFilter, at: 0)
            
            // Update cache based on type
            switch type {
            case .audio:
                audioFilters = filters
                hasLoadedAudio = true
            case .movies:
                moviesFilters = filters
                hasLoadedMovies = true
            case .texts:
                break // Not currently supported
            }
            
            // Update lookup dictionary
            for filter in filters {
                if !filter.identifier.isEmpty {
                    filtersByIdentifier[filter.identifier] = filter
                }
            }
            
            // Save to disk after updating
            saveToDisk()
            
            // Clear any previous errors on success
            hasError = false
            errorMessage = nil
            
        } catch let error as ArchiveServiceError {
            // Handle specific Archive service errors
            errorMessage = "Failed to load \(type.rawValue) collections: \(error.description)"
            hasError = true
            print("ArchiveServiceError loading filters for \(type.rawValue): \(error.description)")
            
            // Also show in universal error overlay
            ArchiveErrorManager.shared.showError(error)
            
        } catch {
            // Handle any other errors (except user cancellations)
            let errorDescription = error.localizedDescription.lowercased()
            guard !errorDescription.contains("cancelled") && !errorDescription.contains("canceled") else {
                // User cancelled the operation, don't show error
                return
            }
            
            errorMessage = "An unexpected error occurred loading \(type.rawValue) collections: \(error.localizedDescription)"
            hasError = true
            print("Unexpected error loading filters for \(type.rawValue): \(error)")
            
            // Also show in universal error overlay
            ArchiveErrorManager.shared.showError(error)
        }
    }
    
    /// Get cached filters for a specific type, loading if necessary
    func getFilters(for type: ArchiveTopCollectionType) async -> [SearchFilter] {
        switch type {
        case .audio:
            if !hasLoadedAudio {
                await loadFilters(for: type)
            }
            return audioFilters
        case .movies:
            if !hasLoadedMovies {
                await loadFilters(for: type)
            }
            return moviesFilters
        case .texts:
            return []
        }
    }
    
    /// Look up a filter by its identifier
    func filter(for identifier: String) -> SearchFilter? {
        return filtersByIdentifier[identifier]
    }
    
    /// Refresh filters for a specific type (optional, for manual refresh)
    func refreshFilters(for type: ArchiveTopCollectionType) async {
        await loadFilters(for: type)
    }
    
    /// Add a user-defined filter
    /// - Parameter filter: The filter to add
    /// - Returns: True if successfully added, false if identifier already exists
    @discardableResult
    func addUserFilter(_ filter: SearchFilter) -> Bool {
        // Check if identifier already exists in any filter collection
        guard !filter.identifier.isEmpty else {
            print("Cannot add filter: identifier is empty")
            return false
        }
        
        if filtersByIdentifier[filter.identifier] != nil {
            print("Cannot add filter: identifier '\(filter.identifier)' already exists")
            return false
        }
        
        // Add to user filters array
        userFilters.append(filter)
        
        // Add to lookup dictionary
        filtersByIdentifier[filter.identifier] = filter
        
        // Save to disk
        saveToDisk()
        
        return true
    }
    
    /// Clear all cached data
    func clearCache() {
        audioFilters = []
        moviesFilters = []
        userFilters = []
        filtersByIdentifier = [:]
        hasLoadedAudio = false
        hasLoadedMovies = false
        
        // Remove disk cache
        try? FileManager.default.removeItem(at: cacheFileURL)
    }
}
