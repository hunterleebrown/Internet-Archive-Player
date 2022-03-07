//
//  FileView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 2/10/22.
//

import Foundation
import SwiftUI
import iaAPI

struct FileView: View {
    var playlistItem: PlaylistItem
    var textColor = Color.white
    var backgroundColor: Color? = Color.gray
    var showImage: Bool = false
    var showDownloadButton = true
    var ellipsisAction: (()->())? = nil

    init(_ playlistItem: PlaylistItem,
         showImage: Bool = false,
         showDownloadButton: Bool = true,
         backgroundColor: Color? = Color.fairyRedAlpha,
         textColor: Color = Color.fairyCream,
         ellipsisAction: (()->())? = nil){
        self.playlistItem = playlistItem
        self.showImage = showImage
        self.showDownloadButton = showDownloadButton
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.ellipsisAction = ellipsisAction
    }
    
    var body: some View {
        
        HStack() {
            if (showImage) {
                AsyncImage(
                    url: playlistItem.iconUrl,
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
                let title = fileTitle(playlistItem.file)
                
                if let name = playlistItem.file.name {
                    if title != name {
                        Text(title)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text(title)
                            .font(.caption2)
                            .foregroundColor(textColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                if let name = playlistItem.file.name {
                    if title != name {
                        Text(name)
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
                    Text("\(playlistItem.file.calculatedSize ?? "\"\"") mb")
                        .font(.caption2)
                        .foregroundColor(textColor)
                    Text(playlistItem.file.displayLength ?? "")
                        .font(.caption2)
                        .foregroundColor(textColor)
                }

                if (showDownloadButton) {
                    Button(action: {
                    }) {
                        Image(systemName: "icloud.and.arrow.down")
                            .accentColor(textColor)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                    }
                    .frame(width: 44, height: 44)
                    .accentColor(textColor)
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
                            .accentColor(textColor)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                    }
                    .highPriorityGesture(TapGesture())
                }


            }
            .padding(5.0)
        }
        .background(backgroundColor ?? nil)
        .cornerRadius(5.0)
        //        .overlay(
        //            Rectangle()
        //                .foregroundColor(Color.white)
        //        )
    }
    
    private func fileTitle(_ iaFile: IAFile?) -> String {
        return iaFile?.title ?? iaFile?.name ?? ""
    }
    
}

extension IAFile {
    public func copy() -> IAFile {
        return IAFile(name:self.name, title: self.title, track:self.track, size:self.size, rawFormat: self.format?.rawValue)
    }
}

extension IAArchiveDoc {
    public func copy() -> IAArchiveDoc {
        return IAArchiveDoc(metadata: self.metadata, files: self.files)
    }
}
