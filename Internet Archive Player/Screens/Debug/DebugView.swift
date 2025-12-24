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
                    HStack {
                        VStack(alignment: .leading) {
                            Text(archiveFile.identifier ?? "Unknown")
                                .font(.caption)
                                .bold()
                                .frame(alignment: .leading)
                            HStack(alignment: .top, spacing: 0){
                                Text(archiveFile.displayTitle)
                                    .font(.caption)
//                                Text(archiveFile.description)
//                                    .font(.caption2)
                                Spacer()
                                Text("\(archiveFile.calculatedSize ?? "") mb")
                                    .font(.caption)
                            }
                            Text(archiveFile.name ?? "")
                                .font(.caption)
                            
                            // Show which playlists contain this file
                            let playlistNames = archiveFile.containingPlaylistNames()
                            if !playlistNames.isEmpty {
                                VStack(alignment: .leading, spacing:2) {
                                    Text("Included in:")
                                        .font(.caption)
                                    ForEach(playlistNames, id: \.self) { playlistName in
                                        Text(playlistName)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text("Not in any playlist")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
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
                                .frame(width: 44, height: 44)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .padding(5)
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
