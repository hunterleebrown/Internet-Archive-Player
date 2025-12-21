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

    @ObservedObject var playlistEntity: PlaylistEntity
    @EnvironmentObject var iaPlayer: Player
    @StateObject var viewModel = SingleListView.ViewModel()
    var showToolbar: Bool = true // Control toolbar visibility

    init(playlistEntity: PlaylistEntity, showToolbar: Bool = true) {
        _playlistEntity = ObservedObject(initialValue: playlistEntity)
        self.showToolbar = showToolbar
    }

    var body: some View {
        Group {
            if playlistEntity.managedObjectContext == nil {
                // Safety check: playlist entity not properly initialized
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.fairyRed)
                    Text("Loading playlist...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.files.isEmpty {
                // Empty state
                VStack(alignment: .center, spacing: 16) {
                    Spacer()
                        .frame(height: 80)
                    
                    Image(systemName: "music.note.list")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("Playlist is Empty")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.primary)
                    
                    Text("Add files from the Internet Archive to build your playlist")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.files, id: \.self) { archiveFile in

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
                .listStyle(PlainListStyle())
            }
        }
        .toolbar {
            if showToolbar && !viewModel.files.isEmpty {
                EditButton()
                    .tint(.fairyRed)
            }
        }
        .navigationTitle(playlistEntity.name ?? "List")
        .navigationBarTitleDisplayMode(.inline)
        .avoidPlayer()
        .task {
            viewModel.configure(player: iaPlayer)
            viewModel.loadFiles(from: playlistEntity)
            iaPlayer.sendPlayingFileForPlaylist()
        }
        .onChange(of: playlistEntity.files) { _, _ in
            viewModel.loadFiles(from: playlistEntity)
        }
    }

    private func remove(at offsets: IndexSet) {
        viewModel.removeFiles(at: offsets, from: playlistEntity)
    }

    private func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        viewModel.moveFiles(fromOffsets: source, toOffset: destination, in: playlistEntity)
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
        
        let delete = MenuAction(name: "Delete from playlist", action: {
            // Find the index of this file in the current playlist
            if let index = viewModel.files.firstIndex(of: archiveFileEntity) {
                self.remove(at: IndexSet(integer: index))
            }
        }, imageName: "trash")
        items.append(delete)

        return items
    }
}

extension SingleListView {
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var playingFile: ArchiveFileEntity? = nil
        @Published var files: [ArchiveFileEntity] = []
        
        weak var player: Player?
        var cancellables = Set<AnyCancellable>()
        
        func configure(player: Player) {
            self.player = player
            setUpSubscribers()
        }
        
        private func setUpSubscribers() {
            guard let player = player else { return }
            player.playingFilePublisher
                .sink { [weak self] file in
                    self?.playingFile = file
                }
                .store(in: &cancellables)
        }
        
        func loadFiles(from playlist: PlaylistEntity) {
            files = playlist.files?.array as? [ArchiveFileEntity] ?? []
        }
        
        func removeFiles(at offsets: IndexSet, from playlist: PlaylistEntity) {
            guard let player = player else { return }
            
            // Capture the entities to remove before modifying the array
            let entitiesToRemove = offsets.map { files[$0] }
            
            // Update the UI immediately by removing from the local array
            files.remove(atOffsets: offsets)
            
            // Then use the Player's method which handles Core Data cleanup properly
            // We pass the offsets which the Player will use on the actual playlist
            player.removeListItem(list: playlist, at: offsets)
            
            // Ensure the view model stays in sync after Core Data changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.loadFiles(from: playlist)
            }
        }
        
        func moveFiles(fromOffsets source: IndexSet, toOffset destination: Int, in playlist: PlaylistEntity) {
            // First update the local array to keep UI in sync immediately
            files.move(fromOffsets: source, toOffset: destination)
            
            // Then update Core Data
            playlist.moveObject(indexes: source, toIndex: destination)
            PersistenceController.shared.save()
        }
    }
}

#Preview {
    SingleListView(playlistEntity: PlaylistEntity.firstEntity(context: PersistenceController.shared.container.viewContext) as! PlaylistEntity)
        .environmentObject(Player())
}
