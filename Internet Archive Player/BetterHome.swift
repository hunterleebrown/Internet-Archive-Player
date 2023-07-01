//
//  BetterHome.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 6/30/23.
//

import Foundation
import SwiftUI

enum PresentedSheet {
    case search
    case favorites
}

struct BetterHome: View {
    @StateObject var iaPlayer = Player()
    @State private var presentingSearch = false
    @State private var presentingFavorites = false
    @State var playingFile: ArchiveFileEntity? = nil
    @State private var showingAlert = false
    @State var showVideoPlayer: Bool = false


    var body: some View {
        NavigationStack {
            if showVideoPlayer {
                CustomVideoPlayer(player: iaPlayer.avPlayer)
                    .frame(width: .infinity, height: 200)
                    .padding(5)
            }
            Playlist()
            Spacer()
                .navigationTitle("Playlist")
                .toolbar {

                    Button(action: {
                        presentingSearch.toggle()
                    }){
                        Image(systemName: "magnifyingglass")
                            .resizable()
                            .frame(width: 30, height: 30)
                    }
                    .tint(.fairyRed)

                    Button(action: {
                        presentingFavorites.toggle()
                    }){
                        Image(systemName: "heart")
                            .resizable()
                            .frame(width: 30, height: 30)
                    }
                    .tint(.fairyRed)

                    EditButton()
                        .tint(.fairyRed)

                    Button(action: {
                        showingAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.fairyRed)
                    }
                    .alert("Are you sure you want to delete the playlist?", isPresented: $showingAlert) {
                        Button("No", role: .cancel) { }
                        Button("Yes") {
                            iaPlayer.clearPlaylist()
                        }
                    }

                }
                .sheet(isPresented: $presentingSearch) {
                    SearchView()
                }
                .sheet(isPresented: $presentingFavorites) {
                    FavoritesView()
                }
                .sheet(item: $playingFile, content: { file in
                    Detail(file.identifier!, isPresented: true)
                })
                .onReceive(PlayerControls.showPlayingDetails) { file in
                    withAnimation {
                        playingFile = file
                    }
                }
                .onReceive(PlayerControls.showVideo) { show in
                    showVideoPlayer.toggle()
                }
            PlayerControls()
                .padding(10)

        }
        .environmentObject(iaPlayer)
    }
}
