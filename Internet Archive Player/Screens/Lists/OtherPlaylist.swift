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
    var archiveFiles: [ArchiveFile]?
    var archiveFileEntities: [ArchiveFileEntity]?
    @ObservedObject var viewModel = OtherPlaylist.ViewModel()
    @State var showingNewPlaylist = false
    @EnvironmentObject var iaPlayer: Player

    init(isPresented: Binding<Bool>, archiveFiles: [ArchiveFile]? = nil, archiveFileEntities: [ArchiveFileEntity]? = nil) {
        self._isPresented = isPresented
        self.archiveFiles = archiveFiles
        self.archiveFileEntities = archiveFileEntities
    }

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Add to playlist")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.fairyRed)
                        .padding(10)
                    Spacer()
                    Button(action: {
                    }) {
                        NavigationLink {
                            NewPlaylist(isPresented: $showingNewPlaylist)
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(.fairyRed)

                        }
                    }
                }
                .padding()
                List {
                    ForEach(viewModel.lists, id: \.self) { list in
                        HStack {
                            Text(list.name ?? "list name")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let files = archiveFiles {
                                viewModel.addFilesToPlaylist(archiveFiles: files, playlist: list)
                            }
                            if let entityFiles = archiveFileEntities {
                                    viewModel.addFilesToPlaylist(archiveEntityFiles: entityFiles, playlist: list)

                            }
                            isPresented = false
                        }
                    }
                }
                .onAppear(perform: {
                    viewModel.getOtherLists()
                })
                .listStyle(PlainListStyle())
            }
        }
        .safeAreaInset(edge: .bottom) {
            Spacer()
                .frame(height: iaPlayer.playerHeight)
        }
    }
}

extension OtherPlaylist {

    final class ViewModel: NSObject, ObservableObject {

        @Published var lists: [PlaylistEntity] = [PlaylistEntity]()
        private let listsFetchController: NSFetchedResultsController<PlaylistEntity>


        public func addFilesToPlaylist(archiveFiles: [ArchiveFile], playlist: PlaylistEntity) {

            let sorted = archiveFiles.sorted{
                guard let track1 = Int($0.track ?? ""), let track2 = Int($1.track ?? "") else { return false}
                return track1 < track2
            }

            sorted.forEach { f in
                do {
                    try PersistenceController.shared.appendPlaylistItem(file: f, playList: playlist)
                } catch (let error) {
                    print(error)
                }
            }
        }

        public func addFilesToPlaylist(archiveEntityFiles: [ArchiveFileEntity], playlist: PlaylistEntity) {

            let sorted = archiveEntityFiles.sorted{
                guard let track1 = Int($0.track ?? ""), let track2 = Int($1.track ?? "") else { return false}
                return track1 < track2
            }

            sorted.forEach { f in
                do {
                    try PersistenceController.shared.appendPlaylistItem(archiveFileEntity: f, playList: playlist)

                } catch (let error) {
                    print(error)
                }

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
        }

        func getOtherLists() {
            do {
                try listsFetchController.performFetch()
                if let playlists = listsFetchController.fetchedObjects {
                    if playlists.count > 0 {
                        self.lists = playlists  //.filter{!$0.permanent}
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
                self.lists = playlists //.filter{!$0.permanent}
            }
        }
    }
}
