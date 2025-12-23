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
        VStack{
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
                                Spacer()
                                Text("\(archiveFile.calculatedSize ?? "") mb")
                                    .font(.caption)
                            }
                            Text(archiveFile.name ?? "")
                                .font(.caption)

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
            } catch {
                print("Failed to fetch local files: \(error.localizedDescription)")
                localFiles = []
            }
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
