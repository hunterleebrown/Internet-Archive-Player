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
    @State private var showingAlert = false
    @State var showVideoPlayer: Bool = false
    @State var showNetworkAlert: Bool = false
    @State var showControls: Bool = false
    @State var maxControlHeight: Bool = true

    static var showControlsPass = PassthroughSubject<Bool, Never>()
    static var controlHeightPass = PassthroughSubject<Bool, Never>()

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
                            if let identifier = file.identifier {
                                Detail(identifier, isPresented: true)
                            }
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
                    VStack(spacing: 0) {
                        ZStack {
                            CustomVideoPlayer()
                                .frame(height: showVideoPlayer ? (geo.size.width / 1.778) : 0 )
                                .zIndex(showVideoPlayer ? 1 : 0)

                            PlayerControls()
                                .zIndex(showVideoPlayer ? 0 : 1)
                        }
                    }
                    .coordinateSpace(name: "controls")
                    .opacity(showControls ? 1 : 0)
                    .padding(10)
                    .frame(maxWidth: 428, maxHeight: maxControlHeight ? nil : 0.5)
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
                }
            }
        }
        .environmentObject(iaPlayer)
    }

}
