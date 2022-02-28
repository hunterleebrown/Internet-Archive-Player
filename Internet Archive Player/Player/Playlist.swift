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
                    .font(.title)
                    .foregroundColor(.fairyCream)
                    .padding(10)
                Spacer()
                Button(action: {
                    playlistViewModel.items.removeAll()

                }) {
                    Text("Clear")
                        .padding(10)
                        .foregroundColor(.fairyCream)
                }

            }
            List{
                ForEach(playlistViewModel.items, id: \.self) { playlistItem in
                    FileView(playlistItem.file, auxControls: false,
                             backgroundColor: playlistItem == iaPlayer.playingFile ? .fairyCream : nil,
                             textColor: playlistItem == iaPlayer.playingFile ? .droopy : .white)
                        .onTapGesture {
                            iaPlayer.playFile(playlistItem, playlistViewModel.items)
                        }
                        .padding(0)
                        .listRowBackground(Color.droopy)
                }
                .onDelete(perform: self.remove)
            }
            .listStyle(PlainListStyle())
            .background(Color.droopy)
            .padding(0)

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

    func remove(at offsets: IndexSet) {
        self.playlistViewModel.items.remove(atOffsets: offsets)
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

struct PlaylistItem: Hashable, Identifiable  {
    var id = UUID()
    let file: PlaylistFile
    let identifier: String
    let artist: String
    let identifierTitle: String
    
    init(_ file: PlaylistFile, _ doc: IAArchiveDoc) {
        self.file = file
        self.identifier = doc.identifier!
        self.artist = doc.artist ?? doc.creator ?? ""
        self.identifierTitle = doc.title ?? ""
    }
    
    public static func == (lhs: PlaylistItem, rhs: PlaylistItem) -> Bool {
        return lhs.file.name == rhs.file.name &&
        lhs.file.title == rhs.file.title &&
        lhs.file.format == rhs.file.format &&
        lhs.file.track == rhs.file.track &&
        lhs.identifier == rhs.identifier
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(file.title)
        hasher.combine(file.track)
        hasher.combine(file.name)
        hasher.combine(file.format)
        hasher.combine(identifier)
    }

    public func fileUrl() ->URL {
        let urlString = "https://archive.org/download/\(identifier)/\(file.name!)"
        return URL(string: urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)!
    }
}

struct PlaylistFile: Hashable {

    var name: String?
    var title: String?
    var track: String?
    var size: String?
    var format: iaAPI.IAFileFormat?
    var length: String?

    init(_ file: IAFile)  {
        self.name = file.name
        self.title = file.title
        self.format = file.format
        self.track = file.track
        self.length = file.length
        self.size = file.size
    }

    public static func == (lhs: PlaylistFile, rhs: PlaylistFile) -> Bool {
        return lhs.name == rhs.name &&
        lhs.title == rhs.title &&
        lhs.format == rhs.format &&
        lhs.track == rhs.track &&
        lhs.length == rhs.length
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(track)
        hasher.combine(name)
        hasher.combine(format)
        hasher.combine(length)
    }

    public var displayLength: String? {

        if let l = length {
            return IAStringUtils.timeFormatter(timeString: l)
        }
        return nil
    }

    public var cleanedTrack: Int?{

        if let tr = track {
            if let num = Int(tr) {
                return num
            } else {
                let sp = tr.components(separatedBy: "/")
                if let first = sp.first {
                    let trimmed = first.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    return Int(trimmed) ?? nil
                }
            }
        }
        return nil
    }

    public var calculatedSize: String? {

        if let s = size {
            if let rawSize = Int(s) {
                return IAStringUtils.sizeString(size: rawSize)
            }
        }
        return nil
    }
}
