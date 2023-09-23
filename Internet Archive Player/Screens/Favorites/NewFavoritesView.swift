//
//  NewFavoritesView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 7/6/23.
//

import SwiftUI
import iaAPI
import MediaPlayer
import AVFoundation
import AVKit
import Combine

struct NewFavoritesView: View {
    @EnvironmentObject var iaPlayer: Player
    @StateObject var viewModel = NewFavoritesView.ViewModel()
    @State private var seek = 1.0
    @State private var showingAlert = false

    @State var playlistErrorAlertShowing: Bool = false

    var body: some View {
        NavigationView {
            List{
                ForEach(iaPlayer.favoriteItems, id: \.self) { archiveFile in

                    EntityFileView(archiveFile,
                                   showImage: true,
                                   backgroundColor: archiveFile.url?.absoluteURL == viewModel.playingFile?.url?.absoluteURL ? .fairyRedAlpha : nil,
                                   textColor: archiveFile.url?.absoluteURL == viewModel.playingFile?.url?.absoluteURL ? .fairyCream : .primary,
                                   fileViewMode: .playlist,
                                   ellipsisAction: self.menuActions(archiveFile: archiveFile))
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .onTapGesture {
                        do {
                            try iaPlayer.appendAndPlay(archiveFile)
                        } catch PlayerError.alreadyOnPlaylist {
                            self.playlistErrorAlertShowing = true
                        } catch {

                        }

                    }
                    .padding(.horizontal, 10)
                }
                .onDelete(perform: self.remove)
                .onMove(perform: self.move)
            }
            .listStyle(PlainListStyle())
            .tint(.fairyRed)
            .safeAreaInset(edge: .bottom) {
                Spacer()
                    .frame(height: iaPlayer.playerHeight)
            }

        }
        .alert(PlayerError.alreadyOnPlaylist.description, isPresented: $playlistErrorAlertShowing) {
            Button("Okay", role: .cancel) { }
                .tint(Color.fairyRed)
        }
        .navigationTitle("Favorites")
        .onAppear() {
            viewModel.setUpSubscribers(iaPlayer)
            iaPlayer.sendPlayingFileForPlaylist()
        }
    }

    private func remove(at offsets: IndexSet) {
        self.iaPlayer.removeListItem(list: iaPlayer.favoritesPlaylist, at: offsets)
    }

    private func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        self.iaPlayer.rearrangeList(list: iaPlayer.favoritesPlaylist, fromOffsets: source, toOffset: destination)
    }

    private func menuActions(archiveFile: ArchiveFileEntity) -> [MenuAction] {
        var actions = [MenuAction]()

        let playlist = MenuAction(name: "Add to list", action:  {
            do  {
                try iaPlayer.appendPlaylistItem(archiveFileEntity: archiveFile)
            } catch PlayerError.alreadyOnPlaylist {
                self.playlistErrorAlertShowing = true
            } catch {
            }
        }, imageName: "list.bullet.rectangle.portrait")
        actions.append(playlist)

        let otherPlaylist = MenuAction(name: "Add to playlist ...", action:  {
            Home.otherPlaylistPass.send(archiveFile)
        }, imageName: "music.note.list")
        actions.append(otherPlaylist)


        return actions
    }
}

extension NewFavoritesView {
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


struct SwiftUIView_PreviewsFavorites: PreviewProvider {
    static var previews: some View {
        NewFavoritesView().environmentObject(Player())
    }
}

