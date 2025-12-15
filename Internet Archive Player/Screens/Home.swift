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
import iaAPI

struct Home: View {
    @StateObject var iaPlayer = Player()
    @State var playingFile: ArchiveFileEntity? = nil
    @State var showVideoPlayer: Bool = false
    @State var showVideoPlayerIPad: Bool = false
    @State var showNetworkAlert: Bool = false
    @State var showControls: Bool = false
    @State var showHistory: Bool = false
    @State var maxControlHeight: Bool = true
    @State var otherPlaylistPresented: Bool = false
    @State var selectedTab: Int = 2  // Default to Now Playing tab (index 3)

    static var showControlsPass = PassthroughSubject<Bool, Never>()
    static var controlHeightPass = PassthroughSubject<Bool, Never>()
    static var otherPlaylistPass = PassthroughSubject<ArchiveFileEntity, Never>()
    static var newPlaylistPass = PassthroughSubject<Bool, Never>()

    @State var showingNewPlaylist = false

    @StateObject var viewModel: Home.ViewModel = Home.ViewModel()

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

//                // Favorites Tab
//                NavigationStack {
//                    NewFavoritesView()
//                }
//                .tabItem {
//                    Label("Favorites", systemImage: "heart")
//                }
//                .tag(1)

                // Favorite Archives Tab
                NavigationStack {
                    FavoriteArchivesView()
                }
                .tabItem {
                    Label("Bookmarks", systemImage: "books.vertical")
                }
                .tag(1)

                // Now Playing Tab (Center - Most Prominent)
                NavigationStack {
                    VStack(spacing:0) {
                        topView()
                            .navigationTitle("Now Playing")
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    NavigationLink(destination: ListsView()) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "music.note.list")
                                            Text("Playlists")
                                        }
                                        .foregroundColor(.fairyRed)
                                    }
                                }
                            }
                            .sheet(item: $playingFile, content: { file in
                                if let identifier = file.identifier {
                                    Detail(identifier, isPresented: true)
                                }
                            })
                    }
                    .safeAreaInset(edge: .bottom) {
                        if showControls {
                            Spacer()
                                .frame(height: iaPlayer.playerHeight)
                        }
                    }
                    .navigationBarColor(backgroundColor: Color("playerBackground").opacity(0.5), titleColor: .fairyRed)
                }
                .tabItem {
                    Label("Now Playing", systemImage: "music.note.square.stack.fill")
                }
                .tag(2)

                // Debug Tab
                NavigationStack {
                    DebugView()
                }
                .tabItem {
                    Label("Debug", systemImage: "ant.circle")
                }
                .tag(3)

            }
            .tint(.fairyRed)
            .zIndex(1)

            // PlayerControls above the tab bar
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    PlayerControls(showVideoPlayer: $showVideoPlayer)
                        .padding(5)
                }
                .opacity(showControls ? 1 : 0)
                .frame(maxWidth: 428, minHeight: iaPlayer.playerHeight, maxHeight: iaPlayer.playerHeight, alignment: .top)
