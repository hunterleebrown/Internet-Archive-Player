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
                               backgroundColor: .white,
                               textColor: .black,
                               fileViewMode: .playlist,
                               ellipsisAction: self.menuItems(archiveFileEntity: archiveFile))
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .padding(10)
                .onTapGesture {
//                    if let playingList = iaPlayer.mainPlaylist {
//                        if playingList != playlistEntity {
//                            iaPlayer.changePlaylist(newPlaylist: playlistEntity)
//                        }
//                    }
                    iaPlayer.playFile(archiveFile)
                }
            }
        }
        .listStyle(PlainListStyle())
        .navigationTitle(playlistEntity.name ?? "List")
    }

    private func menuItems(archiveFileEntity: ArchiveFileEntity) -> [MenuAction] {
        var items = [MenuAction]()

        let details = MenuAction(name: "Archive details", action:  {
            PlayerControls.showPlayingDetails.send(archiveFileEntity)
        }, imageName: "info.circle")

        items.append(details)

        return items
    }
}
