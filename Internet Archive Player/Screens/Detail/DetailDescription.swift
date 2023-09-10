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
                VStack(spacing: 10) {
                    Text(doc.archiveTitle ?? "")
                        .font(.headline)
                        .bold()

                    if let artist = doc.artist ?? doc.creator?.joined(separator: ", ") {
                        Text(artist)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }

                    if let publisher = doc.publisher, !publisher.isEmpty {
                        Text(publisher.joined(separator: ", "))
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }

                    HStack(alignment: .top, spacing: 5) {
                        Text("Collection:")
                            .font(.subheadline)
                            .bold()
                        Text(doc.collection.joined(separator: ", "))
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }

                    Text(AttributedString(attString))
                        .background(Color.white)
                }
                Spacer()
            }
            .padding(20.0)
        }
    }
}
