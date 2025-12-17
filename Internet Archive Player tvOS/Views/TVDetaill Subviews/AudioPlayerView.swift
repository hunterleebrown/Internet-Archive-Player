//
//  AudioPlayerView.swift
//  Internet Archive Player tvOS
//
//  Created by Hunter Lee Brown on 10/28/23.
//

import SwiftUI
import AVKit
import Combine
import iaAPI

struct AudioPlayerView: View {
    let artworkURL: URL?
    
    @StateObject private var viewModel: ViewModel
    
    // Convenience initializer for single file playback
    init(audioFile: ArchiveFile, artworkURL: URL?) {
        self.artworkURL = artworkURL
        _viewModel = StateObject(wrappedValue: ViewModel(audioFile: audioFile, playlist: nil))
    }
    
    // Full initializer with playlist support
    init(audioFile: ArchiveFile, artworkURL: URL?, playlist: [ArchiveFile]?) {
        self.artworkURL = artworkURL
        _viewModel = StateObject(wrappedValue: ViewModel(audioFile: audioFile, playlist: playlist))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color.black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 50) {
                Spacer()
                
                // Album artwork with seek indicator overlay
                ZStack {
                    if let imageURL = artworkURL {
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 600, height: 600)
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 600, height: 600)
                                .overlay(
                                    ProgressView()
                                        .tint(.white)
                                )
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 600, height: 600)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 120))
                                    .foregroundColor(.white.opacity(0.5))
                            )
                    }
                    
                    // Seek indicator overlay
                    if let indicator = viewModel.seekIndicator {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.75))
                                .frame(width: 200, height: 100)
                            
                            Text(indicator)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 600, height: 600)
                
                // Track info
                VStack(spacing: 12) {
                    Text(viewModel.currentTrack.displayTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    if let artist = viewModel.currentTrack.artist ?? viewModel.currentTrack.creator?.joined(separator: ", ") {
                        Text(artist)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Show track position if in playlist mode
                    if viewModel.playlistFiles.count > 1 {
                        Text("Track \(viewModel.currentTrackIndex + 1) of \(viewModel.playlistFiles.count)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // Time progress bar
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.currentTime, total: max(viewModel.duration, 0.1))
                        .progressViewStyle(.linear)
                        .tint(.white)
                        .frame(width: 800)
                    
                    HStack {
                        Text(viewModel.formatTime(viewModel.currentTime))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text(viewModel.formatTime(viewModel.duration))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(width: 800)
                }
                
                // Playback controls
                HStack(spacing: 80) {
                    // Skip to previous track
                    Button(action: viewModel.playPrevious) {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 44))
                    }
                    .disabled(!viewModel.canGoPrevious)
                    
                    // Seek backward 15 seconds
                    Button(action: viewModel.seekBackward) {
                        Image(systemName: "gobackward.\(Int(viewModel.seekInterval))")
                            .font(.system(size: 44))
                    }
                    
                    // Play/Pause button
                    Button(action: viewModel.togglePlayPause) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 44))
                    }
                    
                    // Seek forward 15 seconds
                    Button(action: viewModel.seekForward) {
                        Image(systemName: "goforward.\(Int(viewModel.seekInterval))")
                            .font(.system(size: 44))
                    }
                    
                    // Skip to next track
                    Button(action: viewModel.playNext) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 44))
                    }
                    .disabled(!viewModel.canGoNext)
                }
                .padding(.bottom, 40)
                
                Spacer()
            }
            .padding(.horizontal, 90)
            .padding(.top, 60)
        }
        .onAppear {
            viewModel.setupPlayer()
        }
        .onDisappear {
            viewModel.cleanupPlayer()
        }
    }
}

// MARK: - Audio Player View Model
extension AudioPlayerView {
    @MainActor
    final class ViewModel: ObservableObject {
        // MARK: - Published Properties
        @Published var isPlaying = false
        @Published var currentTime: TimeInterval = 0
        @Published var duration: TimeInterval = 0
        @Published var currentTrackIndex: Int = 0
        @Published var seekIndicator: String? = nil
        
        // MARK: - Public Properties
        let seekInterval: Double = 15
        private(set) var playlistFiles: [ArchiveFile] = []
        
        var currentTrack: ArchiveFile {
            playlistFiles[currentTrackIndex]
        }
        
        var canGoNext: Bool {
            currentTrackIndex < playlistFiles.count - 1
        }
        
