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
    @State var favoritesErrorAlertShowing: Bool = false

    @State private var searchText = ""

    var filteredResorts: [ArchiveFileEntity] {
        if searchText.isEmpty {
            return iaPlayer.mainPlaylist?.files?.array as? [ArchiveFileEntity] ?? []
        } else {

            guard let files = iaPlayer.mainPlaylist?.files?.array as? [ArchiveFileEntity] else { return [] }

            return files.filter {
                guard let archiveTitle = $0.archiveTitle else { return false }
                let title = "\($0.displayTitle)\(archiveTitle)"
                return title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        List{
            ForEach(filteredResorts, id: \.self) { archiveFile in
                EntityFileView(archiveFile,
                               showImage: true,
                               backgroundColor: archiveFile.url?.absoluteURL == viewModel.playingFile?.url?.absoluteURL ? .fairyRedAlpha : nil,
                               textColor: archiveFile.url?.absoluteURL == viewModel.playingFile?.url?.absoluteURL ? .fairyCream : .primary,
                               fileViewMode: .playlist,
                               ellipsisAction: self.menuItems(archiveFileEntity: archiveFile))
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .onTapGesture {
                    if let playlist = iaPlayer.mainPlaylist {
                        iaPlayer.playFileFromPlaylist(archiveFile, playlist: playlist)
                    }
                }
                .padding(.horizontal, 5)
            }
            .onDelete(perform: self.remove)
            .onMove(perform: self.move)
        }
        .alert(PlayerError.alreadyOnFavorites.description, isPresented: $favoritesErrorAlertShowing) {
            Button("Okay", role: .cancel) { }
        }
        .toolbar {
            EditButton()
                .tint(.fairyRed)
            Button(action: {
                showingAlert = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.fairyRed)
            }
            .alert("Are you sure you want to delete the playlist?", isPresented: $showingAlert) {
                Button("No", role: .cancel) { }
                Button("Yes") {
                    iaPlayer.clearPlaylist()
                }
            }
        }
        .searchable(text: $searchText, prompt: "Filter")
        .listStyle(PlainListStyle())
        .onAppear() {
            viewModel.setUpSubscribers(iaPlayer)
            iaPlayer.sendPlayingFileForPlaylist()
        }
        .tint(.fairyRed)

    }

    private func remove(at offsets: IndexSet) {
        self.iaPlayer.removeListItem(list: iaPlayer.mainPlaylist, at: offsets)
    }

    private func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        self.iaPlayer.rearrangeList(list: iaPlayer.mainPlaylist, fromOffsets: source, toOffset: destination)
    }

    private func menuItems(archiveFileEntity: ArchiveFileEntity) -> [MenuAction] {
        var items = [MenuAction]()

        let details = MenuAction(name: "Archive details", action:  {
            PlayerControls.showPlayingDetails.send(archiveFileEntity)
        }, imageName: "info.circle")
        items.append(details)


        let favorites = MenuAction(name: "Add to Favorites", action:  {
            do  {
                try iaPlayer.appendFavoriteItem(archiveFileEntity: archiveFileEntity)
            } catch PlayerError.alreadyOnFavorites {
                self.favoritesErrorAlertShowing = true
            } catch {

            }
        }, imageName: "heart")
        items.append(favorites)

        let otherPlaylist = MenuAction(name: "Add to playlist ...", action:  {
            Home.otherPlaylistPass.send(archiveFileEntity)
        }, imageName: "music.note.list")
        items.append(otherPlaylist)

        return items
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
        Playlist().environmentObject(Player())
    }
}

