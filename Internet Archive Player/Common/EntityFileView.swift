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

    @StateObject var viewModel: EntityFileView.ViewModel = EntityFileView.ViewModel()

    var archiveFile: ArchiveFileEntity
    var textColor = Color.white
    var backgroundColor: Color? = Color.gray
    var showImage: Bool = false
    @State var showDownloadButton = true
    var fileViewMode: FileViewMode = .detail
    var ellipsisAction: (()->())? = nil

    init(_ archiveFile: ArchiveFileEntity,
         showImage: Bool = false,
         backgroundColor: Color? = Color.fairyRedAlpha,
         textColor: Color = Color.fairyCream,
         fileViewMode: FileViewMode = .detail,
         ellipsisAction: (()->())? = nil){

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
                    Text(archiveFile.format ?? "")
                        .font(.caption2)
                        .foregroundColor(textColor)
                        .bold()
                    Text("· \(archiveFile.calculatedSize ?? "\"\"") mb")
                        .font(.caption2)
                        .foregroundColor(textColor)
                        .bold()
                    Text("· \(archiveFile.displayLength ?? "")")
                        .font(.caption2)
                        .foregroundColor(textColor)
                        .bold()
                    Image(systemName: showDownloadButton ? "cloud" : "arrow.down.square.fill")
                        .font(.caption2)
                    Text(showDownloadButton ? "can be streamed" : "is a local file")
                        .font(.caption2)
                        .foregroundColor(textColor)
                }



                if viewModel.downloadProgress > 0 &&
                    viewModel.downloadProgress < 1 &&
                    !archiveFile.isLocalFile() {
                    ProgressView("Downloading", value: viewModel.downloadProgress, total:1)
                        .tint(.fairyRed)
                        .font(.caption2)
                }
            }
            .padding(5.0)
            Spacer()
            HStack() {
                Menu {
                    if (showDownloadButton) {
                        Button(action: {
                            archiveFile.download(delegate: viewModel)
                        }) {
                            Image(systemName: "icloud.and.arrow.down")
                                .aspectRatio(contentMode: .fill)
                                .foregroundColor(textColor)
                            Text("Download")
                        }
                        .frame(width: 44, height: 44)
                    }

                    Button(action: {
                        PlayerControls.showPlayingDetails.send(archiveFile)
                    }){
                        HStack {
                            Image(systemName: "info.circle")
                            Text("Archive Details")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(textColor)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 33, height: 33)
                }
                .highPriorityGesture(TapGesture())
            }
            .tint(textColor)
            .padding(5.0)
        }
        .background(backgroundColor ?? nil)
        .cornerRadius(5.0)
        .onReceive(Downloader.downloadedSubject) { file in
            guard file.id == archiveFile.id else { return }
            showDownloadButton = false
        }
        .onAppear() {
            showDownloadButton = !archiveFile.isLocalFile()
        }
    }
}

extension EntityFileView {
    public class ViewModel: ObservableObject, FileViewDownloadDelegate {
        @Published var downloadProgress = 0.0
    }
}