//                .clipped()
//                .gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
//                    .onEnded { value in
//                        print(value.translation)
//                        switch(value.translation.width, value.translation.height) {
//                        case (...0, -30...30):  print("left swipe")
//                        case (0..., -30...30):  print("right swipe")
//                        case (-100...100, ...0):
//                            print("up swipe")
//                            Home.controlHeightPass.send(true)
//                        case (-100...100, 0...):  print("down swipe")
//                            Home.controlHeightPass.send(false)
//                        default:  print("no clue")
//                        }
//                    }
//                )
                .padding(.bottom, 59)
            }
            .zIndex(showControls ? 3: 1)


        }
        .onReceive(PlayerControls.showPlayingDetails) { file in
            withAnimation {
                playingFile = file
            }
        }
        .onReceive(PlayerControls.showVideo) { show in
            withAnimation {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    showVideoPlayerIPad = show
                } else {
                    showVideoPlayer = show
                }
            }
        }
        .sheet(isPresented: $showVideoPlayer) {
            // iPhone: Use sheet for better experience
            VideoPlayer(player: iaPlayer.avPlayer)
                .ignoresSafeArea()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(false)  // Allow swipe to dismiss
        }
        .fullScreenCover(isPresented: $showVideoPlayerIPad) {
            // iPad: Full-screen video player with custom dismiss button
            ZStack(alignment: .top) {
                VideoPlayer(player: iaPlayer.avPlayer)
                    .ignoresSafeArea()
                
                // Dismiss button - always visible
                Button(action: {
                    showVideoPlayerIPad = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white, .black.opacity(0.6))
                        .shadow(radius: 4)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .center)
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
        .onReceive(PlayerControls.toggleHistory, perform: { _ in
            showHistory.toggle()
        })
        .sheet(isPresented: $showHistory) {
            HistoryDrawerView(isPresented: $showHistory)
        }
        .sheet(isPresented: $otherPlaylistPresented) {
            if let f = viewModel.archiveFileEntity {
                OtherPlaylist(isPresented: $otherPlaylistPresented, archiveFileEntities: [f])
            }
        }
        .sheet(isPresented: $showingNewPlaylist) {
            NewPlaylist(isPresented: $showingNewPlaylist)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onOpenURL { url in
            print("📂 onOpenURL called with: \(url)")
            print("📂 URL scheme: \(url.scheme ?? "none")")
            print("📂 URL path: \(url.path)")
            viewModel.handleIncomingURL(url, player: iaPlayer)
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
            VStack(alignment: .leading, spacing: 0) {
                // Your combined Text view using string interpolation
                Text("Use the search icon \(Image(systemName: "magnifyingglass")) to find and add files to your library.")
            }
            .padding(10)
            .background(Color.fairyRed)
            .cornerRadius(10)
            .foregroundColor(.fairyCream)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

        } else {
            Playlist()
        }
    }

}

extension Home {
    @MainActor
    class ViewModel: ObservableObject {
        var archiveFileEntity: ArchiveFileEntity?
        
        func handleIncomingURL(_ url: URL, player: Player) {
            print("📂 Received URL: \(url)")
            print("  scheme: \(url.scheme ?? "none")")
            print("  host: \(url.host ?? "none")")
            
            // Handle custom URL scheme (e.g., iaplayer://add?identifier=...)
            if url.scheme == "iaplayer" {
                handleCustomURLScheme(url, player: player)
                return
            }
        }
        
        private func handleCustomURLScheme(_ url: URL, player: Player) {
            guard url.host == "add" else {
                print("⚠️ Unknown URL host: \(url.host ?? "none")")
                return
            }
            
            // Parse query parameters
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems else {
                print("⚠️ No query parameters")
                return
            }
            
            // Convert query items to dictionary
            var params: [String: String] = [:]
            for item in queryItems {
                params[item.name] = item.value
            }
            
            print("📋 URL Parameters:")
            for (key, value) in params {
                print("  \(key): \(value)")
            }
            
            // Create ArchiveFile from parameters
            guard let identifier = params["identifier"] else {
                print("⚠️ Missing required parameter: identifier")
                return
            }
            
            // Build the ArchiveFile
            let archiveFile = ArchiveFile(
                identifier: identifier,
                artist: params["artist"],
                creator: params["creator"]?.components(separatedBy: ","),
                archiveTitle: params["archiveTitle"],
                name: params["name"],
                title: params["title"],
                track: params["track"],
                size: params["size"],
                format: params["format"].flatMap { ArchiveFileFormat(rawValue: $0) },
                length: params["length"],
                source: params["source"] ?? "shared"
            )
            
            print("✅ Created ArchiveFile from URL:")
            print("  identifier: \(archiveFile.identifier ?? "nil")")
            print("  title: \(archiveFile.title ?? "nil")")
            
            // Add to player (same logic as file import)
            do {
                try player.checkDupes(archiveFile: archiveFile, list: player.items, error: .alreadyOnPlaylist)
            } catch PlayerError.alreadyOnPlaylist {
                print("⚠️ Already on playlist")
                return
            } catch {}
            
            player.playFile(archiveFile)
            print("✅ Added to Now Playing")
        }
    }
}

struct Home_Preview: PreviewProvider {
    static var previews: some View {
        Home()
    }
}
