//
//  SearchItemView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/25/22.
//

import Foundation
import SwiftUI
import iaAPI

struct SearchItemView<Item: SearchItemDisplayable>: View {
    var item: Item
    var textColor: Color = .droopy
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Image with fixed aspect ratio
            CachedAsyncImage(url: item.displayIconUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
            } placeholder: {
                Color(.systemGray5)
                    .frame(width: 80, height: 80)
            }
            .frame(width: 80, height: 80) // Fixed frame to prevent layout shifts
            .background(Color.black)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                // Title with media type icon
                HStack(spacing: 6) {
                    Text(item.archiveTitle ?? "Untitled")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                    
                    Image(systemName: mediaTypeIconName(for: item.mediatypeDisplay))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Creator/Artist
                if let creators = item.creatorDisplay, !creators.isEmpty {
                    Text(getCreators())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                // First collection badge
                if let collections = item.collectionArchivesDisplay,
                   let firstCollection = collections.first,
                   let collectionTitle = firstCollection.metadata?.archiveTitle {
                    HStack(spacing: 4) {
                        Image(systemName: "tray.2.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(collectionTitle)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.top, 2)
                }

                // Publisher (only if exists)
                if let publisher = item.publisherDisplay, !publisher.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Text("Publisher:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .bold()
                        Text(publisher.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundFillColor)
        )
        .frame(maxWidth: .infinity)
    }
    
    private var backgroundFillColor: Color {
        if item.mediatypeDisplay == .collection {
            return Color(UIColor.systemGray3).opacity(0.85)
        } else {
            return Color(UIColor.systemGray6).opacity(0.5)
        }
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

    private func mediaTypeIconName(for type: ArchiveMediaType?) -> String {

        guard let type else { return "questionmark" }

        switch type {
        case .audio, .etree:
            return "hifispeaker"
        case .movies:
            return "video"
        case .collection:
            return "tray.2"
        default:
            return "questionmark"
        }
    }
}
