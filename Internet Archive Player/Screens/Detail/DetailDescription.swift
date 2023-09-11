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

    var doc: ArchiveMetaData

    var body: some View {
        if let attString = doc.description.joined(separator: "").html2AttributedString {
            ScrollView() {
                VStack(alignment: .leading, spacing: 10) {
                    Text(doc.archiveTitle ?? "")
                        .font(.headline)
                        .bold()
                        .multilineTextAlignment(.center)
                        .frame(alignment: .center)

                    if let artist = doc.artist ?? doc.creator?.joined(separator: ", ") {
                        Text(artist)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }

                    if let publisher = doc.publisher, !publisher.isEmpty {
                        HStack(alignment: .top, spacing: 5) {
                            Text("Publisher:")
                                .font(.caption)
                                .bold()
                            Text(publisher.joined(separator: ", "))
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                    }

                    HStack(alignment: .top, spacing: 5) {
                        Text("Collection:")
                            .font(.caption)
                            .bold()
                        Text(doc.collection.joined(separator: ", "))
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()
                        .frame(height:44)

                    Text(AttributedString(attString))
                        .background(Color.white)
                        .padding(10)

                    Spacer()
                }
                Spacer()
            }
            .padding(20)
        }

    }
}
