//
//  DebugView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 9/20/23.
//

import Foundation
import SwiftUI
import CoreData

struct DebugView: View {
    @EnvironmentObject var iaPlayer: Player
    @ObservedObject var viewModel: ViewModel = ViewModel()
    @State private var playerSkin: PlayerControlsSkin = .classic

    var body: some View {
        VStack(alignment: .leading, spacing: 10){
            HStack{
                Text("Player skin: ")
                    .foregroundColor(.fairyRed)
                Picker("Player Skin", selection: $playerSkin) {
                    ForEach(PlayerControlsSkin.allCases, id: \.self) {
                        Text($0.rawValue.capitalized)
                    }
                    .onChange(of: playerSkin) {
                        withAnimation {
                            iaPlayer.playerSkin = playerSkin
                        }
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Orphan cleanup section
            HStack {
                Text("Orphaned files: ")
                    .foregroundColor(.fairyRed)
                Text("\(viewModel.orphanedFiles.count)")
                Spacer()
                if viewModel.orphanedFiles.count > 0 {
                    Button("Clean Up Orphans") {
                        viewModel.cleanupOrphans()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.fairyRed)
                }
            }


            HStack{
                Text("Downloaded files: ")
                    .foregroundColor(.fairyRed)
                Text("\(viewModel.report?.files.count ?? 0)")
                Spacer()
                Text("\(viewModel.report?.totalSize() ?? 0) bytes")
            }
            

            List{
                ForEach(viewModel.localFiles) { archiveFile in
                    HStack(alignment: .top, spacing: 8) {
                        // Two-column property/value layout
                        VStack(alignment: .leading, spacing: 2) {
                            PropertyRow(property: "Archive Title", value: archiveFile.archiveTitle ?? "Unknown")
                            PropertyRow(property: "Identifier", value: archiveFile.identifier ?? "Unknown")
                            PropertyRow(property: "Title", value: archiveFile.displayTitle)
                            PropertyRow(property: "File Name", value: archiveFile.name ?? "")
                            PropertyRow(property: "Size", value: "\(archiveFile.calculatedSize ?? "") mb")
                            
                            // Show which playlists contain this file
                            let playlistNames = archiveFile.containingPlaylistNames()
                            if !playlistNames.isEmpty {
                                HStack(alignment: .top, spacing: 4) {
                                    Text("Playlists:")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .frame(width: 70, alignment: .leading)
                                    VStack(alignment: .leading, spacing: 1) {
                                        ForEach(playlistNames, id: \.self) { playlistName in
                                            Text(playlistName)
                                                .font(.system(size: 10))
                                                .foregroundColor(.primary)
                                        }
                                    }
                                }
                            } else {
                                PropertyRow(property: "Playlists", value: "None", valueColor: .orange)
                            }
                        }
                        
                        Spacer()
                        
                        Menu {
                            Button(role: .destructive) {
                                viewModel.removeDownload(file: archiveFile)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 30, height: 30)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                    .padding(.vertical, 2)
                }
                .onDelete { indexSet in
                    viewModel.removeDownloads(at: indexSet)
                }
            }
            .listStyle(PlainListStyle())
            .avoidPlayer()
        }
        .navigationTitle("Debug")
        .padding()
        .task{
            viewModel.startDownloadReport()
            viewModel.fetchLocalFiles()
            if let skin = iaPlayer.playerSkin {
                playerSkin = skin
            }
        }
    }

}

// Helper view for property/value rows
struct PropertyRow: View {
    let property: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text(property + ":")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.system(size: 10))
                .foregroundColor(valueColor)
        }
    }
}

extension DebugView {
    class ViewModel: ObservableObject {
        @Published var report: DownloadReport?
        @Published var localFiles: [ArchiveFileEntity] = []
        @Published var orphanedFiles: [ArchiveFileEntity] = []
        
        private let viewContext = PersistenceController.shared.container.viewContext
        
        func startDownloadReport() {
            report = Downloader.report()
        }
        
        func fetchLocalFiles() {
            let fetchRequest: NSFetchRequest<ArchiveFileEntity> = ArchiveFileEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            do {
                let allFiles = try viewContext.fetch(fetchRequest)
                localFiles = allFiles.filter { $0.isLocalFile() }
                
                // Identify orphaned files (local files not in any playlist)
                orphanedFiles = localFiles.filter { file in
                    !PersistenceController.shared.isOnPlaylist(entity: file)
                }
            } catch {
                print("Failed to fetch local files: \(error.localizedDescription)")
                localFiles = []
                orphanedFiles = []
            }
        }
        
        func cleanupOrphans() {
            // Use the PersistenceController's cleanupOrphans method
            PersistenceController.shared.cleanupOrphans()
            // Refresh after cleanup
            fetchLocalFiles()
            startDownloadReport()
        }
        
        func removeDownload(file: ArchiveFileEntity) {
            do {
                try Downloader.removeDownload(file: file)
                // Refresh the list after removal
                fetchLocalFiles()
                // Also refresh the download report
                startDownloadReport()
            } catch {
                print("Failed to delete download: \(error.localizedDescription)")
            }
        }
        
        func removeDownloads(at offsets: IndexSet) {
            for index in offsets {
                let file = localFiles[index]
                removeDownload(file: file)
            }
        }
    }
}
