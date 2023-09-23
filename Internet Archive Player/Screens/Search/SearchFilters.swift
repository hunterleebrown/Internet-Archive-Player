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

struct SearchFilter: Hashable {
    var name: String
    var identifier: String
    var iconUrl: URL?
    var uiImage: UIImage?
    var image: Image?

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}


struct SearchFilters: View {

    @State private var searchFilter: SearchFilter?
    @StateObject var searchFiltersViewModel: SearchFiltersViewModel
    var delegate: SearchView?

    var body: some View {
        VStack(alignment: .center, spacing:10){
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(.fairyRed)
                    .font(.headline)
                Text("Filter by collection")
                    .font(.headline)
                    .foregroundColor(Color.fairyRed)
            }
            List(searchFiltersViewModel.items, id: \.self, selection: $searchFilter ) { filter in

                HStack(alignment:.top, spacing: 5.0) {

                    if let image = filter.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44, height: 48)
                            .padding(.horizontal, 5)
                    } else if let uiImage = filter.uiImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .cornerRadius(5)
                            .frame(width: 44, height: 48)
                            .padding(.horizontal, 5)

                    } else if filter.iconUrl != nil {
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
                        .frame(width: 44, height: 48)
                        .padding(.horizontal, 5)
                    }

                    Text(filter.name)
                        .font(.subheadline)
                        .foregroundColor(delegate?.collectionName == filter.name ? Color.fairyCream : Color("playerBackgroundText"))
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .padding(.leading, 5)

                }
                .listRowInsets(EdgeInsets(top: 1, leading: 5, bottom: 1, trailing: 5))
                .background(delegate?.collectionName == filter.name ? Color.fairyRed : Color("playerBackgrouond"))
                .cornerRadius(10)
            }
            .listStyle(PlainListStyle())
        }
        .offset(y:10)
        .onChange(of: searchFilter) { oldValue, newValue in
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

struct SearchFilters_Previews: PreviewProvider {
    static var previews: some View {
        SearchFilters(searchFiltersViewModel: SearchFiltersViewModel(collectionType: .audio))
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


                let image = Image(systemName: self.collectionType == .movies ? "video" : "hifispeaker")


                let all = SearchFilter(name: "All \(self.collectionType.rawValue.capitalized)", identifier: "", image: image)
                self.items.insert(all, at: 0)

                if self.items.count == 0 {
                    throw ArchiveServiceError.nodata
                }

            } catch _ as ArchiveServiceError {
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
