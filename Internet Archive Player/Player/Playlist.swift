//
//  SwiftUIView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/22/22.
//

import SwiftUI
import iaAPI

struct Playlist: View {
    @State private var seek = 1.0
    @EnvironmentObject var playlistViewModel: Playlist.ViewModel

    var body: some View {
        VStack(alignment:.leading, spacing: 0){
            HStack(spacing:10.0) {
                Text("Playlist")
                    .foregroundColor(.fairyCream)
                    .padding(10)
                Spacer()
                Button(action: {
                    playlistViewModel.items.removeAll()

                }) {
                    Text("Clear")
                        .padding(10)
                        .foregroundColor(.fairyCream)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.fairyCream, lineWidth: 2)
                    )
                }

            }

            Spacer()

            ScrollView {
                LazyVStack{

                    ForEach(playlistViewModel.items, id: \.self) { doc in
                        NavigationLink(destination: Detail(doc)) {
                            SearchItemView(item: doc)
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

            VStack {
                Slider(value: $seek,
                       in: 0...100)
                    .accentColor(.fairyCream)
                HStack{
                    Text("0:00:00")
                        .font(.system(size:9.0))
                        .foregroundColor(.fairyCream)
                    Spacer()
                    Text("0.00.00")
                        .font(.system(size:9.0))
                        .foregroundColor(.fairyCream)

                }
                .frame(height:30)
            }
            .frame(alignment: .bottom)
        }
        .padding(10)
        .modifier(BackgroundColorModifier(backgroundColor: .droopy))
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    
    static var previews: some View {
        Playlist()
            .environmentObject(Playlist.ViewModel())
    }
}

extension Playlist {
    final class ViewModel: ObservableObject {
        @Published var items: [IASearchDoc] = []
    }
}
