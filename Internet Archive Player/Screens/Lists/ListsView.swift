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
    
    // Toggle this to test different layouts
    private let useCarouselLayout = true

    var body: some View {
        if useCarouselLayout {
            PlaylistsCarouselView(viewModel: viewModel)
                .environmentObject(iaPlayer)
        } else {
            PlaylistsListView(viewModel: viewModel)
                .environmentObject(iaPlayer)
        }
    }
}

// MARK: - List Layout (Original)
private struct PlaylistsListView: View {
    @ObservedObject var viewModel: ListsView.ViewModel
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
                    Home.newPlaylistPass.send(nil)
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

// MARK: - Carousel Layout (New)
private struct PlaylistsCarouselView: View {
    @ObservedObject var viewModel: ListsView.ViewModel
    @EnvironmentObject var iaPlayer: Player
    @State private var selectedPlaylistIndex = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    // Loading state
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.fairyRed)
                            .scaleEffect(1.5)
                        Text("Loading playlists...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Page-style carousel with embedded content
                    TabView(selection: $selectedPlaylistIndex) {
                        // Favorites card with embedded view
                        // Only render when favorites playlist is ready
                        if iaPlayer.favoritesPlaylist != nil {
                            FullPlaylistCard(
                                title: "Favorites",
                                icon: "heart.fill",
                                color: .fairyRed,
                                content: AnyView(NewFavoritesView()),
                                showDeleteButton: false
                            )
                            .tag(-1)
                        }
                        
                        // Playlist cards with embedded SingleListView
                        ForEach(Array(viewModel.lists.enumerated()), id: \.element) { index, list in
                            FullPlaylistCard(
                                title: list.name ?? "Untitled Playlist",
                                icon: list.name == "Now Playing" ? "play.circle.fill" : "music.note.list",
                                color: list.name == "Now Playing" ? .fairyRed : .secondary,
                                content: AnyView(SingleListView(playlistEntity: list, showToolbar: false)),
                                showDeleteButton: list.name != "Now Playing",
                                onDelete: {
                                    viewModel.remove(at: IndexSet(integer: index), player: iaPlayer)
                                },
                                playlistEntity: list
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                }
            }
            .navigationTitle("Playlists")
            .toolbar {
                Button(action: {
                    Home.newPlaylistPass.send(nil)
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

// MARK: - Full Playlist Card with Embedded Content
private struct FullPlaylistCard: View {
    let title: String
    let icon: String
    let color: Color
    let content: AnyView
    var showDeleteButton: Bool = false
    var onDelete: (() -> Void)? = nil
    var playlistEntity: PlaylistEntity? = nil  // Optional: pass the playlist to get the first item's image
    @EnvironmentObject var iaPlayer: Player
    
    @State private var showDeleteConfirmation = false
    
    // Get the first file's image URL from the playlist
    private var firstFileImageUrl: URL? {
        guard let playlist = playlistEntity,
              let files = playlist.files?.array as? [ArchiveFileEntity],
              let firstFile = files.first else {
            return nil
        }
        
        // Try to get the archive's icon URL from the identifier
        if let identifier = firstFile.identifier {
            // Construct the archive.org thumbnail URL
            return URL(string: "https://archive.org/services/img/\(identifier)")
        }
        
        return nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with icon/image, title, and gradient background
            HStack(alignment: .center, spacing: 12) {
                // Show first item's image or fallback to SF Symbol icon
                if let imageUrl = firstFileImageUrl {
                    CachedAsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } placeholder: {
                        // Fallback to icon while loading
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                            
                            ProgressView()
                                .tint(.white)
                        }
                    }
                } else {
                    // Default SF Symbol icon
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .minimumScaleFactor(0.5)
                    .lineLimit(2)
                
                Spacer()
                
                // Delete button in header
                if showDeleteButton, let _ = onDelete {
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .font(.body)
                    }
                }
            }
            .padding(10)

            Divider()
            
            // Embedded playlist content
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .confirmationDialog(
            "Delete Playlist",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete?()
            }
            Button("Cancel", role: .cancel) {
                // Dialog dismisses automatically
            }
        } message: {
            Text("Are you sure you want to delete \"\(title)\"? This action cannot be undone.")
        }
    }
}

extension ListsView {

    @MainActor
    final class ViewModel: NSObject, ObservableObject {
        @Published var lists: [PlaylistEntity] = [PlaylistEntity]()
        @Published var isLoading: Bool = true
        private let listsFetchController: NSFetchedResultsController<PlaylistEntity>

        override init() {
            listsFetchController =
            NSFetchedResultsController(fetchRequest:  PlaylistEntity.fetchRequestAllPlaylists(),
                                       managedObjectContext: PersistenceController.shared.container.viewContext,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)

            super.init()
            listsFetchController.delegate = self
            
            // Perform fetch asynchronously to avoid blocking the main thread
            Task { @MainActor in
                await self.performInitialFetch()
            }
        }
        
        private func performInitialFetch() async {
            // Perform the fetch on a background context to avoid blocking
            await Task.detached(priority: .userInitiated) {
                do {
                    // Create a background context
                    let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
                    let fetchRequest = PlaylistEntity.fetchRequestAllPlaylists()
                    
                    // Fetch on background thread
                    let playlists = try backgroundContext.fetch(fetchRequest)
                    let filteredPlaylists = playlists.filter { !$0.permanent }
                    
                    // Get object IDs to transfer to main context
                    let objectIDs = filteredPlaylists.map { $0.objectID }
                    
                    // Switch back to main thread to update UI
                    await MainActor.run {
                        // Convert object IDs to objects in the main context
                        self.lists = objectIDs.compactMap { objectID in
                            try? PersistenceController.shared.container.viewContext.existingObject(with: objectID) as? PlaylistEntity
                        }
                        self.isLoading = false
                        
                        // Now set up the main thread fetch controller for live updates
                        do {
                            try self.listsFetchController.performFetch()
                        } catch {
                            print("Failed to perform fetch on main controller: \(error)")
                        }
                    }
                } catch {
                    print("Failed to fetch playlists: \(error)")
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            }.value
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

