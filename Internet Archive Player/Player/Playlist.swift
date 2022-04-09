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
                    iaPlayer.clearPlaylist()
                }) {
                    Text("Clear")
                        .padding(10)
                        .foregroundColor(.fairyCream)
                }
            }
            List{
                ForEach(iaPlayer.items, id: \.self) { playlistItem in
                    FileView(playlistItem,
                             showImage: true,
                             showDownloadButton: true,
                             backgroundColor: playlistItem == iaPlayer.playingFile ? .fairyCream : nil,
                             textColor: playlistItem == iaPlayer.playingFile ? .droopy : .white)
                        .onTapGesture {
                            iaPlayer.playFile(playlistItem)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
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
        self.iaPlayer.removePlaylistItem(at: offsets)
    }

}

struct SwiftUIView_Previews: PreviewProvider {
    
    static var previews: some View {
        Playlist()
    }
}

struct PlaylistItem: Hashable, Identifiable  {
    var id = UUID()
    let file: ArchiveFile
    let identifier: String
    let artist: String
    let identifierTitle: String
    let archiveDoc: ArchiveMetaData
    
    init(_ file: ArchiveFile, _ doc: ArchiveMetaData) {
        self.file = file
        self.archiveDoc = doc
        self.identifier = doc.identifier!
        self.artist = doc.artist ?? doc.creator.first ?? ""
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

    public func fileUrl() -> URL {
        return self.file.url!
    }

    public var iconUrl: URL {
        return self.archiveDoc.iconUrl
    }
}

struct PlaylistFile: Hashable {

    var name: String?
    var title: String?
    var track: String?
    var size: String?
    var format: iaAPI.ArchiveFileFormat?
    var length: String?

    init(_ file: ArchiveFile)  {
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
