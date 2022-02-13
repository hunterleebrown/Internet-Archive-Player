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
    @EnvironmentObject var iaPlayer: IAPlayer

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
            ScrollView {
                LazyVStack{
                    ForEach(playlistViewModel.items, id: \.self) { playlistItem in

                        FileView(playlistItem.file, auxControls: false,
                                 backgroundColor: playlistItem == iaPlayer.playingFile ? .fairyCream : nil,
                                 textColor: playlistItem == iaPlayer.playingFile ? .droopy : .white)
                            .padding(.leading, 5.0)
                            .padding(.trailing, 5.0)
                            .onTapGesture {
                                iaPlayer.playFile(playlistItem, playlistViewModel.items)
                            }
                    }
                }
                .background(Color.droopy)
            }
            .background(Color.droopy)
            .listStyle(PlainListStyle())

            Spacer()

            VStack {
                Slider(value: $iaPlayer.sliderProgress,
                       in: 0...1, onEditingChanged: { _ in
                    guard let currentItem = iaPlayer.avPlayer?.currentItem else { return }
                    if let player = iaPlayer.avPlayer {
                        let duration = CMTimeGetSeconds(currentItem.duration)
                        let sec = duration * Float64(iaPlayer.sliderProgress)
                        let seakTime:CMTime = CMTimeMakeWithSeconds(sec, preferredTimescale: 600)
                        player.seek(to: seakTime)
                    }

                })
                    .accentColor(.fairyCream)
                HStack{
                    Text(iaPlayer.minTime ?? "")
                        .font(.system(size:9.0))
                        .foregroundColor(.fairyCream)
                    Spacer()
                    Text(iaPlayer.maxTime ?? "")
                        .font(.system(size:9.0))
                        .foregroundColor(.fairyCream)

                }
            }
            .frame(alignment: .bottom)
            .frame(height:33)
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
