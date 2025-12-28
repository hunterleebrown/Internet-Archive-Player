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

enum SelectedTab: Int {
    case browse
    case search
    case home
    case bookmarks
    case settings
}

struct NewPlaylistData: Identifiable {
    let id = UUID()
    let name: String?
}

struct Home: View {
    @StateObject var iaPlayer = Player()
    @StateObject var errorManager = ArchiveErrorManager.shared
    @State var playingFile: ArchiveFileEntity? = nil
    @State var showVideoPlayer: Bool = false
    @State var showVideoPlayerIPad: Bool = false
    @State var showControls: Bool = false
    @State var showHistory: Bool = false
    @State var otherPlaylistPresented: Bool = false
    @State var selectedTab: SelectedTab = .home

    static var showControlsPass = PassthroughSubject<Bool, Never>()
    static var otherPlaylistPass = PassthroughSubject<ArchiveFileEntity, Never>()
    static var newPlaylistPass = PassthroughSubject<String?, Never>()

    static var searchPass = PassthroughSubject<ArchiveMetaData, Never>()
    static var searchPassInternal = PassthroughSubject<ArchiveMetaData, Never>()

    @State var newPlaylistName: NewPlaylistData? = nil

    @StateObject var viewModel: Home.ViewModel = Home.ViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {

            if iaPlayer.playingFile != nil {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showControls.toggle()
                        }
                    }, label: {
                        AnimatedSpeakerWave(isAnimating: !showControls)
                            .foregroundColor(.fairyCream)
                            .padding(2)
                            .frame(width: 44, height: 44, alignment: .leading)
                            .background(Color.fairyRed)
                            .cornerRadius(10)
                    })
                    .padding(.trailing, 10)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.bottom, 59)
                .zIndex(showControls ? 0 : 3)
            }

            TabView(selection: $selectedTab) {
                // Search Tab - First for discovery

                NavigationStack {
                    SearchView()
                }
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(SelectedTab.search)

                NavigationStack {
                    Browse()
                }
                .tabItem {
                    Label("Browse", systemImage: "list.bullet.rectangle")
                }
                .tag(SelectedTab.browse)

                // Now Playing Tab - Where the action happens
                NavigationStack {
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
                        .navigationBarColor(backgroundColor: Color("playerBackground").opacity(0.5), titleColor: .fairyRed)
                }
                .tabItem {
                    Label("Now Playing", systemImage: "play.circle.fill")
                }
                .tag(SelectedTab.home)

                // Bookmarks Tab - Saved favorites
                NavigationStack {
                    FavoriteArchivesView()
                }
                .tabItem {
                    Label("Bookmarks", systemImage: "books.vertical")
                }
                .tag(SelectedTab.bookmarks)

                // Debug Tab
                NavigationStack {
                    DebugView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(SelectedTab.settings)

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
                .padding(.bottom, 59)  // Include tab bar padding in measurement
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: PlayerHeightPreferenceKey.self, value: geometry.size.height)
                            .onAppear {
                                // Ensure height is set when view appears
                                if showControls {
                                    iaPlayer.playerHeight = geometry.size.height
                                }
                            }
                    }
                )
                .onPreferenceChange(PlayerHeightPreferenceKey.self) { height in
                    // Update height with the full measurement including tab bar padding
                    if height > 0 && showControls {
                        iaPlayer.playerHeight = height
                    }
                }
                .onChange(of: showControls) { _, isShowing in
                    if isShowing {
                        // Force layout and height calculation after a brief delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            // By this time, GeometryReader should have measured
                            // If height is still 0, use fallback
                            if iaPlayer.playerHeight == 0 {
                                iaPlayer.playerHeight = 219
                            }
                        }
                    } else {
                        // When hiding, immediately set to 0
                        iaPlayer.playerHeight = 0
                    }
                }
                .opacity(showControls ? 1 : 0)
                .frame(maxWidth: 428)
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
                // Set to 0 immediately when hiding, otherwise let GeometryReader calculate
                if !show {
                    iaPlayer.playerHeight = 0
                } else if iaPlayer.playerHeight == 0 {
                    // Fallback: player controls height + tab bar padding (160 + 59 = 219)
                    iaPlayer.playerHeight = 219
                }
            }
        }
        .onReceive(Home.otherPlaylistPass, perform: { archiveFileEntiity in
            viewModel.archiveFileEntity = archiveFileEntiity
            otherPlaylistPresented = true
        })
        .onReceive(Home.newPlaylistPass, perform: { name in
            newPlaylistName = NewPlaylistData(name: name)
        })
        .onReceive(PlayerControls.toggleHistory, perform: { _ in
            showHistory.toggle()
        })
        .onReceive(Home.searchPass, perform: { collection in
            // First, switch to the search tab
            selectedTab = .search

            // Then, after a brief delay to ensure SearchView is visible,
            // forward the collection to the internal publisher
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                Home.searchPassInternal.send(collection)
            }
        })
        .sheet(isPresented: $showHistory) {
            HistoryDrawerView(isPresented: $showHistory)
                .environmentObject(iaPlayer)
        }
        .sheet(isPresented: $otherPlaylistPresented) {
            if let f = viewModel.archiveFileEntity {
                OtherPlaylist(isPresented: $otherPlaylistPresented, archiveFileEntities: [f])
            }
        }
        .sheet(item: $newPlaylistName) { data in
            NewPlaylist(isPresented: Binding(
                get: { newPlaylistName != nil },
                set: { if !$0 { newPlaylistName = nil } }
            ), initialName: data.name)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onOpenURL { url in
            print("📂 onOpenURL called with: \(url)")
            print("📂 URL scheme: \(url.scheme ?? "none")")
            print("📂 URL path: \(url.path)")
            viewModel.handleIncomingURL(url, player: iaPlayer)
        }
        .archiveErrorOverlay($errorManager.errorMessage)
        .environmentObject(iaPlayer)
    }

    @ViewBuilder func topView() -> some View {
        if iaPlayer.mainPlaylist?.files?.count == 0 {
            VStack(alignment: .center, spacing: 16) {
                Spacer()
                    .frame(height: 80)
                
                Image(systemName: "music.note.list")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary.opacity(0.5))
                
                Text("Nothing Playing")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.primary)
                
                Text("Your Now Playing queue is empty. Search for music and videos from the Internet Archive to start playing, or browse your saved playlists.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: {
                        selectedTab = .search  // Switch to Search tab
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                            Text("Search")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.fairyRed)
                        .cornerRadius(10)
                    }
                    
                    // Navigate to playlists - using the same navigation as toolbar
                    NavigationLink(destination: ListsView()) {
                        HStack(spacing: 6) {
                            Image(systemName: "music.note.list")
                            Text("Playlists")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.fairyRed)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.fairyRed.opacity(0.15))
                        .cornerRadius(10)
                    }
                }
                .padding(.top, 8)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            NowPlaying()
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

// MARK: - Animated Speaker Wave View
struct AnimatedSpeakerWave: View {
    let isAnimating: Bool
    
    @EnvironmentObject private var player: Player
    @State private var currentFrame: Int = 0
    @State private var isPlaying: Bool = false
    
    private let frames = [
        "speaker",
        "speaker.wave.1",
        "speaker.wave.2",
        "speaker.wave.3"
    ]
    
    private let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Image(systemName: iconName)
            .onReceive(timer) { _ in
                if shouldAnimate {
                    currentFrame = (currentFrame + 1) % frames.count
                }
            }
            .onReceive(player.playingPublisher) { playing in
                isPlaying = playing
            }
    }
    
    private var shouldAnimate: Bool {
        isAnimating && isPlaying
    }
    
    private var iconName: String {
        if shouldAnimate {
            return frames[currentFrame]
        } else if isPlaying {
            return "speaker.wave.3"
        } else {
            return "speaker"
        }
    }
}

struct Home_Preview: PreviewProvider {
    static var previews: some View {
        Home()
    }
}
