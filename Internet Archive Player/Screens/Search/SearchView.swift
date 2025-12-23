//
//  SwiftUIView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI
import iaAPI
import Combine

struct SearchView: View {
    @EnvironmentObject var iaPlayer: Player
    @StateObject var viewModel = SearchView.ViewModel()
    @FocusState private var searchFocused: Bool
    @State private var collection: String = ""
    @State var showCollections: Bool = false

    @State var collectionName: String = "All"
    @State var collectionIdentifier: String?

    @State var searchFilter: SearchFilter = SearchFilter(name: "All", identifier: "")
    
    // Navigation state
    @State private var selectedItemIdentifier: String?

    init() {
        searchFocused = false
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Divider()

            searchResultsList
        }
        .navigationBarColor(backgroundColor: Color("playerBackground").opacity(0.5), titleColor: .fairyRed)
        .sheet(isPresented: $showCollections) {
            collectionsSheet
        }
        .avoidPlayer()
        .navigationTitle("Search")
        .tint(.fairyRed)
        .navigationDestination(item: $selectedItemIdentifier) { identifier in
            Detail(identifier)
        }
        .onReceive(Home.searchPassInternal, perform: { collection in
            setSearchFilter(collection)
        })
    }

    // MARK: - View Components
    
    private var headerView: some View {
        VStack(spacing: 0) {
            mediaTypePicker
            collectionFilterRow
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private var mediaTypePicker: some View {
        Picker("What media type?", selection: $viewModel.mediaType) {
            Label("Audio", systemImage: "hifispeaker")
                .tag(0)
            Label("Video", systemImage: "video")
                .tag(1)
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
        .padding(.horizontal, 20)
//        .padding(.vertical, 8) // Add vertical padding for better tap targets
        .onChange(of: viewModel.mediaType) {
            // Reset filter to "All" when switching media types
            searchFilter = SearchFilter(name: "All", identifier: "")
            collectionName = "All"
            collectionIdentifier = nil
            
            viewModel.search(query: viewModel.searchText, collection: nil, loadMore: false)
        }
    }
    
    private var collectionFilterRow: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                filterButton
                collectionDisplayCard
            }
            
            // Long press hint
            HStack(spacing: 4) {
                Image(systemName: "hand.tap")
                    .font(.caption2)
                Text("Tip: Long press items for more options")
                    .font(.caption2)
                Spacer()

                if viewModel.isSearching {
                    ProgressView()
                        .frame(width: 24, height: 24)
                }
            }
            .frame(height: 24)
            .foregroundColor(.secondary)
            .opacity(0.7)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
    
    private var filterButton: some View {
        Button {
            showCollections = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.body)
                Text("Filter")
                    .font(.subheadline)
                    .bold()
            }
            .foregroundColor(.fairyRed)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.fairyRed, lineWidth: 1)
            )
        }
    }
    
    private var collectionDisplayCard: some View {
        HStack(spacing: 8) {
            if let imageUrl = searchFilter.iconUrl {
                AsyncImage(
                    url: imageUrl,
                    content: { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .background(Color.black)
                    },
                    placeholder: {
                        Color(.black)
                            .frame(width: 24, height: 24)
                    })
                .cornerRadius(4)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Collection")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(searchFilter.name)
                    .font(.caption)
                    .bold()
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.systemGray6))
        )
    }
    
    private var searchResultsList: some View {
        List {
            ForEach(viewModel.items, id: \.self) { doc in
                SearchResultRow(
                    doc: doc,
                    isLastItem: doc == viewModel.items.last,
                    onTap: { handleItemTap(doc) },
                    onAppear: {
                        if doc == viewModel.items.last {
                            viewModel.search(query: viewModel.searchText, collection: collectionIdentifier, loadMore: true)
                        }
                    }
                )
                .contextMenu {

                    if let meta = viewModel.firstCollection(doc) {
                        Button {
                            setSearchFilter(meta)
                        } label: {
                            Label("Filter by Collection \(meta.archiveTitle ?? "Unknown")", systemImage: "line.3.horizontal.decrease.circle")
                        }

                    }

                    Button {
                        try? iaPlayer.addFavoriteArchive(doc)
                    } label: {
                        Label("Add to Bookmarks", systemImage: "bookmark")
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search The Internet Archive")
        .onSubmit(of: .search, {
            viewModel.search(query: viewModel.searchText, collection: collectionIdentifier, loadMore: false)
        })
        .zIndex(viewModel.noDataFound ? 2 : 1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var collectionsSheet: some View {
        let type = self.viewModel.mediaTypes[self.viewModel.mediaType]
        if let topCollectionType = ArchiveTopCollectionType(rawValue: type.rawValue) {
            let filterViewModel = SearchFiltersViewModel(collectionType: topCollectionType)
            SearchFilters(searchFiltersViewModel: filterViewModel, delegate: self)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Handles when any item is tapped
    private func handleItemTap(_ item: ArchiveMetaData) {
        if item.mediatype == .collection {
            // If it's a collection, set it as filter and search
            setSearchFilter(item)
        } else {
            // If it's a regular item, navigate to detail
            selectedItemIdentifier = item.identifier
        }
    }
    
    /// Sets the search filter based on a collection and triggers a search
    private func setSearchFilter(_ collection: ArchiveMetaData) {
        // Convert the collection to a SearchFilter
        let filter = SearchFilter(
            name: collection.archiveTitle ?? "Unknown Collection",
            identifier: collection.identifier ?? "",
            iconUrl: collection.iconUrl,
            uiImage: nil,
            image: nil
        )
        
        // Add filter to cache (will only add if identifier doesn't already exist)
        CollectionFilterCache.shared.addUserFilter(filter)
        
        // Update the UI state
        searchFilter = filter
        collectionName = filter.name
        collectionIdentifier = filter.identifier
        
        // Trigger a new search with this collection filter
        viewModel.search(
            query: viewModel.searchText,
            collection: filter.identifier.isEmpty ? nil : filter.identifier,
            loadMore: false
        )
    }

}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView().environmentObject(Player())
    }
}

extension SearchView {
    final class ViewModel: ObservableObject {
        @Published var items: [ArchiveMetaData] = []
        @Published var searchText: String = "" {
            didSet {
                withAnimation(.easeOut(duration: 0.33)) {
                    noDataFound = false
                }
            }
        }
        @Published var isSearching: Bool = false
        @Published var noDataFound: Bool = false
        @Published var archiveError: String?

        @Published var mediaType: Int = 0

        @Published var identifier: String?

        public let mediaTypes: [ArchiveMediaType] = [.audio, .movies, .collection]
        private var isLoadingMore: Bool = false
        private var page: Int = 1
        private var numberOfResults = 0
        private var rows = 50
        private var totalPages = 0

        var searchStarted: Bool = false

        let service: PlayerArchiveService

        init() {
            self.service = PlayerArchiveService()
        }

        @MainActor
        func search(query: String, collection:String? = nil, loadMore: Bool) {

            guard !searchText.isEmpty, searchText.count > 2, !searchStarted  else { return }
            self.isSearching = true
            self.noDataFound = false
            self.isLoadingMore = loadMore
            self.searchStarted = true
            self.archiveError = nil
            Task { @MainActor in
                do {

                    if !self.isLoadingMore {
                        self.page = 1
                        self.totalPages = 0
                        self.items.removeAll()
                    }

                    let format: ArchiveFileFormat? = nil //self.mediaTypes[self.mediaType] == .movies ? nil : .mp3
                    let searchMediaType: ArchiveMediaType = self.mediaTypes[self.mediaType]
                    print(query)
                    let data = try await self.service.searchPPSAsync(query: query, mediaTypes: [searchMediaType, .collection], rows: self.rows, page: self.page, format: format, collection: collection)

                    self.numberOfResults = data.response.numFound
                    self.totalPages = Int(ceil(Double(self.numberOfResults) / Double(self.rows)))

                    self.page += 1

                    print("The Page Number is: \(self.page)")
                    
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
                    withAnimation(.easeIn(duration: 0.33)) {
                        self.archiveError = error.description
                        self.noDataFound = true
                        self.isSearching = false
                        self.searchStarted = false
                    }
                    
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
                    
                    withAnimation(.easeIn(duration: 0.33)) {
                        self.archiveError = "An unexpected error occurred: \(error.localizedDescription)"
                        self.noDataFound = true
                        self.isSearching = false
                        self.searchStarted = false
                    }
                    
                    // Also show in universal error overlay
                    Task { @MainActor in
                        ArchiveErrorManager.shared.showError(error)
                    }
                }
            }
        }

        func firstCollection(_ metadata: ArchiveMetaData) -> ArchiveMetaData? {
            guard let firstCollection = metadata.collectionArchives.first else {
                return nil
            }

            return firstCollection.metadata
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Search Result Row

/// A row in the search results list that handles tap gestures
private struct SearchResultRow: View {
    let doc: ArchiveMetaData
    let isLastItem: Bool
    let onTap: () -> Void
    let onAppear: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            SearchItemView(item: doc)
                .padding(.horizontal, 10)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5))
        .listRowBackground(Color.clear)
        .onAppear(perform: onAppear)
    }
}

