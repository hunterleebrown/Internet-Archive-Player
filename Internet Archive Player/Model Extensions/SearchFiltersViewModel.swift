//
//  SearchFiltersViewModel.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/20/25.
//

import Foundation
import iaAPI
import SwiftUI

@MainActor
class SearchFiltersViewModel: ObservableObject {
    @Published var collectionSelection: SearchFilter = SearchFilter(name: "All", identifier: "")

    let collectionType: ArchiveTopCollectionType
    @Published var items: [SearchFilter] = []
    @Published var userFilters: [SearchFilter] = []
    
    private let cache = CollectionFilterCache.shared

    init(collectionType: ArchiveTopCollectionType) {
        self.collectionType = collectionType
    }

    func search() async {
        // Use cached data instead of making a new network request
        self.items = await cache.getFilters(for: self.collectionType)
        
        // Load user filters (these appear on both audio and video screens)
        self.userFilters = cache.userFilters
        
        if self.items.isEmpty {
            print("No filters available for \(self.collectionType.rawValue)")
        }
    }
    
    /// Look up a filter by identifier from the cache
    func filter(for identifier: String) -> SearchFilter? {
        return cache.filter(for: identifier)
    }
}
