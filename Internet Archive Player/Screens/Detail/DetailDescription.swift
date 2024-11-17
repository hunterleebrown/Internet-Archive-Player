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

        ScrollView() {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    AsyncImage(
                        url: doc.iconUrl,
                        content: { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 66,
                                       maxHeight: 66)
                                .background(Color.black)

                        },
                        placeholder: {
                            Color(.black)
                                .frame(maxWidth: 66,
                                       maxHeight: 66)
                        })
                    .cornerRadius(5)
                    .frame(width: 66, height: 66, alignment: .leading)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(doc.archiveTitle ?? "")
                            .font(.headline)
                            .foregroundColor(.black)
                            .bold()
                            .multilineTextAlignment(.leading)
                            .frame(alignment: .leading)

                        if let artist = doc.artist ?? doc.creator?.joined(separator: ", ") {
                            Text(artist)
                                .foregroundColor(.black)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                        }

                        if let identifier = doc.identifier {
                            HStack(alignment: .top, spacing: 5) {
                                Text("Identifier:")
                                    .foregroundColor(.black)
                                    .font(.caption)
                                    .bold()
                                Text(identifier)
                                    .foregroundColor(.black)
                                    .font(.caption)
                            }
                        }

                        if let publisher = doc.publisher, !publisher.isEmpty {
                            HStack(alignment: .top, spacing: 5) {
                                Text("Publisher:")
                                    .foregroundColor(.black)
                                    .font(.caption)
                                    .bold()
                                Text(publisher.joined(separator: ", "))
                                    .foregroundColor(.black)
                                    .font(.caption)
                                    .multilineTextAlignment(.leading)
                            }
                        }

                        HStack(alignment: .top, spacing: 5) {
                            Text("Collection:")
                                .foregroundColor(.black)
                                .font(.caption)
                                .bold()
                            Text(doc.collection.joined(separator: ", "))
                                .foregroundColor(.black)
                                .font(.caption)
                                .multilineTextAlignment(.leading)
                        }
#if !os(tvOS)
                        if let identifier = doc.identifier {
                            Link("View on archive.org", destination: URL(string: "https://archive.org/details/\(identifier)")!)
                                .foregroundColor(.fairyRed)
                                .font(.subheadline)
                        }
#endif
                    }
                }

                WebView(htmlString: doc.description.joined(separator: ""),
                        bodyFontSize: fontSize,
                        bodyFontFamily: fontFamily,
                        bodyFontWeight: fontWeight,
                        contentHeight: $webViewHeight
                )
                .edgesIgnoringSafeArea(.all)
                .background(Color.yellow)
                .frame(height: webViewHeight)
                .padding()
            }
            .background(Color.white)
            .foregroundColor(.black)
            .frame(maxWidth:.infinity)
            .padding(5)
        }
        .background(Color.white)

    }
}
