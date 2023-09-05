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
    var archiveFile: ArchiveFile
    @StateObject var listViewModel = ListsView.ViewModel()
    @StateObject var viewModel = OtherPlaylist.ViewModel()

    init(isPresented: Binding<Bool>, archiveFile: ArchiveFile) {
        self._isPresented = isPresented
        self.archiveFile = archiveFile
    }

    var body: some View {
        List {
            ForEach(listViewModel.lists, id: \.self) { list in
                HStack {
                    Text(list.name ?? "list name")
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.addFileToPlaylist(archiveFile: archiveFile, playlist: list)
                    isPresented = false
                }
            }
            

        }
        .listStyle(PlainListStyle())
        .navigationTitle("Playlists")
    }
}

extension OtherPlaylist {

    final class ViewModel: NSObject, ObservableObject {

        public func addFileToPlaylist(archiveFile: ArchiveFile, playlist: PlaylistEntity) {
            do {
                try PersistenceController.shared.appendPlaylistItem(archiveFile, playList: playlist)
            } catch (let error) {
                print(error)
            }
        }
    }

}