        var canGoPrevious: Bool {
            currentTrackIndex > 0
        }
        
        // MARK: - Private Properties
        private var player: AVPlayer?
        private var timeObserverToken: Any?
        private var cancellables = Set<AnyCancellable>()
        
        // MARK: - Initialization
        init(audioFile: ArchiveFile, playlist: [ArchiveFile]?) {
            // Initialize playlist
            if let playlist = playlist {
                self.playlistFiles = playlist
                // Find the starting index
                if let index = playlist.firstIndex(where: { $0.name == audioFile.name }) {
                    self.currentTrackIndex = index
                }
            } else {
                self.playlistFiles = [audioFile]
                self.currentTrackIndex = 0
            }
        }
        
        // MARK: - Public Methods
        func setupPlayer() {
            guard let url = currentTrack.url else { return }
            
            let playerItem = AVPlayerItem(url: url)
            let newPlayer = AVPlayer(playerItem: playerItem)
            
            // Observe player status to get duration
            playerItem.publisher(for: \.status)
                .sink { [weak self] status in
                    guard let self = self else { return }
                    if status == .readyToPlay {
                        let durationSeconds = playerItem.duration.seconds
                        if !durationSeconds.isNaN && durationSeconds.isFinite {
                            self.duration = durationSeconds
                        }
                    }
                }
                .store(in: &cancellables)
            
            // Observe when track finishes to auto-advance
            NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    if self.canGoNext {
                        self.playNext()
                    } else {
                        self.isPlaying = false
                    }
                }
                .store(in: &cancellables)
            
            // Add periodic time observer
            let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            timeObserverToken = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                guard let self = self else { return }
                let timeSeconds = time.seconds
                if !timeSeconds.isNaN && timeSeconds.isFinite {
                    self.currentTime = timeSeconds
                }
            }
            
            self.player = newPlayer
            newPlayer.play()
            isPlaying = true
        }
        
        func cleanupPlayer() {
            if let token = timeObserverToken {
                player?.removeTimeObserver(token)
                timeObserverToken = nil
            }
            player?.pause()
            player = nil
            cancellables.removeAll()
        }
        
        func togglePlayPause() {
            guard let player = player else { return }
            
            if isPlaying {
                player.pause()
            } else {
                player.play()
            }
            isPlaying.toggle()
        }
        
        func playNext() {
            guard canGoNext else { return }
            currentTrackIndex += 1
            loadAndPlayCurrentTrack()
        }
        
        func playPrevious() {
            guard canGoPrevious else { return }
            currentTrackIndex -= 1
            loadAndPlayCurrentTrack()
        }
        
        func seekForward() {
            guard let player = player else { return }
            let currentTime = player.currentTime()
            let seekTime = CMTimeAdd(currentTime, CMTime(seconds: seekInterval, preferredTimescale: 1))
            
            // Make sure we don't seek past the end
            if let duration = player.currentItem?.duration, seekTime < duration {
                player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
            } else if let duration = player.currentItem?.duration {
                // If we'd go past the end, just go to the end
                player.seek(to: duration, toleranceBefore: .zero, toleranceAfter: .zero)
            }
            
            // Show visual feedback
            showSeekIndicator("+\(Int(seekInterval))s")
        }
        
        func seekBackward() {
            guard let player = player else { return }
            let currentTime = player.currentTime()
            let seekTime = CMTimeSubtract(currentTime, CMTime(seconds: seekInterval, preferredTimescale: 1))
            
            // Make sure we don't seek before the beginning
            if seekTime > .zero {
                player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
            } else {
                // If we'd go before the start, just go to the beginning
                player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
            }
            
            // Show visual feedback
            showSeekIndicator("-\(Int(seekInterval))s")
        }
        
        func formatTime(_ time: TimeInterval) -> String {
            guard time.isFinite && !time.isNaN else { return "0:00" }
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
        
        // MARK: - Private Methods
        private func loadAndPlayCurrentTrack() {
            // Clean up current player
            cleanupPlayer()
            
            // Reset state
            currentTime = 0
            duration = 0
            
            // Setup new player for current track
            setupPlayer()
        }
        
        private func showSeekIndicator(_ text: String) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                seekIndicator = text
            }
            
            // Hide after 1 second
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                withAnimation(.easeOut(duration: 0.2)) {
                    seekIndicator = nil
                }
            }
        }
    }
}
