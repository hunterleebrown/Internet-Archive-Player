//
//  Home.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 6/30/23.
//

import Foundation
import SwiftUI
import AVKit
import Combine

enum PresentedSheet {
    case search
    case favorites
}

struct Home: View {
    @StateObject var iaPlayer = Player()
    @State private var presentingSearch = false
    @State private var presentingFavorites = false
    @State var playingFile: ArchiveFileEntity? = nil
    @State var showVideoPlayer: Bool = false
    @State var showNetworkAlert: Bool = false
    @State var showControls: Bool = false
    @State var maxControlHeight: Bool = true
    @State var fileForPlaylist: ArchiveFileEntity?
    @State var otherPlaylistPresented: Bool = false

    static var showControlsPass = PassthroughSubject<Bool, Never>()
    static var controlHeightPass = PassthroughSubject<Bool, Never>()
    static var otherPlaylistPass = PassthroughSubject<ArchiveFileEntity, Never>()

    var body: some View {
        ZStack(alignment: .bottom) {

            VStack(spacing: 0) {
                ZStack {
                    CustomVideoPlayer()
                        .frame(height: showVideoPlayer ? 160 : 0 )
                        .zIndex(showVideoPlayer ? 1 : 0)
//                        .padding(5)

                    PlayerControls()
                        .zIndex(showVideoPlayer ? 0 : 1)
                        .padding(5)
                }
            }
            .opacity(showControls ? 1 : 0)
            .frame(maxWidth: 428, maxHeight: maxControlHeight ? 160 : 58, alignment: .top)
            .clipped()
            .gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
                .onEnded { value in
                    print(value.translation)
                    switch(value.translation.width, value.translation.height) {
                    case (...0, -30...30):  print("left swipe")
                    case (0..., -30...30):  print("right swipe")
                    case (-100...100, ...0):
                        print("up swipe")
                        Home.controlHeightPass.send(true)
                    case (-100...100, 0...):  print("down swipe")
                        Home.controlHeightPass.send(false)
                    default:  print("no clue")
                    }
                }
            )
            .zIndex(showControls ? 1: 0)

            NavigationStack {
                VStack(spacing:0) {
                    Playlist()
                        .navigationTitle("Now playing")
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

                            ToolbarItem(placement: .navigationBarLeading) {

                                Button(action: {
                                    print("lists tapped")
                                }){
                                    NavigationLink(destination: ListsView()) {
                                        Image(systemName: "music.note.list")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                    }
                                }
                                .tint(.fairyRed)
                            }

                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    presentingFavorites.toggle()
                                }){
                                    NavigationLink(destination: NewFavoritesView()) {
                                        Image(systemName: "heart")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                    }
                                }
                                .tint(.fairyRed)
                            }

                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    print("debug tap")
                                }){
                                    NavigationLink(destination: DebugView()) {
                                        Image(systemName: "ant.circle")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                    }
                                }
                                .tint(.fairyRed)
                            }
                        }
                        .sheet(item: $playingFile, content: { file in
                            if let identifier = file.identifier {
                                Detail(identifier, isPresented: true)
                            }
                        })
                }
                .safeAreaInset(edge: .bottom) {
                    VStack {
                        Spacer()
                            .frame(height: showControls ? 200 : 0)
                    }
                }

                .navigationBarColor(backgroundColor: Color("playerBackground").opacity(0.5), titleColor: .fairyRed)
            }
        }
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
        .onReceive(Home.showControlsPass) { show in
            withAnimation {
                showControls = show
            }
        }
        .onReceive(Player.networkAlert, perform: { badNetwork in
            showNetworkAlert = true
        })
        .onReceive(Home.controlHeightPass, perform: { show in
            withAnimation {
                maxControlHeight = show
            }
        })
        .onReceive(Home.otherPlaylistPass, perform: { archiveFileEntiity in
            fileForPlaylist = archiveFileEntiity
            otherPlaylistPresented = true
        })
        .sheet(isPresented: $otherPlaylistPresented) {
            if let f = fileForPlaylist {
                OtherPlaylist(isPresented: $otherPlaylistPresented, archiveFileEntity: f)
            }
        }
        .alert("There is no network connection", isPresented: $showNetworkAlert) {
            Button("OK") {
                showNetworkAlert = false
            }
        }

        .environmentObject(iaPlayer)
    }

}
struct Home_Preview: PreviewProvider {
    static var previews: some View {
        Home()
    }
}
