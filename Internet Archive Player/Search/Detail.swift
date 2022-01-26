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
    var doc: IASearchDoc?
    
    var body: some View {
        VStack{
            if let doc = doc {
                SearchItemView(item: doc)
                    .onLongPressGesture {
                        playlistViewModel.items.append(doc)
                    }
                    .frame(alignment:.top)
                    .padding(10)
            }
            Spacer()
        }
        .modifier(BackgroundColorModifier(backgroundColor: Color.droopy))
    }
}

struct Detail_Previews: PreviewProvider {
    static var previews: some View {
        Detail()
    }
}
