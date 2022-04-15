//
//  HomeView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI

struct HomeView: View {
    @StateObject var iaPlayer = IAPlayer()

    var body: some View {
        VStack(alignment:.leading, spacing: 0) {
            ZStack(alignment:.top) {

//                if iaPlayer.showPlayingDetailView {
//                    if let identifier = iaPlayer.playingFile?.identifier {
//                        Detail(identifier)
//                            .zIndex(2)
//                            .transition(.move(edge:.bottom))
//                            .background(Color.white)
//                    }
//                }

                if iaPlayer.showPlaylist {
                    Playlist()
                        .zIndex(1)
                        .transition(.move(edge:.bottom))
                }
                Tabs()
            }
            Player()
                .frame(height: 100, alignment: .bottom)
        }
        .ignoresSafeArea(.keyboard)
//        .modifier(BackgroundColorModifier(backgroundColor: Color.droopy))
        .environmentObject(iaPlayer)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
