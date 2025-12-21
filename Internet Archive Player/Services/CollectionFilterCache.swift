//
//  CollectionFilterCache.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/15/25.
//

import Foundation
import iaAPI
import SwiftUI

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
    
    private init() {}
    
    /// Preload both audio and movies filters at app startup
    func preloadFilters() async {
        guard !isLoading else { return }
        
        isLoading = true
        
        // Load both concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadFilters(for: .audio) }
            group.addTask { await self.loadFilters(for: .movies) }
        }
        
        isLoading = false
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
                image: Image(systemName: iconName)
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
            
        } catch {
            print("Error loading filters for \(type.rawValue): \(error)")
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
    }
}
