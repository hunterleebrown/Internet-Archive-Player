//
//  SearchItemView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/25/22.
//

import Foundation
import SwiftUI
import iaAPI
import CachedAsyncImage

struct SearchItemView: View {
    var item: ArchiveMetaData
    var textColor: Color = .droopy
    var body: some View {
        HStack(alignment:.center, spacing: 10.0) {

            CachedAsyncImage (
                url: item.iconUrl,
                content: { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 80,
                               maxHeight: 80)
                        .background(Color.black)

                },
                placeholder: {
                    ProgressView()
                })
                .cornerRadius(15)

            VStack(alignment:.leading) {
                Text(item.archiveTitle ?? "")
                    .frame(alignment:.leading)
                    .font(.headline)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
                Text(item.creator?.joined(separator: ", ") ?? "")
                    .font(.footnote)
                    .frame(alignment:.leading)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
//                Text(item.description ?? "")
//                    .font(.body)
//                    .frame(alignment:.leading)
//                    .foregroundColor(textColor)
//                    .multilineTextAlignment(.leading)

            }
            .frame(maxWidth: .infinity,
                   alignment: .leading)
        }
//        .background(Color.droopy)
        .frame(maxWidth: .infinity,
               minHeight: 90)
    }
}
