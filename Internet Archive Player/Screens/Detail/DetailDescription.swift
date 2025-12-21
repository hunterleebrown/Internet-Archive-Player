//
//  DetailDescription.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 8/9/23.
//

import Foundation
import SwiftUI
import iaAPI

struct DetailDescription: View {

    @ScaledMetric(relativeTo: .body) var fontSize: CGFloat = 16 // Automatically scales with Dynamic Type
    @State private var webViewHeight: CGFloat = 100
    @Environment(\.dismiss) private var dismiss

    var doc: ArchiveMetaData

    var body: some View {
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        let fontFamily = bodyFont.familyName
        let fontWeight: String = {
            switch bodyFont.fontDescriptor.symbolicTraits {
            case let traits where traits.contains(.traitBold):
                return "bold"
            default:
                return "normal"
            }
        }()

        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                Text(doc.archiveTitle ?? "Archive Details")
                    .font(.title2)
                    .foregroundColor(.fairyRed)
                    .bold()
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
            .background(Color.white)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Icon and basic info
                    HStack(alignment: .top, spacing: 12) {
                        AsyncImage(
                            url: doc.iconUrl,
                            content: { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 66, maxHeight: 66)
                                    .background(Color.black)
                            },
                            placeholder: {
                                Color(.black)
                                    .frame(maxWidth: 66, maxHeight: 66)
                            })
                        .cornerRadius(5)
                        .frame(width: 66, height: 66)

                        VStack(alignment: .leading, spacing: 6) {
                            if let artist = doc.artist ?? doc.creator?.joined(separator: ", ") {
                                Text(artist)
                                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                                    .font(.subheadline)
                                    .bold()
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Metadata section
                    VStack(alignment: .leading, spacing: 12) {
                        if let identifier = doc.identifier {
                            MetadataRow(label: "Identifier", value: identifier)
                        }
                        
                        // Collections with icons
                        if !doc.collectionArchives.isEmpty {
                            CollectionsMetadataRow(collectionArchives: doc.collectionArchives, dismiss: dismiss)
                        }
                        
                        if let publisher = doc.publisher, !publisher.isEmpty {
                            MetadataRow(label: "Publisher", value: publisher.joined(separator: ", "))
                        }

                        if let uploader = doc.uploader {
                            MetadataRow(label: "Uploader", value: uploader)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                    )
                    .padding(.horizontal, 20)

                    // View on archive.org button
                    if let identifier = doc.identifier {
                        Link(destination: URL(string: "https://archive.org/details/\(identifier)")!) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.up.forward.square")
                                    .font(.subheadline)
                                Text("View on archive.org")
                                    .font(.subheadline)
                                    .bold()
                            }
                            .foregroundColor(.fairyRed)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.fairyRed, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Description section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.fairyRed)
                            .padding(.horizontal, 20)
                        
                        WebView(htmlString: doc.description.joined(separator: ""),
                                bodyFontSize: fontSize,
                                bodyFontFamily: fontFamily,
                                bodyFontWeight: fontWeight,
                                contentHeight: $webViewHeight
                        )
                        .frame(height: webViewHeight)
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.top, 8)
            }
        }
        .presentationDragIndicator(.visible)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .colorScheme(.light) // Force light mode
    }
}

// Helper view for consistent metadata rows
private struct MetadataRow: View {
    let label: String
    let value: String
    
    @State private var showCopiedFeedback = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .bold()
                
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
            }
            
            Text(value)
                .font(.body)
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                .textSelection(.enabled)
        }
        .contentShape(Rectangle())
        .onLongPressGesture {
            // Copy to clipboard
            UIPasteboard.general.string = value
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Show feedback
            withAnimation {
                showCopiedFeedback = true
            }
            
            // Hide feedback after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showCopiedFeedback = false
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if showCopiedFeedback {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                    Text("Copied")
                        .font(.caption2)
                        .bold()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.fairyRed)
                )
                .transition(.scale.combined(with: .opacity))
                .offset(x: 8, y: -8)
            }
        }
    }
}
// Helper view for displaying collections with icons
private struct CollectionsMetadataRow: View {
    let collectionArchives: [Archive]
    let dismiss: DismissAction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Collections")
                .font(.caption)
                .foregroundColor(.secondary)
                .bold()
            
            if collectionArchives.isEmpty {
                Text("No collections")
                    .font(.body)
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(collectionArchives) { archive in
                        HStack(alignment: .top, spacing: 6) {
                            // Collection icon
                            AsyncImage(url: archive.metadata?.iconUrl) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Image(systemName: "folder")
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 20, height: 20)
                            .cornerRadius(3)
                            
                            Text(archive.metadata?.archiveTitle ?? archive.metadata?.identifier ?? "Unknown")
                                .font(.subheadline)
                                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .lineLimit(nil)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white)
                        )
                        .onTapGesture {apGesture in
                            guard let meta = archive.metadata else { return }
                            goToSearchWithCollection(collection: meta)
                        }
                    }
                }
            }
        }
    }

    func goToSearchWithCollection(collection: ArchiveMetaData)  {
        // Send the filter (this will dismiss both sheets via their respective onReceive handlers)
        Home.searchPass.send(collection)

        // Dismiss DetailDescription sheet
        dismiss()
    }
}

// Simple flow layout for wrapping collection chips
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

