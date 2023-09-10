//
//  SearchFilters.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 9/9/23.
//

import Foundation
import iaAPI
import SwiftUI

struct SearchFilter: Hashable {
    var name: String
    var identifier: String
    var iconUrl: URL?
}


struct SearchFilters: View {

    @State private var searchFilter: SearchFilter?
    @StateObject var searchFiltersViewModel: SearchFiltersViewModel
    var delegate: SearchView?

    var body: some View {
        List(searchFiltersViewModel.items, id: \.self, selection: $searchFilter ) { filter in

            HStack(spacing: 10) {
//                if delegate?.collectionName == filter.name {
//                    Image(systemName: "checkmark")
//                        .foregroundColor(Color.fairyRed)
//                }

                if filter.iconUrl != nil {
                    AsyncImage(
                        url: filter.iconUrl,
                        content: { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 44,
                                       maxHeight: 44)
                                .background(Color.black)

                        },
                        placeholder: {
                            Color(.black)
                                .frame(maxWidth: 44,
                                       maxHeight: 44)
                        })
                    .cornerRadius(5)
                    .frame(width: 48, height: 44, alignment: .leading)
                }

                Text(filter.name)
                    .foregroundColor(delegate?.collectionName == filter.name ? Color.fairyCream : Color.black)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(.leading, 10)

            }
            .background(delegate?.collectionName == filter.name ? Color.fairyRed : Color.white)
            .cornerRadius(10)
        }
        .listStyle(PlainListStyle())
        .onChange(of: searchFilter) { newValue in
            if let val = newValue {
                searchFiltersViewModel.collectionSelection = val
                if let del = delegate {
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
}

class SearchFiltersViewModel: ObservableObject {
    @Published var collectionSelection: SearchFilter = SearchFilter(name: "All", identifier: "")

    let service: PlayerArchiveService
    let collectionType : ArchiveTopCollectionType
    @Published var items: [SearchFilter] = []

    init(collectionType: ArchiveTopCollectionType) {
        self.collectionType = collectionType
        self.service = PlayerArchiveService()
    }

    func search() {
        Task { @MainActor in
            do {

                let data = try await self.service.getCollections(from: self.collectionType)

                self.items = data.response.docs.map({ doc in
                    SearchFilter(name: doc.archiveTitle ?? "title", identifier: doc.identifier ?? "zero", iconUrl: doc.iconUrl)
                })

                var all = SearchFilter(name: "All", identifier: "")
                self.items.insert(all, at: 0)

                if self.items.count == 0 {
                    throw ArchiveServiceError.nodata
                }

            } catch let error as ArchiveServiceError {
//                withAnimation(.easeIn(duration: 0.33)) {
//                    self.archiveError = error.description
//                    self.noDataFound = true
//                    self.isSearching = false
//                    self.searchStarted = false
//                }
            }
        }
    }
}