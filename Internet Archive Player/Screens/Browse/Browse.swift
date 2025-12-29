//
//  Browse.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/21/25.
//

import SwiftUI
import iaAPI

struct Browse: View {
    @StateObject private var viewModel = BrowseViewModel()

    var body: some View {
        NavigationStack {
            List {
                filtersSection(title: "Audio", filters: viewModel.audioFilters)
                filtersSection(title: "Movies", filters: viewModel.moviesFilters)
                filtersSection(title: "Previously Searched Collections", filters: viewModel.userFilters)
            }
            .listStyle(.plain)
            .navigationDestination(for: SearchFilter.self) { filter in
                BrowseResultsView(filter: filter)
            }
            .navigationTitle("Browse")
            .task {
                viewModel.loadCollections()
            }
            .avoidPlayer()
        }
    }
    
    @ViewBuilder
    private func filtersSection(title: String, filters: [SearchFilter]) -> some View {
        if !filters.isEmpty {
            Section {
                ForEach(filters) { filter in
                    NavigationLink(value: filter) {
                        FilterRowView(filter: filter)
                    }
                }
            } header: {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.fairyRed)
                    .textCase(nil)
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Filter Row View
struct FilterRowView: View {
    let filter: SearchFilter
    
    var body: some View {
        HStack(spacing: 10) {
            FilterIconView(filter: filter)
                .frame(width: 40, height: 40)
            
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
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

// MARK: - Filter Icon View
struct FilterIconView: View {
    let filter: SearchFilter
    
    var body: some View {
        Group {
            if let image = filter.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if let uiImage = filter.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if let iconUrl = filter.iconUrl {
                CachedAsyncImage(
                    url: iconUrl,
                    content: { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .background(Color.black)
                    },
                    placeholder: {
                        Color(.systemGray5)
                    }
                )
                .cornerRadius(5)
            }
        }
    }
}

// MARK: - Browse Results View
struct BrowseResultsView: View {
    let filter: SearchFilter
    @StateObject private var viewModel = BrowseResultsViewModel()
    @State private var hasLoaded = false
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                ProgressView("Loading...")
            } else if viewModel.items.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No items found for \(filter.name)")
                )
            } else {
                resultsList
            }
        }
        .avoidPlayer()
        .navigationTitle(filter.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !hasLoaded else { return }
            await viewModel.search(collection: filter.identifier)
            hasLoaded = true
        }
    }
    
    private var resultsList: some View {
        List(viewModel.items, id: \.self) { doc in
            resultLink(for: doc)
                .onAppear {
                    if doc == viewModel.items.last {
                        Task { await viewModel.loadMore(collection: filter.identifier) }
                    }
                }
        }
        .buttonStyle(.plain)
        .listStyle(PlainListStyle())
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color.clear)
        .navigationDestination(for: SearchFilter.self) { filter in
            BrowseResultsView(filter: filter)
        }
        .navigationDestination(for: String.self) { identifier in
            Detail(identifier)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

    }
    
    @ViewBuilder
    private func resultLink(for doc: ArchiveMetaData) -> some View {
        if doc.mediatype == .collection {

            SearchItemView(item: doc)
                .background(
                    NavigationLink(value: doc.asSearchFilter()) {
                        EmptyView() // Empty label
                    }
                        .opacity(0) // Hide the link itself
                )
                .contentShape(Rectangle())

        } else if let identifier = doc.identifier {
            SearchItemView(item: doc)
                .background(
                    NavigationLink(value: identifier) {
                        EmptyView() // Empty label
                    }
                        .opacity(0) // Hide the link itself
                )
                .contentShape(Rectangle())
        }
    }
}

// MARK: - Browse View Model
@MainActor
final class BrowseViewModel: ObservableObject {
    @Published var audioFilters: [SearchFilter] = []
    @Published var moviesFilters: [SearchFilter] = []
    @Published var userFilters: [SearchFilter] = []
    
    func loadCollections() {
        let cache = CollectionFilterCache.shared
        audioFilters = cache.audioFilters.filter { !$0.identifier.isEmpty }
        moviesFilters = cache.moviesFilters.filter { !$0.identifier.isEmpty }
        userFilters = cache.userFilters.filter { !$0.identifier.isEmpty }
    }
}

// MARK: - Browse Results View Model
@MainActor
final class BrowseResultsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var items: [ArchiveMetaData] = []
    
    private let service = PlayerArchiveService()
    private var page = 1
    private let rows = 50
    private var searchTask: Task<Void, Never>?
    
    func search(collection: String) async {
        searchTask?.cancel()
        isLoading = true
        page = 1
        items.removeAll()
        
        await performSearch(collection: collection)
    }
    
    func loadMore(collection: String) async {
        guard !isLoading else { return }
        await performSearch(collection: collection)
    }
    
    private func performSearch(collection: String) async {
        searchTask = Task {
            defer { isLoading = false }
            
            do {
                let data = try await service.searchPPSAsync(
                    query: collection,
                    mediaTypes: [.audio, .movies, .collection],
                    rows: rows,
                    page: page,
                    format: nil,
                    collection: collection
                )
                
                guard !Task.isCancelled else { return }
                
                // Sort collections to top and filter out TV archive
                let filtered = data.response.docs
                    .filter { !$0.collection.contains { $0.lowercased() == "tvarchive" } }
                    .sorted { lhs, rhs in
                        (lhs.mediatype == .collection) && (rhs.mediatype != .collection)
                    }
                
                items.append(contentsOf: filtered)
                page += 1
                
                if items.isEmpty {
                    throw ArchiveServiceError.nodata
                }
            } catch {
                guard !error.localizedDescription.lowercased().contains("cancel") else { return }
                ArchiveErrorManager.shared.showError(error)
            }
        }
        
        await searchTask?.value
    }
}

// MARK: - ArchiveMetaData Extension
extension ArchiveMetaData {
    func asSearchFilter() -> SearchFilter {
        SearchFilter(
            name: archiveTitle ?? "Collection",
            identifier: identifier ?? "",
            iconUrl: iconUrl
        )
    }
}
