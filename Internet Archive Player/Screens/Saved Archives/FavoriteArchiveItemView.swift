//
//  FavoriteArchiveItemView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/25/22.
//

import Foundation
import SwiftUI
import iaAPI

struct FavoriteArchiveItemView<Item: SearchItemDisplayable>: View {
    var item: Item
    var textColor: Color = .droopy
    
    // Fixed card dimensions for uniform grid
    private let imageHeight: CGFloat = 140
    private let contentHeight: CGFloat = 110
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image at top - larger and more prominent
            AsyncImage(url: item.displayIconUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: imageHeight)
                    .clipped()
            } placeholder: {
                Color(.systemGray5)
                    .frame(maxWidth: .infinity)
                    .frame(height: imageHeight)
            }
            .frame(maxWidth: .infinity)
            .frame(height: imageHeight) // Fixed height to prevent layout shifts
            .background(Color.black)
            
            // Content section with gradient overlay style
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(item.archiveTitle ?? "Untitled")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                
                // Creator/Artist
                if let creators = item.creatorDisplay, !creators.isEmpty {
                    Text(getCreators())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
                
                // Media type badge and heart icon
                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: item.mediatypeDisplay == .audio || item.mediatypeDisplay == .etree ? "hifispeaker" : item.mediatypeDisplay == .movies ? "video" : "questionmark")
                            .font(.caption2)
                        Text(item.mediatypeDisplay == .audio || item.mediatypeDisplay == .etree ? "Audio" : item.mediatypeDisplay == .movies ? "Video" : "Unknown")
                            .font(.caption2)
                            .bold()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)

                    Spacer()
                    
                    Image(systemName: "heart.fill")
                        .font(.callout)
                        .foregroundColor(.fairyRed)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: contentHeight) // Fixed content height
            .background(Color(UIColor.systemBackground))
        }
        .frame(height: imageHeight + contentHeight) // Total fixed height
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.fairyRed.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private func getCreators() -> String {
        if let creators = item.creatorDisplay {
            if creators.count > 1 {
                return item.creatorDisplay?[0...1].joined(separator: ", ") ?? ""
            } else {
                return item.creatorDisplay?.first ?? ""
            }
        }

        return ""
    }
}
