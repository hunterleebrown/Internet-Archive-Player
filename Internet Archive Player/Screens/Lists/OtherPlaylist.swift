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
            VStack(spacing: 0) {
                // Header with title and new playlist button
                HStack {
                    Text("Add to Playlist")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.fairyRed)
                    Spacer()
                    NavigationLink {
                        NewPlaylist(isPresented: $showingNewPlaylist)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.fairyRed)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // List content
                List {
                    ForEach(viewModel.sortedLists, id: \.self) { list in
                        HStack(spacing: 12) {
                            // Special icons for Favorites and Now Playing
                            if list.name == "Favorites" {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.fairyRed)
                                    .font(.body)
                            } else if list.name == "Now Playing" {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.fairyRed)
                                    .font(.body)
                            } else {
                                Image(systemName: "music.note.list")
                                    .foregroundColor(.secondary)
                                    .font(.body)
                            }
                            
                            Text(list.name ?? "Untitled Playlist")
                                .font(.body)
                                .foregroundColor((list.name == "Favorites" || list.name == "Now Playing") ? .fairyRed : .primary)
                                .fontWeight((list.name == "Favorites" || list.name == "Now Playing") ? .semibold : .regular)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                .listStyle(PlainListStyle())
            }
            .onAppear {
                viewModel.getOtherLists()
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

        // Computed property to sort lists with Favorites first, then Now Playing, then alphabetically
        var sortedLists: [PlaylistEntity] {
            lists.sorted { list1, list2 in
                let isList1Favorites = list1.name == "Favorites"
                let isList2Favorites = list2.name == "Favorites"
                let isList1NowPlaying = list1.name == "Now Playing"
                let isList2NowPlaying = list2.name == "Now Playing"
                
                // Favorites always comes first
                if isList1Favorites && !isList2Favorites {
                    return true
                } else if !isList1Favorites && isList2Favorites {
                    return false
                }
                
                // Now Playing comes second (after Favorites)
                if isList1NowPlaying && !isList2NowPlaying {
                    return true
                } else if !isList1NowPlaying && isList2NowPlaying {
                    return false
                }
                
                // Otherwise sort alphabetically by name
                return (list1.name ?? "") < (list2.name ?? "")
            }
        }

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
