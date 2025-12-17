//
//  TVSearchView.swift
//  Internet Archive Player tvOS
//
//  Created by Hunter Lee Brown on 10/28/23.
//

import Foundation
import SwiftUI
import iaAPI
import Combine

struct TVSearchView: View {
    @StateObject var viewModel = TVSearchView.ViewModel()

    // Adaptive columns that adjust based on available space
    let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(viewModel.items, id: \.self) { doc in
                        NavigationLink(destination: TVDetail(doc: doc)) {
                            VStack(spacing: 0) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(doc.archiveTitle ?? "")
                                        .font(.caption)
                                        .multilineTextAlignment(.leading)
                                    
                                    Text(doc.formatDateString() ?? "")
                                        .font(.system(size: 20))
                                }
                                .foregroundColor(.white)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.black.opacity(0.55))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                            .aspectRatio(1.2, contentMode: .fit)
                            .background(
                                AsyncImage(url: doc.iconUrl, transaction: Transaction(animation: .spring())) { phase in
                                    switch phase {
                                    case .empty:
                                        Color.gray.opacity(0.3)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure(_):
                                        Color.gray.opacity(0.3)
                                    @unknown default:
                                        Color.gray.opacity(0.3)
                                    }
                                }
                            )
                            .clipped()
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
            }
            .searchable(text: $viewModel.searchText, prompt: "Search The Internet Archive")
        }
    }
}

extension TVSearchView {
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var items: [ArchiveMetaData] = []
        @Published var searchText: String = ""
        @Published var isSearching: Bool = false
        @Published var noDataFound: Bool = false
        @Published var archiveError: String?

        public let mediaTypes: [ArchiveMediaType] = [.audio, .movies]
        private var searchTask: Task<Void, Never>?
        private var page: Int = 1
        private let rows = 50

        let service: PlayerArchiveService

        init() {
            self.service = PlayerArchiveService()
            
            // Simple debounced search using Task
            Task { @MainActor in
                for await searchText in $searchText.values {
                    // Cancel previous search
                    searchTask?.cancel()
                    
                    let query = searchText.trimmingCharacters(in: .whitespaces)
                    
                    // Clear results if query is too short
                    guard query.count > 2 else {
                        items = []
                        noDataFound = false
                        archiveError = nil
                        continue
                    }
                    
                    // Debounce
                    try? await Task.sleep(for: .milliseconds(500))
                    
                    // Start search
                    searchTask = Task { @MainActor in
                        await performSearch(query: query)
                    }
                }
            }
        }
        
        private func performSearch(query: String) async {
            isSearching = true
            noDataFound = false
            archiveError = nil
            page = 1
            
            do {
                let data = try await service.searchAsync(
                    query: query,
                    mediaTypes: mediaTypes,
                    rows: rows,
                    page: page,
                    format: nil,
                    collection: nil
                )
                
                // Check if task was cancelled
                guard !Task.isCancelled else { return }
                
                items = data.response.docs
                isSearching = false
                
                if items.isEmpty {
                    noDataFound = true
                    archiveError = "No results found"
                }
                
            } catch let error as ArchiveServiceError {
                guard !Task.isCancelled else { return }
                archiveError = error.description
                noDataFound = true
                isSearching = false
            } catch {
                guard !Task.isCancelled else { return }
                isSearching = false
            }
        }
        
        func loadMore() async {
            guard !isSearching else { return }
            
            let query = searchText.trimmingCharacters(in: .whitespaces)
            guard query.count > 2 else { return }
            
            isSearching = true
            page += 1
            
            do {
                let data = try await service.searchAsync(
                    query: query,
                    mediaTypes: mediaTypes,
                    rows: rows,
                    page: page,
                    format: nil,
                    collection: nil
                )
                
                items.append(contentsOf: data.response.docs)
                isSearching = false
                
            } catch {
                isSearching = false
                page -= 1 // Revert page on failure
            }
        }
    }
}


struct Home_Preview: PreviewProvider {
    static var previews: some View {
        TVSearchView()
    }
}
