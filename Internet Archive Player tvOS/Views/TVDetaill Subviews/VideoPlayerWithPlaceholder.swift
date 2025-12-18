//
//  VideoPlayerWithPlaceholder.swift
//  Internet Archive Player tvOS
//
//  Created by Hunter Lee Brown on 10/28/23.
//

import SwiftUI
import AVKit
import Combine

struct VideoPlayerWithPlaceholder: View {
    let videoURL: URL
    let placeholderImageURL: URL?
    
    @State private var player: AVPlayer?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            // Placeholder while loading
            if isLoading {
                ZStack {
                    Color.black
                    
                    if let imageURL = placeholderImageURL {
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .opacity(0.5)
                        } placeholder: {
                            ProgressView()
                                .tint(.white)
                        }
                    } else {
                        ProgressView()
                            .tint(.white)
                    }
                    
                    VStack(spacing: 12) {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                        Text("Loading video...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                }
                .ignoresSafeArea()
            }
            
            // Video player
            if let player = player {
                VideoPlayer(player: player)
                    .opacity(isLoading ? 0 : 1)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
    
    private func setupPlayer() {
        let playerItem = AVPlayerItem(url: videoURL)
        
        // Option #2: Increase buffer duration to preload more video data
        playerItem.preferredForwardBufferDuration = 30.0 // Load 30 seconds ahead
        
        // Option #5: Configure player item for better buffering
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        playerItem.preferredPeakBitRate = 0 // Let AVPlayer choose best quality based on network
        
        let newPlayer = AVPlayer(playerItem: playerItem)
        
        // Observe when the player is ready to play
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemNewAccessLogEntry,
            object: playerItem,
            queue: .main
        ) { _ in
            withAnimation {
                isLoading = false
            }
        }
        
        // Also check player status
        playerItem.publisher(for: \.status)
            .sink { status in
                if status == .readyToPlay {
                    withAnimation {
                        isLoading = false
                    }
                }
            }
            .store(in: &cancellables)
        
        self.player = newPlayer
        newPlayer.play()
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}
