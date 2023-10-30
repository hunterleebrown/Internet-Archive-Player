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

    let columns = [
        GridItem(.fixed(400)),
        GridItem(.fixed(400)),
        GridItem(.fixed(400)),
        GridItem(.fixed(400))
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
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
                                .cornerRadius(10)
                            }
                            .frame(width: 300, height: 250, alignment: .bottomLeading)
                            .background(
                                AsyncImage(url: doc.iconUrl, transaction: Transaction(animation: .spring())) { phase in
                                    switch phase {
                                    case .empty:
                                        Color.clear
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    case .failure(_):
                                        EmptyView()
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search The Internet Archive")
            .onChange(of: viewModel.searchText) {
                viewModel.search(query: viewModel.searchText, collection: nil, loadMore: false)
            }
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

        @Published var mediaType: Int = 1

        private var bag = Set<AnyCancellable>()


        public let mediaTypes: [ArchiveMediaType] = [.audio, .movies]
        private var isLoadingMore: Bool = false
        private var page: Int = 1
        private var numberOfResults = 0
        private var rows = 50
        private var totalPages = 0

        var searchStarted: Bool = false

        let service: PlayerArchiveService

        init() {
            self.service = PlayerArchiveService()

            //            $searchText
            //                .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            //                .sink(receiveValue: { [weak self] value in
            //                    self?.searchText = value
            //                })
            //                .store(in: &bag)
        }

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

                    let format: ArchiveFileFormat? = self.mediaTypes[self.mediaType] == .movies ? nil : .mp3
                    let searchMediaType: ArchiveMediaType = self.mediaTypes[self.mediaType]
                    print(query)
                    let data = try await self.service.searchAsync(query: query, mediaTypes: [searchMediaType], rows: self.rows, page: self.page, format: format, collection: collection)

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
