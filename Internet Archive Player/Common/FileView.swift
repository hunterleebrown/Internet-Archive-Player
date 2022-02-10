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
    var iaFile: IAFile?
    var textColor = Color.white
    var auxControls = true
    
    init(_ file: IAFile){
        iaFile = file
    }
    
    var body: some View {
        
        HStack() {
            VStack() {
                let title = fileTitle(iaFile)
                
                if let name = iaFile?.name {
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
                
                if let name = iaFile?.name {
                    if title != name {
                        Text(iaFile?.name ?? "")
                            .font(.caption2)
                            .foregroundColor(textColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(5.0)
            if (auxControls) {
                Spacer()
                HStack() {
                    VStack(alignment:.leading) {
                        Text("\(iaFile?.calculatedSize ?? "\"\"") mb")
                            .font(.caption2)
                            .foregroundColor(textColor)
                        Text(iaFile?.displayLength ?? "")
                            .font(.caption2)
                            .foregroundColor(textColor)
                    }
                    
                    Button(action: {
                    }) {
                        Image(systemName: "icloud.and.arrow.down")
                            .accentColor(textColor)
                            .aspectRatio(contentMode: .fill)
                    }
                    .frame(width: 44, height: 44)
                    
                    Button(action: {
                    }) {
                        Image(systemName: "ellipsis")
                            .accentColor(textColor)
                            .aspectRatio(contentMode: .fill)
                    }
                    .frame(width: 44, height: 44)
                }
                .padding(5.0)
            }
        }
        .background(Color.gray)
        .cornerRadius(5.0)
        //        .overlay(
        //            Rectangle()
        //                .foregroundColor(Color.white)
        //        )
    }
    
    private func fileTitle(_ iaFile: IAFile?) -> String {
        return iaFile?.displayName ?? iaFile?.title ?? iaFile?.name ?? ""
    }
    
}
