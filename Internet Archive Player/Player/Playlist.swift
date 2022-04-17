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
        NavigationView {
            VStack(alignment:.leading, spacing: 0){
                List{
                    ForEach(viewModel.items, id: \.self) { archiveFile in
                        FileView(archiveFile,
                                 showImage: true,
                                 showDownloadButton: true,
                                 backgroundColor: archiveFile == viewModel.playingFile ? .fairyCream : nil,
                                 textColor: archiveFile == viewModel.playingFile ? .droopy : .white,
                                 fileViewMode: .playlist)
                        .onTapGesture {
                            iaPlayer.playFile(archiveFile)
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
            }
            .padding(10)
            .modifier(BackgroundColorModifier(backgroundColor: .droopy))
            .navigationTitle("Playlist")
            .navigationBarColor(backgroundColor: IAColors.droopy, titleColor: UIColor.fairyCream)
            .onAppear() {
                viewModel.setUpSubscribers(iaPlayer)
                iaPlayer.sendPlayingFileForPlaylist()
                iaPlayer.sendItemsPlaylist()
            }
            .toolbar {
                HStack {
                    Button(action: {
                        showingAlert = true
                    }) {
                        Text("Clear")
                            .padding(10)
                            .foregroundColor(.fairyCream)
                    }
                    .alert("Are you sure you want to delete the playlist?", isPresented: $showingAlert) {
                        Button("No", role: .cancel) { }
                        Button("Yes") {
                            viewModel.items.removeAll()
                            iaPlayer.clearPlaylist()
                        }
                    }

                    Button(action: {
                        PlayerControls.showPlayList.send(false)
                    }) {
                        Image(systemName: "xmark")
                            .tint(.fairyCream)
                    }
                }
            }
        }
    }

    private func remove(at offsets: IndexSet) {
        self.iaPlayer.removePlaylistItem(at: offsets)
        viewModel.items.remove(atOffsets: offsets)
    }
}

extension Playlist {
    final class ViewModel: ObservableObject {
        @Published var playingFile: ArchiveFile? = nil
        @Published var items: [ArchiveFile] = []

        var cancellables = Set<AnyCancellable>()

        public func setUpSubscribers(_ iaPlayer: Player) {
            iaPlayer.playingFilePublisher
                .sink { file in
                    self.playingFile = file
                }
                .store(in: &cancellables)

            iaPlayer.itemsPublisher
                .sink { files in
                    self.items = files
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

