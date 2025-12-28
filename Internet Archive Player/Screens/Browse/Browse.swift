//
//  Browse.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/21/25.
//

import SwiftUI
import iaAPI

struct Browse: View {
    @StateObject private var viewModel: ViewModel = ViewModel()
    @State private var selectedFilter: SearchFilter?

    var body: some View {
        NavigationStack {

            VStack {
                // List of collections
                List {
                    // Collection-based filters section
                    Section {
                        ForEach(viewModel.audioFilters) { filter in
                            NavigationLink(value: filter) {
                                filterRow(for: filter)
                            }
                        }
                    } header: {
                        if !viewModel.audioFilters.isEmpty {
                            Text("Audio")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.fairyRed)
                                .textCase(nil)
                                .padding(.top, 8)
                        }
                    }

                    // movies filters section
                    if !viewModel.moviesFilters.isEmpty {
                        Section {
                            ForEach(viewModel.moviesFilters) { filter in
                                NavigationLink(value: filter) {
                                    filterRow(for: filter)
                                }
                            }
                        } header: {
                            Text("Movies")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.fairyRed)
                                .textCase(nil)
                                .padding(.top, 8)
                        }
                    }

                    // User filters section
                    if !viewModel.userFilters.isEmpty {
                        Section {
                            ForEach(viewModel.userFilters) { filter in
                                NavigationLink(value: filter) {
                                    filterRow(for: filter)
                                }
                            }
                        } header: {
                            Text("User")
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
            .navigationDestination(for: SearchFilter.self) { filter in
                BrowseResultsView(filter: filter)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Browse")
        .task {
            viewModel.fetchInitialCollections()
        }
    }
}

// MARK: - Browse Results View
struct BrowseResultsView: View {
    let filter: SearchFilter
    @StateObject private var viewModel = BrowseResultsViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isSearching && viewModel.items.isEmpty {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.items.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No items found for \(filter.name)")
                )
            } else {
                searchResultsList
            }
        }
        .navigationTitle(filter.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Perform search when view appears
            await performSearch()
        }
    }
    
    private var searchResultsList: some View {
        List {
            ForEach(viewModel.items, id: \.self) { doc in
                Group {
                    if doc.mediatype == .collection {
                        // Navigate to another BrowseResultsView for collections
                        NavigationLink(value: createFilterFromDoc(doc)) {
                            BrowseResultRow(
                                doc: doc,
                                isLastItem: doc == viewModel.items.last,
                                onAppear: {
                                    // Load more when reaching the last item
                                    if doc == viewModel.items.last {
                                        Task {
                                            await loadMore()
                                        }
                                    }
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle()) // Prevents button styling interference
                    } else {
                        // Navigate to Detail view for non-collections
                        NavigationLink(value: doc.identifier ?? "") {
                            BrowseResultRow(
                                doc: doc,
                                isLastItem: doc == viewModel.items.last,
                                onAppear: {
                                    // Load more when reaching the last item
                                    if doc == viewModel.items.last {
                                        Task {
                                            await loadMore()
                                        }
                                    }
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle()) // Prevents button styling interference
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .navigationDestination(for: SearchFilter.self) { filter in
            // Nested navigation for sub-collections
            BrowseResultsView(filter: filter)
        }
        .navigationDestination(for: String.self) { identifier in
            // Navigate to Detail view
            Detail(identifier)
        }
    }
    
    /// Helper function to create a SearchFilter from an ArchiveMetaData doc
    private func createFilterFromDoc(_ doc: ArchiveMetaData) -> SearchFilter {
        return SearchFilter(
            name: doc.archiveTitle ?? "Collection",
            identifier: doc.identifier ?? "",
            iconUrl: doc.iconUrl
        )
    }
    
    func handleItemTap(_ doc: ArchiveMetaData) {
        // Handle item tap - you can navigate to detail view here
    }
    
    private func performSearch() async {
        // Use the filter identifier as the collection parameter
        viewModel.search(query: filter.identifier, collection: filter.identifier, loadMore: false)
    }
    
    private func loadMore() async {
        viewModel.search(query: filter.identifier, collection: filter.identifier, loadMore: true)
    }
}

extension Browse {

    func handleItemTap(_ doc: ArchiveMetaData) {

    }

    @ViewBuilder
    private func filterRow(for filter: SearchFilter) -> some View {
        HStack(spacing: 10) {
            // Collection icon
            filterIcon(for: filter)
                .frame(width: 40, height: 40)

            // Collection name and identifier
            VStack(alignment: .leading, spacing: 2) {
                Text(filter.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                if !filter.identifier.isEmpty {
                    Text(filter.identifier)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.clear, lineWidth: 2)
        )
        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    /// Extracts the icon logic into a separate view builder
    @ViewBuilder
    private func filterIcon(for filter: SearchFilter) -> some View {
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
                CachedAsyncImage(
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
    }

    /// Checks if a filter is currently selected
//    private func isSelected(_ filter: SearchFilter) -> Bool {
//        selectedFilter.identifier == filter.identifier
//    }

}

extension Browse {
    final class ViewModel: ObservableObject {

        @Published var isSearching: Bool = false
        @Published var items: [ArchiveMetaData] = []
        @Published var searchText: String = ""

        @Published var audioFilters: [SearchFilter] = []
        @Published var moviesFilters: [SearchFilter] = []
        @Published var userFilters: [SearchFilter] = []

        let service: PlayerArchiveService
        private var isLoadingMore: Bool = false
        var searchStarted: Bool = false

        init() {
            self.service = PlayerArchiveService()
        }

        @MainActor
        func fetchInitialCollections() {
            audioFilters = CollectionFilterCache.shared.audioFilters
            moviesFilters = CollectionFilterCache.shared.moviesFilters
            userFilters = CollectionFilterCache.shared.userFilters
        }

        @MainActor
        func search(query: String, collection:String? = nil, loadMore: Bool) {

            guard !searchStarted  else { return }
            self.isSearching = true
            self.isLoadingMore = loadMore
            self.searchStarted = true

            Task { @MainActor in
                do {

                    if !self.isLoadingMore {
                        self.items.removeAll()
                    }

                    let format: ArchiveFileFormat? = nil //self.mediaTypes[self.mediaType] == .movies ? nil : .mp3
//                    let searchMediaType: ArchiveMediaType = self.mediaTypes[self.mediaType]
//                    print(query)
                    let data = try await self.service.searchPPSAsync(query: query, mediaTypes: [.audio, .movies, .collection], format: format, collection: collection)

//                    self.numberOfResults = data.response.numFound
//                    self.totalPages = Int(ceil(Double(self.numberOfResults) / Double(self.rows)))

//                    self.page += 1

//                    print("The Page Number is: \(self.page)")

                    // Sort results to put collections at the top
                    let sortedDocs = data.response.docs.sorted { lhs, rhs in
                        let lhsIsCollection = lhs.mediatype == .collection
                        let rhsIsCollection = rhs.mediatype == .collection

                        // Collections come first
                        if lhsIsCollection && !rhsIsCollection {
                            return true
                        } else if !lhsIsCollection && rhsIsCollection {
                            return false
                        }
                        // Keep original order for same type
                        return false
                    }

                    // Filter out any docs where collection contains "tvarchive"
                    let noTV = sortedDocs.filter { doc in
                        // Exclude docs that have "tvarchive" in their collections
                        return !doc.collection.contains { $0.lowercased() == "tvarchive" }
                    }

                    if !isLoadingMore {
                        self.items = noTV
                    } else {
                        self.items += noTV
                    }

                    self.isSearching = false
                    self.searchStarted = false

                    if self.items.count == 0 {
                        throw ArchiveServiceError.nodata
                    }

                } catch let error as ArchiveServiceError {
//                    withAnimation(.easeIn(duration: 0.33)) {
//                        self.archiveError = error.description
//                        self.noDataFound = true
//                        self.isSearching = false
//                        self.searchStarted = false
//                    }

                    // Also show in universal error overlay
                    Task { @MainActor in
                        ArchiveErrorManager.shared.showError(error)
                    }

                } catch {
                    // Catch any other errors (except user cancellations)
                    let errorDescription = error.localizedDescription.lowercased()
                    guard !errorDescription.contains("cancelled") && !errorDescription.contains("canceled") else {
                        // User cancelled the operation, don't show error
                        return
                    }

//                    withAnimation(.easeIn(duration: 0.33)) {
//                        self.archiveError = "An unexpected error occurred: \(error.localizedDescription)"
//                        self.noDataFound = true
//                        self.isSearching = false
//                        self.searchStarted = false
//                    }

                    // Also show in universal error overlay
                    Task { @MainActor in
                        ArchiveErrorManager.shared.showError(error)
                    }
                }
            }
        }

    }
}
// MARK: - Browse Results ViewModel
@MainActor
class BrowseResultsViewModel: ObservableObject {
    @Published var isSearching: Bool = false
    @Published var items: [ArchiveMetaData] = []
    
    let service: PlayerArchiveService
    private var isLoadingMore: Bool = false
    private var searchTask: Task<Void, Never>?
    
    init() {
        self.service = PlayerArchiveService()
    }
    
    func search(query: String, collection: String? = nil, loadMore: Bool) {
        // Cancel any existing search
        searchTask?.cancel()
        
        self.isSearching = true
        self.isLoadingMore = loadMore
        
        searchTask = Task { @MainActor in
            do {
                if !self.isLoadingMore {
                    self.items.removeAll()
                }
                
                let data = try await self.service.searchPPSAsync(
                    query: query,
                    mediaTypes: [.audio, .movies, .collection],
                    format: nil,
                    collection: collection
                )
                
                // Sort results to put collections at the top
                let sortedDocs = data.response.docs.sorted { lhs, rhs in
                    let lhsIsCollection = lhs.mediatype == .collection
                    let rhsIsCollection = rhs.mediatype == .collection
                    
                    if lhsIsCollection && !rhsIsCollection {
                        return true
                    } else if !lhsIsCollection && rhsIsCollection {
                        return false
                    }
                    return false
                }
                
                // Filter out TV archive
                let noTV = sortedDocs.filter { doc in
                    return !doc.collection.contains { $0.lowercased() == "tvarchive" }
                }
                
                if !isLoadingMore {
                    self.items = noTV
                } else {
                    self.items += noTV
                }
                
                self.isSearching = false
                
                if self.items.count == 0 {
                    throw ArchiveServiceError.nodata
                }
                
            } catch let error as ArchiveServiceError {
                self.isSearching = false
                ArchiveErrorManager.shared.showError(error)
            } catch {
                let errorDescription = error.localizedDescription.lowercased()
                guard !errorDescription.contains("cancelled") && !errorDescription.contains("canceled") else {
                    return
                }
                self.isSearching = false
                ArchiveErrorManager.shared.showError(error)
            }
        }
    }
}

struct BrowseResultRow: View {
    let doc: ArchiveMetaData
    let isLastItem: Bool
    let onAppear: () -> Void

    var body: some View {
        SearchItemView(item: doc)
                .padding(.horizontal, 10)
        .listRowInsets(EdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5))
        .listRowBackground(Color.clear)
        .onAppear(perform: onAppear)
    }
}
