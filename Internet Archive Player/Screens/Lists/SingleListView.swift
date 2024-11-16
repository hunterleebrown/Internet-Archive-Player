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

    @State var playlistEntity: PlaylistEntity
    @EnvironmentObject var iaPlayer: Player
    @StateObject var viewModel = SingleListView.ViewModel()

    init(playlistEntity: PlaylistEntity) {
        _playlistEntity = State(initialValue: playlistEntity)
    }

    var body: some View {
        List {
            ForEach(playlistEntity.files?.array as? [ArchiveFileEntity] ?? [], id: \.self) { archiveFile in

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
            iaPlayer.sendPlayingFileForPlaylist()
        }
    }

    private func remove(at offsets: IndexSet) {
        for index in offsets {
            if let file = playlistEntity.files?.array[index] as? ArchiveFileEntity{
                playlistEntity.removeFromFiles(file)
                PersistenceController.shared.save()
            }
        }
    }

    private func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        self.iaPlayer.rearrangeList(list: playlistEntity, fromOffsets: source, toOffset: destination)
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

#Preview {
    SingleListView(playlistEntity: PlaylistEntity.firstEntity(context: PersistenceController.shared.container.viewContext) as! PlaylistEntity)
        .environmentObject(Player())
}
