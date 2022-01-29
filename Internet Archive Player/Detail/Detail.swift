//
//  Detail.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/24/22.
//

import SwiftUI
import iaAPI

struct Detail: View {
    @EnvironmentObject var playlistViewModel: Playlist.ViewModel
    @ObservedObject var viewModel: Detail.ViewModel
    var doc: IASearchDoc?

    init(_ doc: IASearchDoc?) {
        self.doc = doc
        self.viewModel = Detail.ViewModel(doc)
    }
    
    var body: some View {
        VStack{
            Spacer()
        }
        .modifier(BackgroundColorModifier(backgroundColor: Color.droopy))
    }
}

struct Detail_Previews: PreviewProvider {
    static var previews: some View {
        Detail(nil)
    }
}

extension Detail {
    final class ViewModel: ObservableObject {
        let service: IAService
        let searchDoc: IASearchDoc?
        init(_ doc: IASearchDoc?) {
            self.service = IAService()
            self.searchDoc = doc
        }
    }
    
}
