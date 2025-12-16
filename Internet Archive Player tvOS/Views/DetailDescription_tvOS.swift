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

    @Environment(\.dismiss) private var dismiss
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
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                Text(doc.archiveTitle ?? "Archive Details")
                    .font(.title2)
                    .foregroundColor(.fairyRed)
                    .bold()
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dismiss()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.fairyRed)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 40)
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Icon and basic info
                    HStack(alignment: .top, spacing: 20) {
                        AsyncImage(
                            url: doc.iconUrl,
                            content: { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 100, maxHeight: 100)
                                    .background(Color.black)
                            },
                            placeholder: {
                                Color(.black)
                                    .frame(maxWidth: 100, maxHeight: 100)
                            })
                        .cornerRadius(8)
                        .frame(width: 100, height: 100)

                        VStack(alignment: .leading, spacing: 10) {
                            if let artist = doc.artist ?? doc.creator?.joined(separator: ", ") {
                                Text(artist)
                                    .foregroundColor(.primary)
                                    .font(.title3)
                                    .bold()
                                    .multilineTextAlignment(.leading)
                            }
                            
                            if let identifier = doc.identifier {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Identifier")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .bold()
                                    Text(identifier)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // Metadata section
                    VStack(alignment: .leading, spacing: 16) {
                        // Collections
                        if !doc.collection.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Collections")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text(doc.collection.joined(separator: ", "))
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        if let publisher = doc.publisher, !publisher.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Publisher")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text(publisher.joined(separator: ", "))
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }

                        if let uploader = doc.uploader {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Uploader")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text(uploader)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // Description section
                    if !doc.description.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Description")
                                .font(.title3)
                                .foregroundColor(.fairyRed)
                                .bold()
                            
                            if let att = doc.description.joined(separator: "").html2AttributedString {
                                Text(AttributedString(scaledAttributedStringForTVOS(att)))
                                    .font(.body)
                                    .foregroundColor(.primary)
                            } else {
                                Text(doc.description.joined(separator: "\n"))
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.darkGray).opacity(0.3))
    }
}

