//
//  SwiftUIView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI
import iaAPI

struct SearchView: View {
    @State private var searchText = ""
    @ObservedObject var viewModel = SearchView.ViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar()
                    .padding(10)
                //                    .background(Color.fairyRed)
                ScrollView {
                    LazyVStack{
                        
                        ForEach(viewModel.items, id: \.self) { doc in
                            NavigationLink(destination: Detail(doc: doc)) {
                                ItemView(item: doc)
                                    .padding(.leading, 10)
                                    .padding(.trailing, 10)
                                    .padding(.bottom, 10)
                            }
                        }
                    }
                    .background(Color.droopy)
                }
                .background(Color.droopy)
                .listStyle(PlainListStyle())
            }
            .frame(alignment: .leading)
            .environmentObject(viewModel)
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(Color.droopy)
        }
        .background(Color.droopy)
        .navigationViewStyle(StackNavigationViewStyle())
        
    }
    
    struct SearchBar: View {
        @EnvironmentObject var viewModel: ViewModel
        
        var body: some View {
            HStack(spacing: 20) {
                SearchTextField($viewModel.searchText)
                    .becomeFirstResponder()
                    .onReturn {
                    }
                    .cornerRadius(4)
                
            }
            .frame(height: 36.0)
        }
    }
    
    struct ItemView: View {
        var item: IASearchDoc
        var body: some View {
            HStack(alignment:.top, spacing: 10.0) {
                
                AsyncImage(
                    url: item.iconUrl,
                    content: { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 80,
                                   maxHeight: 80)
                            .background(Color.black)
                        
                    },
                    placeholder: {
                        ProgressView()
                    })
                    .cornerRadius(15)
                
                VStack(alignment:.leading) {
                    Text(item.title ?? "")
                        .frame(alignment:.leading)
                        .font(.headline)
                        .foregroundColor(.fairyCream)
                        .multilineTextAlignment(.leading)
                    Text(item.creator.joined(separator: ", "))
                        .font(.footnote)
                        .frame(alignment:.leading)
                        .foregroundColor(.fairyCream)
                        .multilineTextAlignment(.leading)
                    Text(item.desc ?? "")
                        .font(.body)
                        .frame(alignment:.leading)
                        .foregroundColor(.fairyCream)
                        .multilineTextAlignment(.leading)

                }
                .frame(maxWidth: .infinity,
                       alignment: .leading)
            }
            .background(Color.droopy)
            .frame(maxWidth: .infinity,
                   minHeight: 90)
        }
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
        let service: IAService
        
        init() {
            self.service = IAService()
        }
        
        func handleTextChange() {
            guard searchText != "" else { return }
            self.search(query: searchText)
        }
        
        func search(query: String) {
            self.items.removeAll()
            self.service.search(queryString: query,
                                searchField: .all,
                                mediaTypes: [.audio],
                                rows: 100,
                                format: .mp3) { (docs, error) in
                docs?.forEach({ (doc) in
                    self.items.append(doc)
                })
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
