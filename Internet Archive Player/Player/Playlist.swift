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
                                 backgroundColor: archiveFile == viewModel.playingFile ? .droopy : nil,
                                 textColor: archiveFile == viewModel.playingFile ? .fairyCream : .droopy,
                                 fileViewMode: .playlist)
                        .onTapGesture {
                            iaPlayer.playFile(archiveFile)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .padding(0)
                        .listRowBackground(Color.white)
                        .accentColor(.droopy)
                        .tint(.droopy)
                    }
                    .onDelete(perform: self.remove)
                    .onMove(perform: self.move)
                }
                .listStyle(PlainListStyle())
                .accentColor(.droopy)
                .background(Color.white)
                .padding(0)
            }
            .padding(10)
            .modifier(BackgroundColorModifier(backgroundColor: .white))
            .navigationTitle("Playlist")
            .navigationBarColor(backgroundColor: .white, titleColor: IAColors.droopy)
            .onAppear() {
                viewModel.setUpSubscribers(iaPlayer)
                iaPlayer.sendPlayingFileForPlaylist()
                iaPlayer.sendItemsPlaylist()
            }
            .toolbar {
                HStack {
                    EditButton()
                        .accentColor(.droopy)

                    Button(action: {
                        showingAlert = true
                    }) {
                        Image(systemName: "trash")
                        .foregroundColor(.droopy)
                    }
                    .alert("Are you sure you want to delete the playlist?", isPresented: $showingAlert) {
                        Button("No", role: .cancel) { }
                        Button("Yes") {
                            viewModel.items.removeAll()
                            iaPlayer.clearPlaylist()
                        }
                    }

                    Button( action: {
                        PlayerControls.showPlayList.send(false)
                    }){
                        Image(systemName: "xmark")
                            .foregroundColor(.droopy)
                    }
                }
            }
        }
    }

    private func remove(at offsets: IndexSet) {
        self.iaPlayer.removePlaylistItem(at: offsets)
        viewModel.items.remove(atOffsets: offsets)
    }

    private func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        self.viewModel.items.move(fromOffsets: source, toOffset: destination)
        self.iaPlayer.rearrangePlaylist(fromOffsets: source, toOffset: destination)
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

