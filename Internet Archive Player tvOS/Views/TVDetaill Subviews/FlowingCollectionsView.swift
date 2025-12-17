//
//  FlowingCollectionsView.swift
//  Internet Archive Player tvOS
//
//  Created by Hunter Lee Brown on 10/28/23.
//

import SwiftUI
import iaAPI

struct FlowingCollectionsView: View {
    let collections: [Archive]
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(Array(collections.prefix(12).enumerated()), id: \.element.id) { index, archive in
                if let metadata = archive.metadata {
                    HStack(spacing: 8) {
                        // Collection thumbnail
                        AsyncImage(url: metadata.iconUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "folder")
                                        .font(.caption)
                                        .opacity(0.5)
                                )
                        }
                        
                        // Collection title
                        Text(metadata.archiveTitle ?? "Collection")
                            .font(.caption)
                            .opacity(0.9)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
            }
        }
    }
}
