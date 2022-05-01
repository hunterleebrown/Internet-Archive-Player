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
                    ForEach(iaPlayer.items, id: \.self) { archiveFile in
                        EntityFileView(archiveFile,
                                 showImage: true,
                                 showDownloadButton: true,
                                 backgroundColor: archiveFile.url?.absoluteURL == viewModel.playingFile?.url?.absoluteURL ? .fairyRed : nil,
                                 textColor: archiveFile.url?.absoluteURL == viewModel.playingFile?.url?.absoluteURL ? .fairyCream : .droopy,
                                 fileViewMode: .playlist)
                        .onTapGesture {
                            iaPlayer.playFile(archiveFile)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .padding(0)
                        .listRowBackground(Color.white)
                        .tint(.droopy)
                    }
                    .onDelete(perform: self.remove)
                    .onMove(perform: self.move)
                }
                .listStyle(PlainListStyle())
                .tint(.droopy)
                .background(Color.white)
                .padding(0)
            }
            .padding(10)
            .modifier(BackgroundColorModifier(backgroundColor: .white))
            .onAppear() {
                viewModel.setUpSubscribers(iaPlayer)
                iaPlayer.sendPlayingFileForPlaylist()
                iaPlayer.sendItemsPlaylist()
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    EditButton()
                        .tint(.droopy)

                    Button(action: {
                        showingAlert = true
                    }) {
                        Image(systemName: "trash")
                        .foregroundColor(.droopy)
                    }
                    .alert("Are you sure you want to delete the playlist?", isPresented: $showingAlert) {
                        Button("No", role: .cancel) { }
                        Button("Yes") {
                            iaPlayer.clearPlaylist()
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Playlist")
            .navigationBarColor(backgroundColor: UIColor(white: 1.0, alpha: 0.5), titleColor: .black)
        }
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

