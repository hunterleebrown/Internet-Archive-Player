//
//  SwiftUIView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI
import iaAPI
import Combine


struct SearchFilter: Hashable {
    var name: String
    var identifier: String
}


struct SearchFilters: View {

    @State private var searchFilter: SearchFilter?
    var searchFiltersViewModel: SearchFiltersViewModel
    var delegate: SearchView?

    let collections: [SearchFilter] = [
        SearchFilter(name: "All", identifier: ""),
        SearchFilter(name: "Audio Books & Poetry", identifier: "audio_bookspoetry"),
        SearchFilter(name: "LibriVox", identifier: "librivoxaudio")
    ]


    var body: some View {
        List(collections, id: \.self, selection: $searchFilter ) { filter in

            HStack {
                if searchFiltersViewModel.collectionSelection == filter {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color.fairyRed)
                }
                Text(filter.name)
            }
        }
        .onChange(of: searchFilter) { newValue in
            if let val = newValue {
                searchFiltersViewModel.collectionSelection = val
                if let del = delegate {
                    del.showCollections = false
                    del.viewModel.search(query: del.viewModel.searchText, collection: searchFiltersViewModel.collectionSelection.identifier.isEmpty ? nil : searchFiltersViewModel.collectionSelection.identifier, loadMore: false)

                }
            }
        }
    }
}

class SearchFiltersViewModel: ObservableObject {
    @Published var collectionSelection: SearchFilter = SearchFilter(name: "All", identifier: "")
}

struct SearchView: View {
    @EnvironmentObject var iaPlayer: Player
    @StateObject var viewModel = SearchView.ViewModel()
    @FocusState private var searchFocused: Bool
    @State private var collection: String = ""
    @State var showCollections: Bool = false
    @StateObject var searchFiltersViewModel = SearchFiltersViewModel()

    init() {
        searchFocused = false
    }

    var body: some View {
        NavigationStack {

            VStack(alignment: .leading, spacing: 5) {

                Picker("What media type?", selection: $viewModel.mediaType) {
                    Text(ArchiveMediaType.audio.rawValue).tag(0)
                    Text(ArchiveMediaType.movies.rawValue).tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .onChange(of: viewModel.mediaType) { newValue in
                    viewModel.search(query: viewModel.searchText, loadMore: false)
                }

                HStack(alignment: .center , spacing:20) {
                    Text("From collection:")
                    Button(searchFiltersViewModel.collectionSelection.name) {
                        showCollections = true
                    }
                }
                .padding(.horizontal, 20)


//                TextField("Collection?", text: $collection)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 5)
//                            .stroke(Color.gray, lineWidth: 1)
//                    )
//                    .padding([.horizontal], 20)




//                ScrollView(.horizontal) {
//                    LazyHStack {
//                        ForEach(0..<10) { i in
//                            RoundedRectangle(cornerRadius: 25)
//                                .fill(Color(hue: Double(i) / 10, saturation: 1, brightness: 1).gradient)
//                                .frame(width: 300, height: 100)
//                        }
//                    }
//                    .scrollTargetLayout()
//                }
//                .scrollTargetBehavior(.viewAligned)
//                .safeAreaPadding(.horizontal, 40)

                List{
                    ForEach(viewModel.items, id: \.self) { doc in
                        NavigationLink(destination:
                                        Detail(doc.identifier!)
                            .safeAreaInset(edge: .bottom, content: {
                                Spacer()
                                    .frame(height: 200)
                            })

                        ) {
                            SearchItemView(item: doc)
                                .onAppear {
                                    if doc == viewModel.items.last {
                                        viewModel.search(query: viewModel.searchText, loadMore: true)
                                    }
                                }
                        }
                        .listRowInsets(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                        .listRowBackground(Color.clear)
                    }
                }
                .zIndex(viewModel.noDataFound ? 2 : 1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .searchable(text: $viewModel.searchText, prompt: "Search The Internet Archive")
                .onSubmit(of: .search, {
                    viewModel.search(query: viewModel.searchText, collection: searchFiltersViewModel.collectionSelection.identifier.isEmpty ? nil : searchFiltersViewModel.collectionSelection.identifier, loadMore: false)
                })
                .frame(maxWidth: .infinity)
                .listStyle(PlainListStyle())

            }
            .sheet(isPresented: $showCollections) {
                SearchFilters(searchFiltersViewModel: searchFiltersViewModel, delegate: self)
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            Spacer()
                .frame(height: 200)
        })
        .navigationViewStyle(.stack)
        .navigationTitle("Search")
        .navigationBarColor(backgroundColor: Color("playerbackground"), titleColor: .fairyRed)
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
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

        private let mediaTypes: [ArchiveMediaType] = [.audio, .movies]
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

                    let format: ArchiveFileFormat = self.mediaTypes[self.mediaType] == .movies ? .h264HD : .mp3
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

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
