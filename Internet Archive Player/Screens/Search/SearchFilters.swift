//
//  SearchFilters.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 9/9/23.
//

import Foundation
import iaAPI
import SwiftUI
import UIKit

struct SearchFilter: Identifiable, Hashable, Codable {
    var name: String
    var identifier: String
    var iconUrl: URL?
    var uiImage: UIImage?
    var image: Image?
    var systemImageName: String? // Store the system image name for encoding
    
    // Use identifier as the unique id for Identifiable conformance
    var id: String { identifier }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    static func == (lhs: SearchFilter, rhs: SearchFilter) -> Bool {
        lhs.identifier == rhs.identifier
    }
    
    // MARK: - Codable conformance
    
    enum CodingKeys: String, CodingKey {
        case name
        case identifier
        case iconUrl
        case uiImageData
        case systemImageName
    }
    
    init(name: String, identifier: String, iconUrl: URL? = nil, uiImage: UIImage? = nil, image: Image? = nil, systemImageName: String? = nil) {
        self.name = name
        self.identifier = identifier
        self.iconUrl = iconUrl
        self.uiImage = uiImage
        self.image = image
        self.systemImageName = systemImageName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        identifier = try container.decode(String.self, forKey: .identifier)
        iconUrl = try container.decodeIfPresent(URL.self, forKey: .iconUrl)
        systemImageName = try container.decodeIfPresent(String.self, forKey: .systemImageName)
        
        // Decode UIImage from Data if present
        if let imageData = try container.decodeIfPresent(Data.self, forKey: .uiImageData) {
            uiImage = UIImage(data: imageData)
        } else {
            uiImage = nil
        }
        
        // Reconstruct Image from system image name if present
        if let systemName = systemImageName {
            image = Image(systemName: systemName)
        } else {
            image = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(identifier, forKey: .identifier)
        try container.encodeIfPresent(iconUrl, forKey: .iconUrl)
        try container.encodeIfPresent(systemImageName, forKey: .systemImageName)
        
        // Encode UIImage as PNG Data if present
        if let uiImage = uiImage, let imageData = uiImage.pngData() {
            try container.encode(imageData, forKey: .uiImageData)
        }
    }
}


struct SearchFilters: View {

    @State private var searchFilter: SearchFilter?
    @StateObject var searchFiltersViewModel: SearchFiltersViewModel
    @Environment(\.dismiss) private var dismiss
    var delegate: SearchView?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Filter by Collection")
                    .font(.title2)
                    .foregroundColor(.fairyRed)
                    .bold()
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            // Collection type indicator
            HStack(spacing: 6) {
                Image(systemName: searchFiltersViewModel.collectionType == .movies ? "video" : "hifispeaker")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(searchFiltersViewModel.collectionType.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            Divider()
            
            // List of collections
            List {
                // Collection-based filters section
                Section {
                    ForEach(searchFiltersViewModel.items) { filter in
                        filterRow(for: filter)
                            .onTapGesture {
                                searchFilter = filter
                            }
                    }
                } header: {
                    if !searchFiltersViewModel.userFilters.isEmpty {
                        Text("Top Collections")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.fairyRed)
                            .textCase(nil)
                            .padding(.top, 8)
                    }
                }
                
                // User filters section
                if !searchFiltersViewModel.userFilters.isEmpty {
                    Section {
                        ForEach(searchFiltersViewModel.userFilters) { filter in
                            filterRow(for: filter)
                                .onTapGesture {
                                    searchFilter = filter
                                }
                        }
                    } header: {
                        Text("My Used Filters")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.fairyRed)
                            .textCase(nil)
                            .padding(.top, 8)
                    }
                }
            }
            .listStyle(.plain)
        }
        .presentationDragIndicator(.visible)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .onChange(of: searchFilter) { oldValue, newValue in
            if let val = newValue {
                searchFiltersViewModel.collectionSelection = val
                if let del = delegate {
                    del.searchFilter = val
                    del.collectionName = val.name
                    del.collectionIdentifier = val.identifier
                    del.showCollections = false
                    del.viewModel.search(query: del.viewModel.searchText, collection: searchFiltersViewModel.collectionSelection.identifier.isEmpty ? nil : searchFiltersViewModel.collectionSelection.identifier, loadMore: false)
                }
            }
        }
        .onAppear() {
            searchFiltersViewModel.search()
        }
    }
    
    // MARK: - Helper Views
    
    /// Reusable filter row view
    @ViewBuilder
    private func filterRow(for filter: SearchFilter) -> some View {
        HStack(spacing: 10) {
            // Collection icon
            Group {
                if let image = filter.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                } else if let uiImage = filter.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                } else if filter.iconUrl != nil {
                    AsyncImage(
                        url: filter.iconUrl,
                        content: { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .background(Color.black)
                        },
                        placeholder: {
                            Color(.systemGray5)
                                .frame(width: 40, height: 40)
                        })
                    .cornerRadius(5)
                }
            }
            .frame(width: 40, height: 40)
            
            // Collection name and identifier
            VStack(alignment: .leading, spacing: 2) {
                Text(filter.name)
                    .font(.subheadline)
                    .foregroundColor(isSelected(filter) ? .white : .primary)
                    .lineLimit(2)
                
                if !filter.identifier.isEmpty {
                    Text(filter.identifier)
                        .font(.caption2)
                        .foregroundColor(isSelected(filter) ? .white.opacity(0.8) : .secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Checkmark for selected
            if isSelected(filter) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.callout)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected(filter) ? Color.fairyRed : Color(UIColor.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected(filter) ? Color.fairyRed.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    private func isSelected(_ filter: SearchFilter) -> Bool {
        delegate?.collectionName == filter.name
    }
}

struct SearchFilters_Previews: PreviewProvider {
    static var previews: some View {
        SearchFilters(searchFiltersViewModel: SearchFiltersViewModel(collectionType: .audio))
    }
}

@MainActor
class SearchFiltersViewModel: ObservableObject {
    @Published var collectionSelection: SearchFilter = SearchFilter(name: "All", identifier: "")

    let collectionType : ArchiveTopCollectionType
    @Published var items: [SearchFilter] = []
    @Published var userFilters: [SearchFilter] = []
    
    private let cache = CollectionFilterCache.shared

    init(collectionType: ArchiveTopCollectionType) {
        self.collectionType = collectionType
    }

    func search() {
        Task {
            // Use cached data instead of making a new network request
            self.items = await cache.getFilters(for: self.collectionType)
            
            // Load user filters (these appear on both audio and video screens)
            self.userFilters = cache.userFilters
            
            if self.items.isEmpty {
                print("No filters available for \(self.collectionType.rawValue)")
            }
        }
    }
    
    /// Look up a filter by identifier from the cache
    func filter(for identifier: String) -> SearchFilter? {
        return cache.filter(for: identifier)
    }
}
