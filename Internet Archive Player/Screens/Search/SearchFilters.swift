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
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dismiss()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.fairyRed)
                        .font(.title3)
                }
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
            List(searchFiltersViewModel.items, id: \.self, selection: $searchFilter) { filter in
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
            .listStyle(.plain)
        }
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
    
    private func isSelected(_ filter: SearchFilter) -> Bool {
        delegate?.collectionName == filter.name
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
