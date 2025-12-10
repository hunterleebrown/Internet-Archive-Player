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

struct Home: View {
    @StateObject var iaPlayer = Player()
    @State var playingFile: ArchiveFileEntity? = nil
    @State var showVideoPlayer: Bool = false
    @State var showNetworkAlert: Bool = false
    @State var showControls: Bool = false
    @State var maxControlHeight: Bool = true
    @State var otherPlaylistPresented: Bool = false
    @State var selectedTab: Int = 2  // Default to Now Playing tab (index 2)

    static var showControlsPass = PassthroughSubject<Bool, Never>()
    static var controlHeightPass = PassthroughSubject<Bool, Never>()
    static var otherPlaylistPass = PassthroughSubject<ArchiveFileEntity, Never>()
    static var newPlaylistPass = PassthroughSubject<Bool, Never>()

    @State var showingNewPlaylist = false

    var viewModel: Home.ViewModel = Home.ViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {

            if iaPlayer.playingFile != nil {
                VStack(alignment: .trailing) {

                    Button(action: {
                        withAnimation {
                            showControls.toggle()
                        }
                    }, label: {
                        Image(systemName: "rectangle.expand.vertical")
                            .foregroundColor(.fairyRed)
                            .frame(maxWidth: 44, maxHeight: 44)
                            .background(Color.fairyCream)
                            .cornerRadius(10)
                    })
                }
                .padding(.trailing, 10)
                .padding(.bottom, 59)
                .zIndex(showControls ? 0 : 3)
            }

            TabView(selection: $selectedTab) {
                // Search Tab
                NavigationStack {
                    SearchView()
                }
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(0)
                
                // Lists Tab
                NavigationStack {
                    ListsView()
                }
                .tabItem {
                    Label("Lists", systemImage: "music.note.list")
                }
                .tag(1)
                
                // Now Playing Tab (Center - Most Prominent)
                NavigationStack {
                    VStack(spacing:0) {
                        topView()
                            .navigationTitle("Now Playing")
                            .sheet(item: $playingFile, content: { file in
                                if let identifier = file.identifier {
                                    Detail(identifier, isPresented: true)
                                }
                            })
                    }
                    .safeAreaInset(edge: .bottom) {
                        if showControls {
                            Color.clear
                                .frame(height: iaPlayer.playerHeight)
                        }
                    }
                    .navigationBarColor(backgroundColor: Color("playerBackground").opacity(0.5), titleColor: .fairyRed)
                }
                .tabItem {
                    Label("Now Playing", systemImage: "music.note.square.stack.fill")
                }
                .tag(2)
                
                // Favorites Tab
                NavigationStack {
                    NewFavoritesView()
                }
                .tabItem {
                    Label("Favorites", systemImage: "heart")
                }
                .tag(3)
                
                // Debug Tab
                NavigationStack {
                    DebugView()
                }
                .tabItem {
                    Label("Debug", systemImage: "ant.circle")
                }
                .tag(4)

            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    PlayerControls(showVideoPlayer: $showVideoPlayer)
                        .padding(5)
                }
                .opacity(showControls ? 1 : 0)
                .frame(maxWidth: 428, alignment: .top)
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
                .padding(.bottom, 49)

            }
            .tint(.fairyRed)
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
        .sheet(isPresented: $showVideoPlayer) {
            VideoPlayer(player: iaPlayer.avPlayer)
                .ignoresSafeArea()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(false)  // Allow swipe to dismiss
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

    @ViewBuilder func topView() -> some View {
        if iaPlayer.mainPlaylist?.files?.count == 0 {
            ZStack(alignment: .top) {
                VStack {
                    // Your combined Text view
                    Text("Use the search icon ")
                        + Text(Image(systemName: "magnifyingglass"))
                        + Text(" to find and add files to your library.")
                }
                .padding(10)
                .background(Color.fairyRed)
                .cornerRadius(10)
            }
            .foregroundColor(.fairyCream)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)


        } else {
            Playlist()
        }
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
