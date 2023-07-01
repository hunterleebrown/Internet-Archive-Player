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
import Combine

struct Playlist: View {
    @EnvironmentObject var iaPlayer: Player
    @StateObject var viewModel = Playlist.ViewModel()
    @State private var seek = 1.0
    @State private var showingAlert = false

    var body: some View {
        List{
            ForEach(iaPlayer.items, id: \.self) { archiveFile in
                EntityFileView(archiveFile,
                               showImage: true,
                               backgroundColor: archiveFile.url?.absoluteURL == viewModel.playingFile?.url?.absoluteURL ? .fairyRedAlpha : nil,
                               textColor: archiveFile.url?.absoluteURL == viewModel.playingFile?.url?.absoluteURL ? .fairyCream : .primary,
                               fileViewMode: .playlist)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .onTapGesture {
                    iaPlayer.playFile(archiveFile)
                }
                .padding(10)
            }
            .onDelete(perform: self.remove)
            .onMove(perform: self.move)
        }
        .listStyle(PlainListStyle())
        .modifier(BackgroundColorModifier(backgroundColor: Color("playerBackground")))
        .onAppear() {
            viewModel.setUpSubscribers(iaPlayer)
            iaPlayer.sendPlayingFileForPlaylist()
        }
        .navigationBarColor(backgroundColor: Color("playerBackground"), titleColor: .fairyRed)
        .tint(.fairyRed)

    }

    private func remove(at offsets: IndexSet) {
        self.iaPlayer.removePlaylistItem(at: offsets)
    }

    private func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        self.iaPlayer.rearrangePlaylist(fromOffsets: source, toOffset: destination)
    }
}

extension Playlist {
    final class ViewModel: ObservableObject {
        @Published var playingFile: ArchiveFileEntity? = nil

        var cancellables = Set<AnyCancellable>()

        public func setUpSubscribers(_ iaPlayer: Player) {
            iaPlayer.playingFilePublisher
                .sink { file in
                    self.playingFile = file
                }
                .store(in: &cancellables)
        }
    }
}


struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        Playlist()
    }
}

