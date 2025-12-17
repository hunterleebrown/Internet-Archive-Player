//
//  DetailDescription_tvOS.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/15/25.
//

import Foundation
import SwiftUI
import iaAPI

struct DetailDescription: View {

    var doc: ArchiveMetaData
    
    // Helper function to scale attributed string fonts for tvOS
    private func scaledAttributedStringForTVOS(_ attributedString: NSAttributedString) -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        let range = NSRange(location: 0, length: mutableAttributedString.length)
        
        // Target font size for tvOS body text (readable from distance)
        let tvOSBodySize: CGFloat = 29.0
        
        mutableAttributedString.enumerateAttribute(.font, in: range, options: []) { value, range, _ in
            if let font = value as? UIFont {
                // Scale the font while preserving its traits (bold, italic, etc.)
                let scaledFont: UIFont
                if font.fontDescriptor.symbolicTraits.contains(.traitBold) {
                    scaledFont = UIFont.boldSystemFont(ofSize: tvOSBodySize)
                } else if font.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                    scaledFont = UIFont.italicSystemFont(ofSize: tvOSBodySize)
                } else {
                    scaledFont = UIFont.systemFont(ofSize: tvOSBodySize)
                }
                mutableAttributedString.addAttribute(.font, value: scaledFont, range: range)
            }
        }
        
        return mutableAttributedString
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 32) {
                // Header section with icon and title
                HStack(alignment: .top, spacing: 24) {
                    AsyncImage(url: doc.iconUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150)
                            .cornerRadius(12)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 150, height: 150)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(doc.archiveTitle ?? "Archive Details")
                            .font(.system(size: 36, weight: .bold))
                            .multilineTextAlignment(.leading)
                        
                        if let artist = doc.artist ?? doc.creator?.joined(separator: ", "), !artist.isEmpty {
                            Text(artist)
                                .font(.system(size: 24, weight: .medium))
                                .opacity(0.9)
                        }
                        
                        if let identifier = doc.identifier {
                            Text(identifier)
                                .font(.caption)
                                .opacity(0.7)
                        }
                    }
                    
                    Spacer()
                }
                
                // Metadata section
                VStack(alignment: .leading, spacing: 20) {
                    if let publisher = doc.publisher, !publisher.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Publisher")
                                .font(.headline)
                                .opacity(0.7)
                            
                            Text(publisher.joined(separator: ", "))
                                .font(.body)
                        }
                    }
                    
                    if let uploader = doc.uploader {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Uploader")
                                .font(.headline)
                                .opacity(0.7)
                            
                            Text(uploader)
                                .font(.body)
                        }
                    }
                }
                
                // Collections with images (flowing layout)
                if !doc.collectionArchives.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Collections")
                            .font(.system(size: 24, weight: .semibold))
                            .opacity(0.9)
                        
                        FlowingCollectionsView(collections: doc.collectionArchives)
                    }
                }
                
                // Description section
                if !doc.description.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.system(size: 24, weight: .semibold))
                        
                        if let att = doc.description.joined(separator: "").html2AttributedString {
                            Text(AttributedString(scaledAttributedStringForTVOS(att)))
                                .font(.body)
                        } else {
                            Text(doc.description.joined(separator: "\n"))
                                .font(.body)
                        }
                    }
                }
                
                // Add a spacer at the bottom to ensure last content is visible
                Spacer(minLength: 100)
            }
            .padding(60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


