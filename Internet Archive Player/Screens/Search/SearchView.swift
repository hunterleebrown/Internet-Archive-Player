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

    init() {
        searchFocused = false
    }

    var body: some View {
        VStack {
//            HStack {
//                Image(systemName: "magnifyingglass")
//                    .foregroundColor(.gray)
//                TextField("Search the Internet Archive", text: $viewModel.searchText)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .autocapitalization(.none) // Optional: For case-insensitive searches
//                    .disableAutocorrection(true) // Optional: Disable autocorrection if unnecessary
//                    .onSubmit {
//                        viewModel.search(query: viewModel.searchText, collection: collectionIdentifier, loadMore: false)
//                    }
//            }
//            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 5) {

                Picker("What media type?", selection: $viewModel.mediaType) {
                    Image(systemName: "hifispeaker").tag(0)
                    Image(systemName: "video").tag(1)
                }
                .foregroundColor(.fairyRed)
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .onChange(of: viewModel.mediaType) {
                    viewModel.search(query: viewModel.searchText, loadMore: false)
                }

                HStack(alignment: .center , spacing:5) {


                    Button {
                        showCollections = true
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .buttonStyle(IAButton())

                    Text("Collection: ")
                        .font(.caption)

                    collectionLabel(filter: searchFilter)

                }
                .padding(.horizontal, 20)

                Divider()

                List{
                    ForEach(viewModel.items, id: \.self) { doc in
                        NavigationLink(destination: Detail(doc.identifier!)) {
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
                .listStyle(PlainListStyle())
                .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search The Internet Archive")
                .onSubmit(of: .search, {
                    viewModel.search(query: viewModel.searchText, collection: collectionIdentifier, loadMore: false)
                })
                .zIndex(viewModel.noDataFound ? 2 : 1)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationBarColor(backgroundColor: Color("playerBackground").opacity(0.5), titleColor: .fairyRed)
            .sheet(isPresented: $showCollections) {
                let type = self.viewModel.mediaTypes[self.viewModel.mediaType]
                if let topCollectionType = ArchiveTopCollectionType(rawValue: type.rawValue) {
                    let filterViewModel = SearchFiltersViewModel(collectionType: topCollectionType)
                    SearchFilters(searchFiltersViewModel: filterViewModel, delegate: self)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Spacer()
                .frame(height: iaPlayer.playingFile != nil ? iaPlayer.playerHeight + 10 : 0)
        }
        .navigationTitle("Search")
        .tint(.fairyRed)
    }

    @ViewBuilder
    func collectionLabel(filter: SearchFilter) -> some View {
        HStack(spacing: 5) {
            if let imageUrl = filter.iconUrl {
                AsyncImage(
                    url: imageUrl,
                    content: { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 20,
                                   maxHeight: 20)
                            .background(Color.black)
                    },
                    placeholder: {
                        Color(.black)
                            .frame(maxWidth: 20,
                                   maxHeight: 20)
                    })
                .cornerRadius(5)
                .frame(width: 20, height: 20)
            }

            Text(filter.name)
                .font(.caption)

            Spacer()
        }
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
        }

        func search(query: String, collection:String? = nil, loadMore: Bool) {

            guard IAReachability.isConnectedToNetwork() else {
                Player.networkAlert.send(true)
                return
            }

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

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
