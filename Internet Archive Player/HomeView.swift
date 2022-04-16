//
//  HomeView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI

struct HomeView: View {
    @StateObject var iaPlayer = Player()
    @State var showPlaylist = false
    @State var showPlayingDetails = false
    @State var identifier = ""

    var body: some View {
        VStack(alignment:.leading, spacing: 0) {
            ZStack(alignment:.top) {

                if showPlayingDetails {
                    Detail(identifier)
                        .zIndex(2)
                        .transition(.move(edge:.bottom))
                        .background(Color.white)
                }

                if showPlaylist {
                    Playlist()
                        .zIndex(1)
                        .transition(.move(edge:.bottom))
                }
                Tabs()
            }
            PlayerControls()
                .frame(height: 100, alignment: .bottom)
        }
        .ignoresSafeArea(.keyboard)
        .environmentObject(iaPlayer)
        .onReceive(PlayerControls.showPlayList) { shouldShow in
            withAnimation {
                self.showPlaylist = shouldShow
            }
        }
//        .onReceive(PlayerControls.showPlayingDetails) { id in
//            withAnimation {
//                identifier = id
//                showPlayingDetails.toggle()
//            }
//        }

    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
