//
//  FileView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 2/10/22.
//

import Foundation
import SwiftUI
import iaAPI

struct EntityFileView: View {
    var archiveFile: ArchiveFileEntity
    var textColor = Color.white
    var backgroundColor: Color? = Color.gray
    var showImage: Bool = false
    var showDownloadButton = true
    var fileViewMode: FileViewMode = .detail
    var ellipsisAction: (()->())? = nil

    init(_ archiveFile: ArchiveFileEntity,
         showImage: Bool = false,
         showDownloadButton: Bool = true,
         backgroundColor: Color? = Color.fairyRedAlpha,
         textColor: Color = Color.fairyCream,
         fileViewMode: FileViewMode = .detail,
         ellipsisAction: (()->())? = nil){

        self.archiveFile = archiveFile
        self.showImage = showImage
        self.showDownloadButton = showDownloadButton
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

                HStack(alignment: .top, spacing: 5) {
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
                }

            }
            .padding(5.0)
            Spacer()
            HStack() {
                Menu {
                    if (showDownloadButton) {

                        Button(action: {
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
                }
                .highPriorityGesture(TapGesture())
            }
            .tint(textColor)
            .padding(5.0)
        }
        .background(backgroundColor ?? nil)
        .cornerRadius(5.0)
    }
}
