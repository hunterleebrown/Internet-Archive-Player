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

struct SingleListView: View {

    var playlistEntity: PlaylistEntity
    @EnvironmentObject var iaPlayer: Player

    var body: some View {
        List {
            ForEach(playlistEntity.files?.array as? [ArchiveFileEntity] ?? [], id: \.self) { archiveFile in

                EntityFileView(archiveFile,
                               showImage: true,
                               backgroundColor: nil,
                               textColor: .primary,
                               fileViewMode: .playlist,
                               ellipsisAction: self.menuItems(archiveFileEntity: archiveFile))
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .onTapGesture {
                    iaPlayer.playFile(archiveFile, newItems: playlistEntity.files?.array as? [ArchiveFileEntity] ?? [])
                }
            }
            .onDelete(perform: { indexSet in
                self.remove(at: indexSet)
            })
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
    }

    private func remove(at offsets: IndexSet) {
        for index in offsets {
            if let file = playlistEntity.files?.array[index] as? ArchiveFileEntity{
                playlistEntity.removeFromFiles(file)
                PersistenceController.shared.save()
            }
        }
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

#Preview {
    SingleListView(playlistEntity: PlaylistEntity.firstEntity(context: PersistenceController.shared.container.viewContext) as! PlaylistEntity)
        .environmentObject(Player())
}
