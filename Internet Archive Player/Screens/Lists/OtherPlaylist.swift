//
//  OtherPlaylist.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 9/4/23.
//

import Foundation
import iaAPI
import SwiftUI
import UIKit
import Combine

struct OtherPlaylist: View {
    @Binding var isPresented: Bool
    var archiveFile: ArchiveFile?
    var archiveFileEntity: ArchiveFileEntity?
    @StateObject var listViewModel = ListsView.ViewModel()
    @StateObject var viewModel = OtherPlaylist.ViewModel()

    init(isPresented: Binding<Bool>, archiveFile: ArchiveFile? = nil, archiveFileEntity: ArchiveFileEntity? = nil) {
        self._isPresented = isPresented
        self.archiveFile = archiveFile
        self.archiveFileEntity = archiveFileEntity
    }

    var body: some View {
        VStack {
            Text("Add to playlist")
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(.fairyRed)
                .padding(10)
            List {
                ForEach(listViewModel.lists, id: \.self) { list in
                    HStack {
                        Text(list.name ?? "list name")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let file = archiveFile {
                            viewModel.addFileToPlaylist(archiveFile: file, playlist: list)
                        }
                        if let entityFile = archiveFileEntity {
                            viewModel.addFileToPlaylist(archiveEntityFile: entityFile, playlist: list)
                        }
                        isPresented = false
                    }
                }


            }
            .listStyle(PlainListStyle())
            .navigationTitle("Playlists")
        }
    }
}

extension OtherPlaylist {

    final class ViewModel: NSObject, ObservableObject {

        public func addFileToPlaylist(archiveFile: ArchiveFile, playlist: PlaylistEntity) {
            do {
                try PersistenceController.shared.appendPlaylistItem(file: archiveFile, playList: playlist)
            } catch (let error) {
                print(error)
            }
        }

        public func addFileToPlaylist(archiveEntityFile: ArchiveFileEntity, playlist: PlaylistEntity) {
            do {
                try PersistenceController.shared.appendPlaylistItem(archiveFileEntity: archiveEntityFile, playList: playlist)
            } catch (let error) {
                print(error)
            }
        }

    }

}
