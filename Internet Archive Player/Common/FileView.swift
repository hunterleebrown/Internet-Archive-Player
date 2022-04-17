//
//  FileView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 2/10/22.
//

import Foundation
import SwiftUI
import iaAPI

enum FileViewMode {
    case detail
    case playlist
}


struct FileView: View {
    var archiveFile: ArchiveFile
    var textColor = Color.white
    var backgroundColor: Color? = Color.gray
    var showImage: Bool = false
    var showDownloadButton = true
    var fileViewMode: FileViewMode = .detail
    var ellipsisAction: (()->())? = nil

    init(_ archiveFile: ArchiveFile,
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
                        ProgressView()
                    })
                    .cornerRadius(5)
                    .padding(5)
            }

            Spacer()
            VStack() {
                let title = archiveFile.displayTitle

                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)

                if fileViewMode == .playlist {
                    Text(archiveFile.archiveTitle ?? "")
                        .font(.caption2)
                        .foregroundColor(textColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)

                    if let artist = archiveFile.artist {
                        Text(artist)
                            .font(.caption2)
                            .foregroundColor(textColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }

                    if let creator = archiveFile.creator {
                        Text(creator.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundColor(textColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }
                }


            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(5.0)
            Spacer()
            HStack() {
                VStack(alignment:.leading) {
                    Text(archiveFile.format?.rawValue ?? "")
                        .font(.caption2)
                        .foregroundColor(textColor)
                    Text("\(archiveFile.calculatedSize ?? "\"\"") mb")
                        .font(.caption2)
                        .foregroundColor(textColor)
                    Text(archiveFile.displayLength ?? "")
                        .font(.caption2)
                        .foregroundColor(textColor)
                }

                if (showDownloadButton) {

                    Button(action: {
                    }) {
                        Image(systemName: "icloud.and.arrow.down")
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .foregroundColor(textColor)
                    }
                    .frame(width: 44, height: 44)
                }

                if let ellipsisAction = ellipsisAction {
                    Menu {
                        Button(action: {
                            ellipsisAction()
                        }){
                            Text("Add to Playlist")
                        }
                        .frame(width: 44, height: 44)
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(textColor)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                    }
                    .highPriorityGesture(TapGesture())
                }
            }
            .accentColor(textColor)
            .padding(5.0)
        }
        .background(backgroundColor ?? nil)
        .cornerRadius(5.0)
    }
    
    private func fileTitle(_ iaFile: ArchiveFile?) -> String {
        return iaFile?.title ?? iaFile?.name ?? ""
    }
    
}

extension ArchiveFile {
    public var displayLength: String? {

        if let l = length {
            return IAStringUtils.timeFormatter(timeString: l)
        }
        return nil
    }

    public var calculatedSize: String? {

        if let s = size {
            if let rawSize = Int(s) {
                return IAStringUtils.sizeString(size: rawSize)
            }
        }
        return nil
    }

    public var iconUrl: URL {
        let itemImageUrl = "https://archive.org/services/img/\(identifier!)"
        return URL(string: itemImageUrl)!
    }

    public var displayTitle: String {
        return title ?? name ?? ""
    }
}
