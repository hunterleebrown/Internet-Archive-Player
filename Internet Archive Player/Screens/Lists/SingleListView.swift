//
//  SingleList.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 9/4/23.
//

import Foundation
import SwiftUI
import iaAPI
import CoreData
import CoreData
import Combine

struct SingleListView: View {

    @ObservedObject var playlistEntity: PlaylistEntity
    @EnvironmentObject var iaPlayer: Player
    @StateObject var viewModel = SingleListView.ViewModel()

    init(playlistEntity: PlaylistEntity) {
        _playlistEntity = ObservedObject(initialValue: playlistEntity)
    }

    var body: some View {
        List {
            ForEach(viewModel.files, id: \.self) { archiveFile in

                EntityFileView(archiveFile,
                               showImage: true,
                               backgroundColor: archiveFile.url?.absoluteURL == viewModel.playingFile?.url?.absoluteURL ? .fairyRedAlpha : nil,
                               textColor: archiveFile.url?.absoluteURL == viewModel.playingFile?.url?.absoluteURL ? .fairyCream : .primary,
                               fileViewMode: .playlist,
                               ellipsisAction: self.menuItems(archiveFileEntity: archiveFile))
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .onTapGesture {
                    iaPlayer.playFileFromPlaylist(archiveFile, playlist: playlistEntity)
                }
            }
            .onDelete(perform: { indexSet in
                self.remove(at: indexSet)
            })
            .onMove(perform: self.move)
        }
        .toolbar {
            EditButton()
                .tint(.fairyRed)
        }
        .listStyle(PlainListStyle())
        .navigationTitle(playlistEntity.name ?? "List")
        .safeAreaInset(edge: .bottom) {
            Spacer()
                .frame(height: iaPlayer.playerHeight)
        }
        .onAppear {
            viewModel.setUpSubscribers(iaPlayer)
            viewModel.loadFiles(from: playlistEntity)
            iaPlayer.sendPlayingFileForPlaylist()
        }
        .onChange(of: playlistEntity.files) { _, _ in
            viewModel.loadFiles(from: playlistEntity)
        }
    }

    private func remove(at offsets: IndexSet) {
        viewModel.removeFiles(at: offsets, from: playlistEntity, player: iaPlayer)
    }

    private func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        viewModel.moveFiles(fromOffsets: source, toOffset: destination, in: playlistEntity)
    }

    private func menuItems(archiveFileEntity: ArchiveFileEntity) -> [MenuAction] {
        var items = [MenuAction]()

        let details = MenuAction(name: "Archive details", action:  {
            PlayerControls.showPlayingDetails.send(archiveFileEntity)
        }, imageName: "info.circle")
        items.append(details)

        let otherPlaylist = MenuAction(name: "Add to playlist ...", action:  {
            Home.otherPlaylistPass.send(archiveFileEntity)
        }, imageName: "music.note.list")
        items.append(otherPlaylist)

        return items
    }
}

extension SingleListView {
    final class ViewModel: ObservableObject {
        @Published var playingFile: ArchiveFileEntity? = nil
        @Published var files: [ArchiveFileEntity] = []

        var cancellables = Set<AnyCancellable>()

        public func setUpSubscribers(_ iaPlayer: Player) {
            iaPlayer.playingFilePublisher
                .sink { file in
                    self.playingFile = file
                }
                .store(in: &cancellables)
        }
        
        public func loadFiles(from playlist: PlaylistEntity) {
            files = playlist.files?.array as? [ArchiveFileEntity] ?? []
        }
        
        public func removeFiles(at offsets: IndexSet, from playlist: PlaylistEntity, player: Player) {
            // Use the Player's method which handles cleanup properly
            // This will trigger a Core Data change, which we'll pick up in onChange
            player.removeListItem(list: playlist, at: offsets)
        }
        
        public func moveFiles(fromOffsets source: IndexSet, toOffset destination: Int, in playlist: PlaylistEntity) {
            // First update the local array to keep UI in sync immediately
            files.move(fromOffsets: source, toOffset: destination)
            
            // Then update Core Data
            playlist.moveObject(indexes: source, toIndex: destination)
            PersistenceController.shared.save()
        }
    }
}

#Preview {
    SingleListView(playlistEntity: PlaylistEntity.firstEntity(context: PersistenceController.shared.container.viewContext) as! PlaylistEntity)
        .environmentObject(Player())
}
