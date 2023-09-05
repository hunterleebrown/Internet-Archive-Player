//
//  Home.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 6/30/23.
//

import Foundation
import SwiftUI
import AVKit

enum PresentedSheet {
    case search
    case favorites
}

struct Home: View {
    @StateObject var iaPlayer = Player()
    @State private var presentingSearch = false
    @State private var presentingFavorites = false
    @State var playingFile: ArchiveFileEntity? = nil
    @State private var showingAlert = false
    @State var showVideoPlayer: Bool = false
    @State var showNetworkAlert: Bool = false

    var body: some View {

        GeometryReader { geo in

            VStack(spacing:0) {
                NavigationStack {
                    Playlist()
                        .navigationTitle("Now Playing")
                        .toolbar {

                            ToolbarItem(placement: .navigationBarLeading) {

                                Button(action: {
                                    presentingSearch.toggle()
                                }){
                                    NavigationLink(destination: SearchView()) {
                                        Image(systemName: "magnifyingglass")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                    }
                                }
                                .tint(.fairyRed)
                            }

//                            ToolbarItem(placement: .navigationBarLeading) {
//
//                                Button(action: {
//                                    print("lists tapped")
//                                }){
//                                    NavigationLink(destination: ListsView()) {
//                                        Image(systemName: "music.note.list")
//                                            .resizable()
//                                            .frame(width: 30, height: 30)
//                                    }
//                                }
//                                .tint(.fairyRed)
//                            }

                            ToolbarItem(placement: .navigationBarLeading) {

                                Button(action: {
                                    presentingFavorites.toggle()
                                }){
                                    Image(systemName: "heart")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                }
                                .tint(.fairyRed)

                            }
                            
                        }
                        .toolbar {


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
                        .sheet(isPresented: $presentingFavorites) {
                            NewFavoritesView()
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
                            withAnimation {
                                showVideoPlayer = show
                            }
                        }
                        .onReceive(Player.networkAlert, perform: { badNetwork in
                            showNetworkAlert = true
                        })
                        .alert("There is no network connection", isPresented: $showNetworkAlert) {
                            Button("OK") {
                                showNetworkAlert = false
                            }
                        }
                        .safeAreaInset(edge: .bottom) {
                            Spacer()
                                .frame(height: showVideoPlayer ? (geo.size.width / 1.778) : 200 )
                        }


                }
                .safeAreaInset(edge: .bottom) {
                    ZStack {
                        CustomVideoPlayer()
                            .frame(height: showVideoPlayer ? (geo.size.width / 1.778) : 0 )
                            .zIndex(showVideoPlayer ? 1 : 0)

                        PlayerControls()
                            .cornerRadius(10)
                            .zIndex(showVideoPlayer ? 0 : 1)
                    }
                    .padding(10)
                }
            }

        }
        .environmentObject(iaPlayer)
    }

}
