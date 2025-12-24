//
//  FileView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 2/10/22.
//

import Foundation
import SwiftUI
import iaAPI

public protocol FileViewDownloadDelegate {
    var downloadProgress: Double { get set }
}


struct EntityFileView: View {

    @Environment(\.colorScheme) var colorScheme

    @StateObject var viewModel: EntityFileView.ViewModel = EntityFileView.ViewModel()

    var archiveFile: ArchiveFileEntity
    var textColor = Color.white
    var backgroundColor: Color? = Color.gray
    var showImage: Bool = false
    var fileViewMode: FileViewMode = .detail
    var ellipsisAction: [MenuAction] = [MenuAction]()

    init(_ archiveFile: ArchiveFileEntity,
         showImage: Bool = false,
         backgroundColor: Color? = Color.fairyRedAlpha,
         textColor: Color = Color.fairyCream,
         fileViewMode: FileViewMode = .detail,
         ellipsisAction: [MenuAction] = [MenuAction]()){

        self.archiveFile = archiveFile
        self.showImage = showImage
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.ellipsisAction = ellipsisAction
        self.fileViewMode = fileViewMode
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail with fixed frame to prevent layout shifts
            if showImage {
                thumbnailView
            }
            
            // Main content
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(archiveFile.displayTitle)
                    .font(.subheadline)
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                
                // Archive title (in playlist mode)
                if fileViewMode == .playlist, let archiveTitle = archiveFile.archiveTitle {
                    Text(archiveTitle)
                        .font(.caption)
                        .foregroundColor(textColor.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                
                // Metadata row
                metadataView
                
                // Download progress
                if viewModel.downloadProgress > 0 &&
                    viewModel.downloadProgress < 1 &&
                    !archiveFile.isLocalFile() {
                    ProgressView("Downloading", value: viewModel.downloadProgress, total: 1)
                        .tint(textColor)
                        .font(.caption2)
                        .foregroundColor(textColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Menu button
            menuButton
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(backgroundColor ?? (colorScheme == .dark ? Color.droopy : Color.white))
        )
        .listRowSeparator(.visible)
        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .onReceive(Downloader.downloadedSubject) { file in
            guard file.id == archiveFile.id else { return }
            viewModel.showDownloadButton = !file.isLocalFile()
        }
        .task {
            viewModel.showDownloadButton = !archiveFile.isLocalFile()
            viewModel.fetchDownloadUrl(for: archiveFile)
        }
    }
    
    // MARK: - Subviews
    
    private var thumbnailView: some View {
        CachedAsyncImage(url: archiveFile.iconUrl) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipped()
        } placeholder: {
            Color.black
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: archiveFile.isVideo ? "video.fill" : "music.note")
                        .foregroundColor(textColor.opacity(0.5))
                        .font(.title3)
                )
        }
        .frame(width: 56, height: 56)
        .background(Color.black)
        .cornerRadius(6)
    }
    
    private var metadataView: some View {
        HStack(alignment: .center, spacing: 4) {
            // Media type icon
            Image(systemName: archiveFile.isVideo ? "video" : "hifispeaker")
                .font(.caption2)
                .foregroundColor(textColor.opacity(0.8))
            
            // File size
            if let size = archiveFile.calculatedSize {
                Text("·")
                    .font(.caption2)
                    .foregroundColor(textColor.opacity(0.6))
                Text(size + " MB")
                    .font(.caption2)
                    .foregroundColor(textColor.opacity(0.8))
            }
            
            // Duration
            if let duration = archiveFile.displayLength {
                Text("·")
                    .font(.caption2)
                    .foregroundColor(textColor.opacity(0.6))
                Text(duration)
                    .font(.caption2)
                    .foregroundColor(textColor.opacity(0.8))
            }
            
            // Download status
            Text("·")
                .font(.caption2)
                .foregroundColor(textColor.opacity(0.6))
            Image(systemName: viewModel.showDownloadButton ? "icloud" : "arrow.down.circle.fill")
                .font(.caption2)
                .foregroundColor(textColor.opacity(0.8))
            Text(viewModel.showDownloadButton ? "online" : "downloaded")
                .font(.caption2)
                .foregroundColor(textColor.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var menuButton: some View {
        Menu {
            // Custom menu items
            ForEach(ellipsisAction, id: \.self) { menuItem in
                Button(action: menuItem.action) {
                    Label(menuItem.name, systemImage: menuItem.imageName ?? "")
                }
            }
            
            // Share
            if let shareURL = archiveFile.shareURL {
                ShareLink(item: shareURL) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            
            Divider()
            
            // Download/Remove
            if viewModel.showDownloadButton && archiveFile.format == "VBR MP3" {
                Button(action: {
                    archiveFile.download(delegate: viewModel)
                }) {
                    Label("Download", systemImage: "icloud.and.arrow.down")
                }
            } else if !viewModel.showDownloadButton {
                Button(role: .destructive, action: {
                    do {
                        try Downloader.removeDownload(file: archiveFile)
                    } catch {
                        print("Remove download error: \(error)")
                    }
                }) {
                    Label("Remove Download", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(textColor)
                .font(.title3)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
    }
}

struct EntityFileView_Previews: PreviewProvider {
    static var previews: some View {
        if let file = ArchiveFileEntity.firstEntity(context: PersistenceController.shared.container.viewContext) as? ArchiveFileEntity {
            EntityFileView(file)
        }
    }
}

extension EntityFileView {
    public class ViewModel: ObservableObject, FileViewDownloadDelegate {
        @Published var downloadProgress = 0.0

        @Published var downloadUrl: URL?
        @Published var errorMessage: String?

        @Published var showDownloadButton = true

        func fetchDownloadUrl(for file: ArchiveFileEntity) {
            do {
                if let url = try Downloader.entityDownloadedUrl(entity: file) {
                    DispatchQueue.main.async {
                        self.downloadUrl = url
                        self.errorMessage = nil

                        file.url = url
                        PersistenceController.shared.save()

                        self.showDownloadButton = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "URL could not be retrieved."
                        self.downloadUrl = nil
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "An error occurred: \(error.localizedDescription)"
                    self.downloadUrl = nil
                }
            }
        }
    }
}
