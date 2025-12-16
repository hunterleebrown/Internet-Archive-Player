//
//  Lists.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 9/3/23.
//

import Foundation
import SwiftUI
import iaAPI
import Combine
import CoreData

struct ListsView: View {
    @StateObject var viewModel = ListsView.ViewModel()
    @EnvironmentObject var iaPlayer: Player

    var body: some View {
        NavigationStack {

            List {
                NavigationLink {
                    NewFavoritesView()
                }   label: {
                    HStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.fairyRed)
                            .font(.body)
                        Text("Favorites")
                            .foregroundColor(.fairyRed)
                            .fontWeight(.semibold)
                    }
                }

                ForEach(viewModel.lists, id: \.self) { list in
                    NavigationLink {
                        SingleListView(playlistEntity: list)
                    }   label: {
                        HStack(spacing: 12) {
                            if list.name == "Now Playing" {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.fairyRed)
                                    .font(.body)
                            } else {
                                Image(systemName: "music.note.list")
                                    .foregroundColor(.secondary)
                                    .font(.body)
                            }
                            Text(list.name ?? "Untitled Playlist")
                                .foregroundColor(list.name == "Now Playing" ? .fairyRed : .primary)
                                .fontWeight(list.name == "Now Playing" ? .semibold : .regular)
                        }
                    }
                }
                .onDelete { offsets in
                    viewModel.remove(at: offsets, player: iaPlayer)
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Playlists")
            .toolbar {
                Button(action: {
                    Home.newPlaylistPass.send(true)
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.fairyRed)
                    Text("Create Playlist")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Spacer()
                    .frame(height: iaPlayer.playerHeight)
            }
        }
    }
}

extension ListsView {

    @MainActor
    final class ViewModel: NSObject, ObservableObject {
        @Published var lists: [PlaylistEntity] = [PlaylistEntity]()
        private let listsFetchController: NSFetchedResultsController<PlaylistEntity>

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
                    if playlists.count > 0 {
                        self.lists = playlists.filter{!$0.permanent}
                    }
                }
            } catch {
                print("failed to fetch items!")
            }
        }


        func remove(at offsets: IndexSet, player: Player) {
            Task { @MainActor in
                for index in offsets {
                    let list = lists[index]
                    
                    // Step 1: Get all files from the playlist
                    guard let files = list.files?.array as? [ArchiveFileEntity] else {
                        // If no files, just delete the playlist
                        PersistenceController.shared.delete(list)
                        continue
                    }
                    
                    // Step 2: Delete all local files that are only in this playlist
                    var deletionErrors: [String] = []
                    
                    for item in files {
                        // Unset the playing file if this item is currently playing
                        player.unsetPlayingFile(entity: item)
                        
                        // Only attempt to delete if it's a local file
                        guard item.isLocalFile() else { continue }
                        
                        // Check if this file exists in other playlists
                        // Only delete the physical file if this is the only playlist using it
                        let isInOtherPlaylists = PersistenceController.shared.fileExistsInOtherPlaylists(item, excluding: list)
                        
                        if isInOtherPlaylists {
                            print("ℹ️ Skipping deletion of \(item.name ?? "unknown") - exists in other playlists")
                            continue
                        }
                        
                        // Verify the file actually exists before attempting deletion
                        guard let workingUrl = item.workingUrl,
                              FileManager.default.fileExists(atPath: workingUrl.path) else {
                            print("⚠️ Local file doesn't exist at expected path for: \(item.name ?? "unknown")")
                            continue
                        }
                        
                        // Attempt to delete the file
                        do {
                            try Downloader.removeFile(at: workingUrl)
                            print("✅ Successfully deleted local file: \(workingUrl.lastPathComponent)")
                        } catch {
                            let errorMessage = "Failed to delete \(item.name ?? "unknown"): \(error.localizedDescription)"
                            deletionErrors.append(errorMessage)
                            print("❌ \(errorMessage)")
                        }
                    }
                    
                    // Step 3: Delete the playlist from Core Data
                    // This happens regardless of whether file deletion succeeded
                    // (to avoid orphaned playlists in the database)
                    PersistenceController.shared.delete(list)
                    
                    // Step 4: Clean up orphaned ArchiveFileEntity objects
                    // (if your Core Data relationship is set to Nullify)
                    PersistenceController.shared.cleanupOrphanedFiles(from: files)
                    
                    // Step 5: Log any errors that occurred
                    if !deletionErrors.isEmpty {
                        print("⚠️ Playlist deleted but some files could not be removed:")
                        deletionErrors.forEach { print("  - \($0)") }
                    }
                }
            }
        }
    }

}

extension ListsView.ViewModel: NSFetchedResultsControllerDelegate {
    nonisolated func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let playlists = controller.fetchedObjects as? [PlaylistEntity]
        else { return }
        
        if playlists.count > 0 {
            let filteredPlaylists = playlists.filter{!$0.permanent}
            Task { @MainActor in
                self.lists = filteredPlaylists
            }
        }
    }
}

#Preview {
    ListsView()
}
