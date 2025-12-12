//
//  SearchItemView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/25/22.
//

import Foundation
import SwiftUI
import iaAPI

struct SearchItemView<Item: SearchItemDisplayable>: View {
    var item: Item
    var textColor: Color = .droopy
    var body: some View {
        HStack(alignment:.top, spacing: 5.0) {

            AsyncImage(
                url: item.displayIconUrl,
                content: { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 44,
                               maxHeight: 44)
                        .background(Color.black)

                },
                placeholder: {
                    Color(.black)
                        .frame(maxWidth: 44,
                               maxHeight: 44)
                })
            .cornerRadius(5)
            .frame(width: 44, height: 44, alignment: .leading)

            Image(systemName: item.mediatypeDisplay == .audio ||  item.mediatypeDisplay == .etree ? "hifispeaker" : item.mediatypeDisplay == .movies ? "video" : "questionmark")
                .frame(width: 22.0, height: 22.0, alignment: .center)
                .tint(.black)

            VStack(alignment:.leading, spacing: 2.0) {
                Text(item.archiveTitle ?? "")
                    .bold()
                    .font(.caption)
//                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)

                if let publisher = item.publisherDisplay, !publisher.isEmpty {
                    HStack(alignment: .top, spacing: 5.0) {
                        Text("Publisher: ")
                            .font(.caption2)
//                            .foregroundColor(textColor)
                            .bold()
                        Text(publisher.joined(separator: ", "))
                            .font(.caption2)
//                            .foregroundColor(textColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }
                }

                if !(item.creatorDisplay?.isEmpty ?? false) {
                    HStack(alignment: .top, spacing: 5.0) {
                        Text(getCreators())
                            .font(.caption2)
//                            .foregroundColor(textColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .frame(maxWidth: .infinity,
                   alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    private func getCreators() -> String {
        if let creators = item.creatorDisplay {
            if creators.count > 1 {
                return item.creatorDisplay?[0...1].joined(separator: ", ") ?? ""
            } else {
                return item.creatorDisplay?.first ?? ""
            }
        }

        return ""
    }
}
