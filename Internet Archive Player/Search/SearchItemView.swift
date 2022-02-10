//
//  SearchItemView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/25/22.
//

import Foundation
import SwiftUI
import iaAPI

struct SearchItemView: View {
    var item: IASearchDoc
    var textColor: Color = .droopy
    var body: some View {
        HStack(alignment:.center, spacing: 10.0) {

            AsyncImage(
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
                Text(item.title ?? "")
                    .frame(alignment:.leading)
                    .font(.headline)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
                Text(item.creator.joined(separator: ", "))
                    .font(.footnote)
                    .frame(alignment:.leading)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
                Text(item.desc ?? "")
                    .font(.body)
                    .frame(alignment:.leading)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)

            }
            .frame(maxWidth: .infinity,
                   alignment: .leading)
        }
//        .background(Color.droopy)
        .frame(maxWidth: .infinity,
               minHeight: 90)
    }
}
