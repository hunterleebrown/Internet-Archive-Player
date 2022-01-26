//
//  HomeView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI

struct HomeView: View {
    @State var showPlayer = false
    @StateObject var playlistViewModel = Playlist.ViewModel()
    var body: some View {
        VStack(alignment:.leading, spacing: 0) {
            ZStack(alignment:.top) {
                if showPlayer {
                Playlist()
                    .zIndex(1)
//                    .opacity(showPlayer ? 1 : 0)
//                    .frame(height: showPlayer ? nil : 0, alignment: .bottom)
                    .transition(.move(edge:.bottom))
                }
                Tabs()
//                    .zIndex(showPlayer ? 2 : 1)
//                    .opacity(showPlayer ? 0 : 1)
//                    .frame(height: showPlayer ? 0 : nil, alignment: .bottom)
//                    .transition(.scale(scale: 0.1, anchor: .bottom))


            }
            Player(showPlayer: $showPlayer)
                .frame(height: 100, alignment: .bottom)
        }
        .ignoresSafeArea(.keyboard)
        .modifier(BackgroundColorModifier(backgroundColor: Color.droopy))
        .environmentObject(playlistViewModel)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
