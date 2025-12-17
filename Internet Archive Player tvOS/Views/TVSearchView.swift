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
    @State private var searchText = ""
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

        private var bag = Set<AnyCancellable>()
        private var searchTask: Task<Void, Never>?

        public let mediaTypes: [ArchiveMediaType] = [.audio, .movies]
        private var isLoadingMore: Bool = false
        private var page: Int = 1
        private var numberOfResults = 0
        private var rows = 50
        private var totalPages = 0

        let service: PlayerArchiveService

        init() {
            self.service = PlayerArchiveService()

            $searchText
                .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
                .removeDuplicates()
                .sink(receiveValue: { [weak self] value in
                    guard let self = self else { return }
                    self.search(query: value, collection: nil, loadMore: false)
                })
                .store(in: &bag)
        }

        func search(query: String, collection:String? = nil, loadMore: Bool) {
            guard !query.isEmpty, query.count > 2 else { 
                self.items.removeAll()
                return 
            }
            
            // Cancel any existing search
            searchTask?.cancel()
            
            self.isSearching = true
            self.noDataFound = false
            self.isLoadingMore = loadMore
            self.archiveError = nil
            
            searchTask = Task { @MainActor in
                do {

                    if !self.isLoadingMore {
                        self.page = 1
                        self.totalPages = 0
                        self.items.removeAll()
                    }

//                    let format: ArchiveFileFormat? = .mp3 //self.mediaTypes[self.mediaType] == .movies ? nil : .mp3
//                    let searchMediaType: ArchiveMediaType = self.mediaTypes[self.mediaType]
                    print("Searching for: \(query)")
                    let data = try await self.service.searchAsync(query: query, mediaTypes: self.mediaTypes, rows: self.rows, page: self.page, format: nil, collection: collection)

                    self.numberOfResults = data.response.numFound
                    self.totalPages = Int(ceil(Double(self.numberOfResults) / Double(self.rows)))

                    self.page += 1

                    print("The Page Number is: \(self.page)")
                    if !isLoadingMore {
                        self.items = data.response.docs
                    } else {
                        self.items += data.response.docs
                    }

                    self.isSearching = false

                    if self.items.count == 0 {
                        throw ArchiveServiceError.nodata
                    }

                } catch let error as ArchiveServiceError {
                    withAnimation(.easeIn(duration: 0.33)) {
                        self.archiveError = error.description
                        self.noDataFound = true
                        self.isSearching = false
                    }
                } catch {
                    // Handle cancellation
                    self.isSearching = false
                }
            }
        }
    }
}


struct Home_Preview: PreviewProvider {
    static var previews: some View {
        TVSearchView()
    }
}
