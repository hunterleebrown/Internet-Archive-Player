//
//  DetailDescription_tvOS.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/15/25.
//

import Foundation
import SwiftUI
import iaAPI
import UIKit

struct DetailDescription: View {

    var doc: ArchiveMetaData

    // MARK: - Focus catcher (keeps focus stable so move commands scroll)
    @FocusState private var focusCatcherFocused: Bool

    // MARK: - Paging scroll state
    @State private var anchorIndex: Int = 0

    // MARK: - Tuning
    private let animationDuration: Double = 0.22
    private let pageStride: Int = 1

    // Helper function to scale attributed string fonts for tvOS
    private func scaledAttributedStringForTVOS(_ attributedString: NSAttributedString) -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        let range = NSRange(location: 0, length: mutableAttributedString.length)

        // Target font size for tvOS body text (readable from distance)
        let tvOSBodySize: CGFloat = 29.0

        mutableAttributedString.enumerateAttribute(.font, in: range, options: []) { value, range, _ in
            if let font = value as? UIFont {
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

    // MARK: - Paragraph splitting (helps scrolling feel “paged”)
    private func descriptionParagraphs() -> [String] {
        let raw = doc.description.joined(separator: "\n")
        let parts = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return parts.isEmpty ? (raw.isEmpty ? [] : [raw]) : parts
    }

    // MARK: - Anchor counts
    private func totalAnchorCount(hasCollections: Bool, paragraphCount: Int, hasAttributed: Bool) -> Int {
        // Anchors:
        // 0 = top
        // 1 = header
        // 2 = metadata
        // 3 = collections (if present) OR first description (if no collections)
        // description:
        //   - attributed HTML: single anchor
        //   - plain paragraphs: one anchor per paragraph
        // last = bottom
        var count = 1 // top
        count += 1    // header
        count += 1    // metadata
        if hasCollections { count += 1 } // collections

        if hasAttributed {
            count += 1 // one description anchor
        } else {
            count += max(0, paragraphCount) // per paragraph
        }

        count += 1 // bottom
        return count
    }

    // MARK: - Move command handling
    private func handleMove(_ direction: MoveCommandDirection, proxy: ScrollViewProxy, maxIndex: Int) {
        switch direction {
        case .down:
            anchorIndex = min(anchorIndex + pageStride, maxIndex)
        case .up:
            anchorIndex = max(anchorIndex - pageStride, 0)
        default:
            return
        }

        withAnimation(.easeOut(duration: animationDuration)) {
            proxy.scrollTo(anchorIndex, anchor: .top)
        }
    }

    var body: some View {
        let hasCollections = !doc.collectionArchives.isEmpty
        let paragraphs = descriptionParagraphs()
        let hasAttributed = (doc.description.joined(separator: "").html2AttributedString != nil)

        let maxAnchorIndex = max(
            0,
            totalAnchorCount(
                hasCollections: hasCollections,
                paragraphCount: paragraphs.count,
                hasAttributed: hasAttributed
            ) - 1
        )

        ScrollViewReader { proxy in
            ZStack(alignment: .topLeading) {

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 32) {

                        // Anchor 0: top
                        Color.clear
                            .frame(height: 1)
                            .id(0)

                        // Header (Anchor 1)
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
                        .id(1)

                        // Metadata (Anchor 2)
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
                        .id(2)

                        // Collections (Anchor 3 if present)
                        if hasCollections {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Collections")
                                    .font(.system(size: 24, weight: .semibold))
                                    .opacity(0.9)

                                FlowingCollectionsView(collections: doc.collectionArchives)
                                    // If FlowingCollectionsView has focusable children, it can still “steal”
                                    // focus. This reduces the chance:
                                    .focusable(false)
                            }
                            .id(3)
                        }

                        // Description
                        if !doc.description.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Description")
                                    .font(.system(size: 24, weight: .semibold))

                                let firstDescriptionAnchor = hasCollections ? 4 : 3

                                if let att = doc.description.joined(separator: "").html2AttributedString {
                                    Text(AttributedString(scaledAttributedStringForTVOS(att)))
                                        .font(.body)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .id(firstDescriptionAnchor)
                                } else {
                                    VStack(alignment: .leading, spacing: 18) {
                                        ForEach(Array(paragraphs.enumerated()), id: \.offset) { (i, p) in
                                            Text(p)
                                                .font(.body)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .multilineTextAlignment(.leading)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .id(firstDescriptionAnchor + i)
                                        }
                                    }
                                }
                            }
                        }

                        // Bottom anchor
                        Spacer(minLength: 140)
                            .id(maxAnchorIndex)
                    }
                    .padding(60)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Invisible focus catcher: stays focused and converts ↑/↓ into scroll-to-anchor.
                Button(action: {}) { EmptyView() }
                    .buttonStyle(.plain)
                    .frame(width: 1, height: 1)
                    .opacity(0.001)
                    .focused($focusCatcherFocused)
                    .onMoveCommand { direction in
                        handleMove(direction, proxy: proxy, maxIndex: maxAnchorIndex)
                    }
            }
            .onAppear {
                // Ensure we start focused on the catcher and at top
                anchorIndex = 0
                DispatchQueue.main.async {
                    focusCatcherFocused = true
                    proxy.scrollTo(0, anchor: .top)
                }
            }
        }
    }
}
