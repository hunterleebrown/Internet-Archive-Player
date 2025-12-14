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

    @Environment(\.colorScheme) var colorScheme // Access the color scheme

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
        
        HStack() {
            if (showImage) {
                AsyncImage(
                    url: archiveFile.iconUrl,
                    content: { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 44,
                                   maxHeight: 44)
                            .background(Color.black)

                    },
                    placeholder: {
                        Color(.black)
                            .frame(maxWidth: 44,
                                   maxHeight: 44)
                    })
                    .cornerRadius(5)
                    .padding(5)
            }

            Spacer()
            VStack(alignment: .leading, spacing: 0) {
                Text(archiveFile.displayTitle)
                    .bold()
                    .font(.caption)
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)

                if fileViewMode == .playlist {
                    Text(archiveFile.archiveTitle ?? "")
                        .font(.caption2)
                        .foregroundColor(textColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }

                HStack(alignment: .center, spacing: 5) {

                    Image(systemName: archiveFile.isVideo ? "video" : "hifispeaker")
                        .tint(.black)
                        .font(.caption2)

                    Text("· \(archiveFile.calculatedSize ?? "\"\"") mb")
                        .font(.caption2)
                        .foregroundColor(textColor)
                        .bold()
                    Text("· \(archiveFile.displayLength ?? "")")
                        .font(.caption2)
                        .foregroundColor(textColor)
                        .bold()
                    Image(systemName: viewModel.showDownloadButton ? "cloud" : "iphone")
                        .font(.caption2)
                    Text(viewModel.showDownloadButton ? "online" : "downloaded")
                        .font(.caption2)
                        .foregroundColor(textColor)
                }

                if viewModel.downloadProgress > 0 &&
                    viewModel.downloadProgress < 1 &&
                    !archiveFile.isLocalFile() {
                    ProgressView("Downloading", value: viewModel.downloadProgress, total:1)
                        .tint(textColor)
                        .font(.caption2)
                }
            }
            .padding(5.0)
            Spacer()
            HStack() {

                    Menu {

                        ForEach(self.ellipsisAction, id: \.self) { menuItem in
                            Button(action: {
                                menuItem.action()
                            }){
                                HStack {
                                    if let imageName = menuItem.imageName {
                                        Image(systemName: imageName)
                                            .aspectRatio(contentMode: .fill)
                                            .foregroundColor(textColor)
                                    }
                                    Text(menuItem.name)
                                }
                            }
                            .frame(width: 44, height: 44)

                        }

                        if (viewModel.showDownloadButton && archiveFile.format == "VBR MP3") {
                            Button(action: {
                                archiveFile.download(delegate: viewModel)
                            }) {
                                Image(systemName: "icloud.and.arrow.down")
                                    .aspectRatio(contentMode: .fill)
                                    .foregroundColor(textColor)
                                Text("Download")
                            }
                            .frame(width: 44, height: 44)
                        } else {
                            Button(action: {
                                do {
                                    try Downloader.removeDownload(file: archiveFile)
                                } catch let error {
                                    print("Remove download error: \(error)")
                                }
                            }) {
                                Image(systemName: "folder.badge.minus")
                                    .aspectRatio(contentMode: .fill)
                                    .foregroundColor(textColor)
                                Text("Remove download")
                            }
                            .frame(width: 44, height: 44)
                        }


                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(textColor)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                    }
                    .highPriorityGesture(TapGesture())
            }
            .padding(5.0)
        }
        .listRowSeparator(.visible) // Hides the separator for this row
        .background(
            RoundedRectangle(
                cornerRadius: 5,
                style: .continuous
            )
            .fill(backgroundColor ?? (colorScheme == .dark ? Color.droopy : Color.white))
        )
        .padding(10)
        .onReceive(Downloader.downloadedSubject) { file in
            guard file.id == archiveFile.id else { return }
            viewModel.showDownloadButton = !file.isLocalFile()
        }
        .onAppear() {
            viewModel.showDownloadButton = !archiveFile.isLocalFile()
            viewModel.fetchDownloadUrl(for: archiveFile)
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
