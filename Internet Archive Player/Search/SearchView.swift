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
            VStack(spacing:0) {
                HStack(spacing: 5.0) {
                    TextField("Search The Internet Archive",
                              text: $viewModel.searchText,
                              onCommit:{
                        if !viewModel.searchText.isEmpty {
                            viewModel.search(query: viewModel.searchText)
                        }})
                    .focused($searchFocused)
                    if viewModel.isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.leading, 5)
                .padding(.trailing, 5)

                if viewModel.noDataFound {
                    VStack(spacing:0) {
                        Text(viewModel.archiveError ?? "Error with Search")
                            .padding(10)
                            .foregroundColor(Color.fairyCream)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .background(Rectangle().fill(Color.fairyRedAlpha).cornerRadius(10))
                    }
                    .padding(5.0)
                    .transition(.move(edge: .leading))

                }

                ScrollView {
                    LazyVStack{
                        ForEach(viewModel.items, id: \.self) { doc in
                            NavigationLink(destination: Detail(doc.identifier!)) {
                                SearchItemView(item: doc)
                                    .padding(.leading, 5)
                                    .padding(.trailing, 5)
                                    .padding(.bottom, 5)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .padding(0)
            }
            .frame(alignment: .leading)
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(
                Image("petabox")
                    .resizable()
                    .opacity(0.3)
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 05)
//                LinearGradient(
//                    colors: [Color.fairyRed, Color.fairyCream],
//                    startPoint: .top, endPoint: .bottom)
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.black)
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
        
        let service: PlayerArchiveService

        init() {
            self.service = PlayerArchiveService()
        }

        func search(query: String) {
            guard !searchText.isEmpty, searchText.count > 2 else { return }
            self.items.removeAll()
            self.isSearching = true
            self.noDataFound = false
            Task { @MainActor in
                do {
                    self.items = try await self.service.searchAsync(query: query, format: .mp3).response.docs
                    self.isSearching = false
                } catch let error as ArchiveServiceError {
                    withAnimation(.easeIn(duration: 0.33)) {
                        self.archiveError = error.description
                        self.noDataFound = true
                        self.isSearching = false
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
