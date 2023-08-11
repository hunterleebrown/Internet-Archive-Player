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
                Text(doc.archiveTitle ?? "")
                    .font(.headline)
                    .bold()

                if let artist = doc.artist ?? doc.creator?.joined(separator: ", ") {
                    Text(artist)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }

                if let publisher = doc.publisher {
                    Text(publisher.joined(separator: ", "))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }

                Text(AttributedString(attString))
                    .background(Color.white)
            }
            .padding(20.0)
            Spacer()
        }
    }
}
