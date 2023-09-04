//
//  BetterDetail.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 7/8/23.
//

import Foundation
import SwiftUI

struct BetterDetail: View {
    private var identifier: String
    @EnvironmentObject var iaPlayer: Player
    @StateObject var viewModel = DetailViewModel()
    
    init(_ identifier: String, isPresented: Bool = false) {
        self.identifier = identifier
    }

    var body: some View {
        VStack(alignment: .center) {
            if let iconUrl = viewModel.archiveDoc?.iconUrl {
                AsyncImage (
                    url: iconUrl,
                    content: { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .background(Color.black)
                    },
                    placeholder: {
                        Color.black
                    })
//                .cornerRadius(15)
//                .edgesIgnoringSafeArea(.top)
            }
//            Spacer()
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .edgesIgnoringSafeArea(.all)
        .onAppear() {
            self.viewModel.getArchiveDoc(identifier: self.identifier)
            self.viewModel.setSubscribers(iaPlayer)
        }
    }
}
