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
    @State var otherPlaylistPresented: Bool = false

    static var showControlsPass = PassthroughSubject<Bool, Never>()
    static var controlHeightPass = PassthroughSubject<Bool, Never>()
    static var otherPlaylistPass = PassthroughSubject<ArchiveFileEntity, Never>()
    static var newPlaylistPass = PassthroughSubject<Bool, Never>()

    @State var showingNewPlaylist = false

    var viewModel: Home.ViewModel = Home.ViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ZStack {
                    ZStack(alignment: .topTrailing) {
                        PlayerButton(.hidePlay, CGSize(width: 20, height: 20)) {
                            withAnimation{
                                Home.showControlsPass.send(false)
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 40)
                        .frame(width: 20, alignment: .trailing)
                        .zIndex(5)

                        CustomVideoPlayer()
                            .frame(height: showVideoPlayer ? 160 : 0 )
                    }
                    .zIndex(showVideoPlayer ? 1 : 0)
                    PlayerControls()
                        .zIndex(showVideoPlayer ? 0 : 1)
                        .padding(5)
                }
            }
            .opacity(showControls ? 1 : 0)
            .frame(maxWidth: 428, maxHeight: iaPlayer.playerHeight, alignment: .top)
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
            .zIndex(showControls ? 3: 1)


            if iaPlayer.playingFile != nil {
                VStack(alignment: .trailing) {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                showControls.toggle()
                            }
                        }, label: {
                            Image(systemName: "play")
                                .foregroundColor(.fairyRed)
                                .frame(maxWidth: 44, maxHeight: 44)
                                .background(Color.fairyCream)
                                .cornerRadius(10)
                        })
                    }
                }
                .padding(.trailing, 50)
                .zIndex(showControls ? 0 : 3)
            }

            NavigationStack {
                VStack(spacing:0) {
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
                            .frame(height: showControls ? iaPlayer.playerHeight : 0)
                    }
                }

                .navigationBarColor(backgroundColor: Color("playerBackground").opacity(0.5), titleColor: .fairyRed)
            }
            .zIndex(1)


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
            iaPlayer.playerHeight = show ? 160 : 58
            withAnimation {
                maxControlHeight = show
            }
        })
        .onReceive(Home.otherPlaylistPass, perform: { archiveFileEntiity in
            viewModel.archiveFileEntity = archiveFileEntiity
            otherPlaylistPresented = true
        })
        .onReceive(Home.newPlaylistPass, perform: { show in
            showingNewPlaylist = true
        })
        .sheet(isPresented: $otherPlaylistPresented) {
            if let f = viewModel.archiveFileEntity {
                OtherPlaylist(isPresented: $otherPlaylistPresented, archiveFileEntities: [f])
            }
        }
        .sheet(isPresented: $showingNewPlaylist) {
            NewPlaylist(isPresented: $showingNewPlaylist)
        }
        .alert("There is no network connection", isPresented: $showNetworkAlert) {
            Button("OK") {
                showNetworkAlert = false
            }
        }
        .environmentObject(iaPlayer)
    }

}

extension Home {
    class ViewModel {
        var archiveFileEntity: ArchiveFileEntity?
    }
}

struct Home_Preview: PreviewProvider {
    static var previews: some View {
        Home()
    }
}
