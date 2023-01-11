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

    init() {
        searchFocused = false
    }

    var body: some View {
        NavigationView {
            //            VStack() {
            //                Text(viewModel.archiveError ?? "Error with Search")
            //                    .padding(10)
            //                    .foregroundColor(Color.fairyCream)
            //                    .font(.headline)
            //                    .frame(maxWidth: .infinity)
            //                    .background(Rectangle().fill(Color.fairyRedAlpha).cornerRadius(10))
            //                    .transition(.move(edge: .leading))
            //                Spacer()
            //            }
            //            .zIndex(viewModel.noDataFound ? 1 : 2)
            //            .padding(10)


            VStack(alignment: .leading, spacing: 5.0) {

                Picker("What media type?", selection: $viewModel.mediaType) {
                    Text(ArchiveMediaType.audio.rawValue).tag(0)
                    Text(ArchiveMediaType.movies.rawValue).tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

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
                .zIndex(viewModel.noDataFound ? 2 : 1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .searchable(text: $viewModel.searchText, prompt: "Search The Internet Archive")
                .onSubmit(of: .search, {
                    viewModel.search(query: viewModel.searchText, loadMore: false)
                })
//                .background(
//                    Image("petabox")
//                        .resizable()
//                        .opacity(0.3)
//                        .aspectRatio(contentMode: .fill)
//                        .blur(radius: 05)
//                )
                .background(Color.white)
                .frame(maxWidth: .infinity)
                .listStyle(PlainListStyle())
                .navigationTitle("Search")
                .navigationBarColor(backgroundColor: UIColor(white: 1.0, alpha: 0.5), titleColor: .fairyRed)


            }
        }
        .navigationViewStyle(.stack)
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

        func search(query: String, loadMore: Bool) {
            guard !searchText.isEmpty, searchText.count > 2, !searchStarted  else { return }
            self.isSearching = true
            self.noDataFound = false
            self.isLoadingMore = loadMore
            self.searchStarted = true
            Task { @MainActor in
                do {

                    if !self.isLoadingMore {
                        self.page = 1
                        self.totalPages = 0
                        self.items.removeAll()
                    }

                    let format: ArchiveFileFormat = self.mediaTypes[self.mediaType] == .movies ? .h264HD : .mp3
                    let searchMediaType: ArchiveMediaType = self.mediaTypes[self.mediaType]

                    let data = try await self.service.searchAsync(query: query, mediaTypes: [searchMediaType], rows: self.rows, page: self.page, format: format)

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
