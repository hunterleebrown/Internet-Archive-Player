//
//  SwiftUIView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/22/22.
//

import SwiftUI
import iaAPI
import MediaPlayer
import AVFoundation
import AVKit

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
                    ForEach(playlistViewModel.items, id: \.self) { playlistItem in
                        FileView(playlistItem.file)
                            .padding(.leading, 5.0)
                            .padding(.trailing, 5.0)
                            .onTapGesture {
//                                if let archiveDoc = self.viewModel.archiveDoc {
//                                    iaPlayer.playFile((file: file, doc: archiveDoc))
//                                }
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
        @Published var items: [PlaylistItem] = []
    }
}

struct PlaylistItem: Hashable  {
    
    let file: IAFile
    let doc: IAArchiveDoc
    
    init(_ file: IAFile, _ doc: IAArchiveDoc) {
        self.file = file
        self.doc = doc
    }
    
    public static func == (lhs: PlaylistItem, rhs: PlaylistItem) -> Bool {
        return lhs.file.name == rhs.file.name &&
        lhs.file.title == rhs.file.title &&
        lhs.file.format == rhs.file.format &&
        lhs.file.track == rhs.file.track &&
        lhs.doc.identifier == rhs.doc.identifier
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(file.title)
        hasher.combine(file.track)
        hasher.combine(file.name)
        hasher.combine(file.format)
        hasher.combine(doc.identifier)
    }
}
