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
                    .transition(.move(edge:.bottom))
                }
                Tabs()
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
