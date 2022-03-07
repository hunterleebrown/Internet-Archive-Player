//
//  SwiftUIView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI
import iaAPI
import Alamofire

struct SearchView: View {
    @State private var searchText = ""
    @ObservedObject var viewModel = SearchView.ViewModel()
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationView {
            VStack {
                HStack(spacing: 5.0) {

                    TextField("Search The Internet Archive",
                              text: $searchText,
                              onCommit:{
                        if !searchText.isEmpty {
                            viewModel.cancelRequest()
                            viewModel.searchText = searchText
                            searchFocused = false
                        }})
                        .focused($searchFocused)
                    //                    .onChange(of: searchText, perform: { text in
                    //                        if !text.isEmpty {
                    //                            viewModel.cancelRequest()
                    //                            viewModel.searchText = text
                    //                        } else {
                    //                            viewModel.cancelRequest()
                    //                            searchFocused = false
                    //                        }
                    //                    })

                    if viewModel.isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(5)

                ScrollView {
                    LazyVStack{
                        ForEach(viewModel.items, id: \.self) { doc in
                            NavigationLink(destination: Detail(doc.identifier)) {
                                SearchItemView(item: doc)
                                    .padding(.leading, 5)
                                    .padding(.trailing, 5)
                                    .padding(.bottom, 5)
                            }
                        }
                    }
                    //                    .background(Color.droopy)
                }
                //                .background(Color.droopy)
                .listStyle(PlainListStyle())
                .padding(0)
            }
            .frame(alignment: .leading)
            .environmentObject(viewModel)
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(
                Image("petabox")
                    .resizable()
                    .opacity(0.3)
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 05)
            )
            //            .background(Color.droopy)
        }
        //        .background(Color.droopy)
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(Color.black)
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}

extension SearchView {
    final class ViewModel: ObservableObject {
        @Published var items: [IASearchDoc] = []
        @Published var searchText: String = "" {
            didSet { handleTextChange() }
        }
        @Published var isSearching: Bool = false
        
        let service: IAService
        private var request: Request?

        init() {
            self.service = IAService()
        }

        func cancelRequest() {
            if let req = request {
                req.cancel()
                self.isSearching = false
            }
        }
        
        func handleTextChange() {
            guard searchText != "" else { return }
            self.search(query: searchText)
            self.isSearching = true
        }
        
        func search(query: String) {
            self.items.removeAll()
            request = self.service.search(queryString: query,
                                          searchField: .all,
                                          mediaTypes: [.audio],
                                          rows: 100,
                                          format: .mp3)
            { (docs, error) in
                docs?.forEach({ (doc) in
                    self.items.append(doc)
                })
                self.isSearching = false
            }
        }
    }
}

extension IASearchDoc: Hashable {
    
    public static func == (lhs: IASearchDoc, rhs: IASearchDoc) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.title == rhs.title
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        hasher.combine(title)
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
