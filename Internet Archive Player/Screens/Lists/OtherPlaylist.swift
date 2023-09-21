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
import CoreData

struct OtherPlaylist: View {
    @Binding var isPresented: Bool
    var archiveFile: ArchiveFile?
    var archiveFileEntity: ArchiveFileEntity?
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
                ForEach(viewModel.lists, id: \.self) { list in
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

        @Published var lists: [PlaylistEntity] = [PlaylistEntity]()
        private let listsFetchController: NSFetchedResultsController<PlaylistEntity>


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


        override init() {
            listsFetchController =
            NSFetchedResultsController(fetchRequest:  PlaylistEntity.fetchRequestAllPlaylists(),
                                       managedObjectContext: PersistenceController.shared.container.viewContext,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)

            super.init()
            listsFetchController.delegate = self

            do {
                try listsFetchController.performFetch()
                if let playlists = listsFetchController.fetchedObjects {
                    DispatchQueue.main.async {
                        if playlists.count > 0 {
                            self.lists = playlists.filter{!$0.permanent}
                        }
                    }
                }
            } catch {
                print("failed to fetch items!")
            }
        }
    }

}

extension OtherPlaylist.ViewModel: NSFetchedResultsControllerDelegate {
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
      guard let playlists = controller.fetchedObjects as? [PlaylistEntity]
      else { return }
      DispatchQueue.main.async {
          if playlists.count > 0 {
              self.lists = playlists.filter{!$0.permanent}
          }
      }
  }
}
