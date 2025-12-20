//
//  HistoryDrawerView.swift
//  Internet Archive Player
//
//  Created on 12/14/24.
//

import SwiftUI
import CoreData

struct HistoryDrawerView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = ViewModel()
    @EnvironmentObject var iaPlayer: Player
    @State private var showClearAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("History")
                    .font(.title)
                    .foregroundColor(.fairyCream)
                    .bold()
                
                Spacer()
                
                // Clear history button
                if !viewModel.historyItems.isEmpty {
                    Button(action: {
                        showClearAlert = true
                    }) {
                        Text("Clear")
                            .font(.subheadline)
                            .foregroundColor(.fairyCream)
                    }
                    .padding(.trailing, 12)
                }                
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            // History items list
            if viewModel.historyItems.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "clock")
                        .font(.system(size: 60))
                        .foregroundColor(.fairyCream.opacity(0.5))
                    
                    Text("No History Yet")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.fairyCream)
                    
                    Text("Files you play will appear here")
                        .font(.subheadline)
                        .foregroundColor(.fairyCream.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.historyItems, id: \.stableID) { item in
                            HistoryItemRow(item: item) {
                                viewModel.playHistoryItem(item, player: iaPlayer)
                                isPresented = false
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            
                            if item.stableID != viewModel.historyItems.last?.stableID {
                                Divider()
                                    .background(Color.fairyCream.opacity(0.3))
                                    .padding(.leading, 76)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.fairyRed.opacity(0.95))
        .alert("Clear History", isPresented: $showClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                viewModel.clearHistory(player: iaPlayer)
            }
        } message: {
            Text("Are you sure you want to clear all play history? This cannot be undone.")
        }
        .task {
            viewModel.fetchHistory()
        }
    }
}

struct HistoryItemRow: View {
    let item: HistoryArchiveFileEntity
    let onPlay: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Thumbnail
            CachedAsyncImage(
                url: item.iconUrl,
                content: { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .background(Color.black)
                        .cornerRadius(5)
                },
                placeholder: {
                    Color.black
                        .frame(width: 50, height: 50)
                        .cornerRadius(5)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.fairyCream.opacity(0.5))
                        )
                }
            )
            .frame(width: 50, height: 50)
            
            // Title, artist, and timestamp
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.fairyCream)
                    .lineLimit(2)
                
                Text(item.displayArtist)
                    .font(.caption)
                    .foregroundColor(.fairyCream.opacity(0.8))
                    .lineLimit(1)
                
                // Compact timestamp with styled fonts
                Text(formattedTimestamp)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.fairyCream.opacity(0.6))
            }
            
            Spacer()
            
            // Play count badge
            VStack(spacing: 2) {
                Text("\(item.playCount)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.fairyCream)
                    .monospacedDigit()
                    .frame(minWidth: 30, minHeight: 34)
                    .padding(.horizontal, 4)
                    .background(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.fairyCream.opacity(0.4), lineWidth: 1.5)
                    )
                    .cornerRadius(4)
                
                Text("plays")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.fairyCream.opacity(0.7))
                    .textCase(.uppercase)
                    .kerning(0.5)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onPlay()
        }
    }
    
    // Compact single-line timestamp with bullets
    private var formattedTimestamp: String {
        guard let playedAt = item.playedAt else { return "----•---•--•--:--:-- --" }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        
        // Get individual components
        formatter.dateFormat = "yyyy"
        let year = formatter.string(from: playedAt)
        
        formatter.dateFormat = "MMM"
        let month = formatter.string(from: playedAt)
        
        formatter.dateFormat = "dd"
        let day = formatter.string(from: playedAt)
        
        formatter.dateFormat = "h:mm:ss a"
        let time = formatter.string(from: playedAt)
        
        return "\(year)•\(month)•\(day)•\(time)"
    }
}

// MARK: - ViewModel
extension HistoryDrawerView {
    @MainActor
    class ViewModel: ObservableObject {
        @Published var historyItems: [HistoryArchiveFileEntity] = []
        
        private let context = PersistenceController.shared.container.viewContext
        
        func fetchHistory() {
            let fetchRequest = HistoryArchiveFileEntity.historyFetchRequest
            
            do {
                historyItems = try context.fetch(fetchRequest)
            } catch {
                print("Error fetching history: \(error.localizedDescription)")
                historyItems = []
            }
        }
        
        func playHistoryItem(_ historyItem: HistoryArchiveFileEntity, player: Player) {
            guard let mainPlaylist = player.mainPlaylist else { return }
            guard let playlistFiles = mainPlaylist.files?.array as? [ArchiveFileEntity] else { return }
            
            // Check if an ArchiveFileEntity with matching identifier/name already exists in the playlist
            if let existingEntity = playlistFiles.first(where: { entity in
                entity.identifier == historyItem.identifier && entity.name == historyItem.name
            }) {
                // Play the existing entity
                player.playFileFromPlaylist(existingEntity, playlist: mainPlaylist)
            } else {
                // Create new ArchiveFileEntity from history item
                let newEntity = historyItem.toArchiveFileEntity(context: context)
                
                do {
                    // Add to playlist
                    try player.appendPlaylistItem(archiveFileEntity: newEntity)
                    
                    // Retrieve the saved entity from the playlist to ensure we use the managed object
                    if let savedEntity = playlistFiles.first(where: { entity in
                        entity.identifier == historyItem.identifier && entity.name == historyItem.name
                    }) {
                        player.playFileFromPlaylist(savedEntity, playlist: mainPlaylist)
                    } else {
                        // Fallback: play the newly created entity
                        player.playFileFromPlaylist(newEntity, playlist: mainPlaylist)
                    }
                } catch {
                    print("Error adding history item to playlist: \(error.localizedDescription)")
                }
            }
        }
        
        func clearHistory(player: Player) {
            // Stop playing if the currently playing file is in history
            // Find if any history item matches the currently playing file
            if let matchingItem = historyItems.first(where: { item in
                guard let playingFile = player.playingFile else { return false }
                return item.onlineUrl?.absoluteString == playingFile.onlineUrl?.absoluteString
            }) {
                player.unsetPlayingFile(entity: matchingItem)
            }
            
            // Delete all history items
            for item in historyItems {
                context.delete(item)
            }
            
            do {
                try context.save()
                historyItems = []
            } catch {
                print("Error clearing history: \(error.localizedDescription)")
            }
        }
    }
}

struct HistoryDrawerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.ignoresSafeArea()
            
            VStack {
                Spacer()
                HistoryDrawerView(isPresented: .constant(true))
                    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            }
        }
    }
}
