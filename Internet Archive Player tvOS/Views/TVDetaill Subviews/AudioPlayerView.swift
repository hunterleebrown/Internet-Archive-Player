//
//  AudioPlayerView.swift
//  Internet Archive Player tvOS
//
//  Created by Hunter Lee Brown on 10/28/23.
//

import SwiftUI
import AVKit
import Combine
import MediaPlayer
import iaAPI

struct AudioPlayerView: View {
    let artworkURL: URL?
    let archiveDoc: ArchiveMetaData

    @StateObject private var viewModel: ViewModel
    
    // Convenience initializer for single file playback
    init(audioFile: ArchiveFile, artworkURL: URL?, archiveDoc: ArchiveMetaData) {
        self.artworkURL = artworkURL
        self.archiveDoc = archiveDoc
        _viewModel = StateObject(wrappedValue: ViewModel(audioFile: audioFile, playlist: nil))
    }
    
    // Full initializer with playlist support
    init(audioFile: ArchiveFile, artworkURL: URL?, archiveDoc: ArchiveMetaData, playlist: [ArchiveFile]?) {
        self.artworkURL = artworkURL
        self.archiveDoc = archiveDoc
        _viewModel = StateObject(wrappedValue: ViewModel(audioFile: audioFile, playlist: playlist))
    }
    
    // MARK: - Playlist View
    private var playlistView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "music.note.list")
                    .font(.body)
                Text("Up Next")
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Playlist items with ScrollViewReader for auto-scrolling
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(viewModel.playlistFiles.enumerated()), id: \.element.name) { index, file in
                            playlistRow(for: file, at: index)
                                .id(index) // Add ID for scrolling
                        }
                    }
                }
                .onChange(of: viewModel.currentTrackIndex) { oldValue, newValue in
                    // Scroll to currently playing track with animation
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
                .onAppear {
                    // Scroll to current track on appear
                    proxy.scrollTo(viewModel.currentTrackIndex, anchor: .center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.black.opacity(0.4))
                .blur(radius: 6)
        )
        .allowsHitTesting(false) // Make playlist non-interactive
        .clipped() // Ensure content doesn't go out of bounds
    }
    
    private func playlistRow(for file: ArchiveFile, at index: Int) -> some View {
        HStack(spacing: 8) {
            // Playing indicator
            if index == viewModel.currentTrackIndex {
                Image(systemName: viewModel.isPlaying ? "speaker.wave.2.fill" : "pause.fill")
                    .font(.system(size: 14))
                    .frame(width: 20)
            } else {
                Text("\(index + 1)")
                    .font(.system(size: 13))
                    .frame(width: 20)
            }
            
            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(file.displayTitle)
                    .font(.system(size: 20))
                    .lineLimit(1)
                
                if let artist = file.artist ?? file.creator?.joined(separator: ", ") {
                    Text(artist)
                        .font(.system(size: 18))
                        .opacity(0.8)
                        .lineLimit(1)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            index == viewModel.currentTrackIndex
                ? Color.white.opacity(0.15)
                : Color.clear
        )
    }
    
    var body: some View {
        ZStack {
            // Animated pastel gradient background
            LinearGradient(
                colors: viewModel.currentGradientColors,
                startPoint: viewModel.gradientStartPoint,
                endPoint: viewModel.gradientEndPoint
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 2.0), value: viewModel.currentGradientColors)
            
            // Two-column layout
            HStack(spacing: 0) {
                // Left side: Playlist (only show if more than 1 track)
                if viewModel.playlistFiles.count > 1 {
                    playlistView
                        .frame(width: 380)
                }
                
                // Right side: Main content
                VStack(spacing: 0) {
                    // Archive title (if available)
                    if let archiveTitle = archiveDoc.archiveTitle {
                        Text(archiveTitle)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 90)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.4))
                                    .blur(radius: 10)
                            )
                            .padding(.bottom, 15)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Album artwork with seek indicator overlay
                    ZStack {
                        if let imageURL = artworkURL {
                            AsyncImage(url: imageURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 450, height: 450)
                                    .cornerRadius(20)
                                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 450, height: 450)
                                    .overlay(
                                        ProgressView()
                                            .tint(.white)
                                    )
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 450, height: 450)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 120))
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
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(width: 450, height: 450)
                    .padding(.bottom, 20)
                    
                    // Track info
                    VStack(spacing: 6) {
                        Text(viewModel.currentTrack.displayTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        if let artist = viewModel.currentTrack.artist ?? viewModel.currentTrack.creator?.joined(separator: ", ") {
                            Text(artist)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                        }
                        
                        // Show track position if in playlist mode
                        if viewModel.playlistFiles.count > 1 {
                            Text("Track \(viewModel.currentTrackIndex + 1) of \(viewModel.playlistFiles.count)")
                                .font(.caption)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.35))
                            .blur(radius: 8)
                    )
                    .padding(.bottom, 20)
                    
                    // Time progress bar
                    VStack(spacing: 6) {
                        ProgressView(value: viewModel.currentTime, total: max(viewModel.duration, 0.1))
                            .progressViewStyle(.linear)
                            .tint(.white)
                            .frame(width: 800)
                        
                        HStack {
                            Text(viewModel.formatTime(viewModel.currentTime))
                                .font(.caption)
                            
                            Spacer()
                            
                            Text(viewModel.formatTime(viewModel.duration))
                                .font(.caption)
                        }
                        .frame(width: 800)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.25))
                            .blur(radius: 8)
                    )
                    .padding(.bottom, 20)
                    
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
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.4))
                            .blur(radius: 10)
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onPlayPauseCommand {
            print("this is magic")
            viewModel.togglePlayPause()
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
        var audioFile: ArchiveFile
        @Published var isPlaying = false
        @Published var currentTime: TimeInterval = 0
        @Published var duration: TimeInterval = 0
        @Published var currentTrackIndex: Int = 0
        @Published var seekIndicator: String? = nil
        @Published var currentGradientColors: [Color] = []
        @Published var gradientStartPoint: UnitPoint = .topLeading
        @Published var gradientEndPoint: UnitPoint = .bottomTrailing
        
        // MARK: - Public Properties
        let seekInterval: Double = 15
        private(set) var playlistFiles: [ArchiveFile] = []
        
        // Pastel color palette
        private let pastelColors: [Color] = [
            Color(red: 1.0, green: 0.8, blue: 0.8),      // Pastel pink
            Color(red: 1.0, green: 0.9, blue: 0.8),      // Pastel peach
            Color(red: 1.0, green: 1.0, blue: 0.8),      // Pastel yellow
            Color(red: 0.8, green: 1.0, blue: 0.8),      // Pastel mint
            Color(red: 0.8, green: 1.0, blue: 1.0),      // Pastel cyan
            Color(red: 0.8, green: 0.9, blue: 1.0),      // Pastel sky blue
            Color(red: 0.9, green: 0.8, blue: 1.0),      // Pastel lavender
            Color(red: 1.0, green: 0.8, blue: 1.0),      // Pastel magenta
            Color(red: 1.0, green: 0.85, blue: 0.9),     // Pastel rose
            Color(red: 0.85, green: 0.9, blue: 1.0),     // Pastel periwinkle
            Color(red: 0.9, green: 1.0, blue: 0.85),     // Pastel lime
            Color(red: 1.0, green: 0.95, blue: 0.85)     // Pastel cream
        ]
        
        private let gradientPoints: [(UnitPoint, UnitPoint)] = [
            (.topLeading, .bottomTrailing),
            (.top, .bottom),
            (.topTrailing, .bottomLeading),
            (.leading, .trailing),
            (.bottomLeading, .topTrailing),
            (.bottom, .top)
        ]
        
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
        private var gradientTimer: Timer?
        private var lastGradientChangeTime: TimeInterval = 0
        
        // MARK: - Initialization
        init(audioFile: ArchiveFile, playlist: [ArchiveFile]?) {
            self.audioFile = audioFile

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
            
            // Initialize with first gradient
            generateNewGradient()
        }
        
        // MARK: - Public Methods
        func setupPlayer() {
            guard let url = currentTrack.url else { return }
            
            // Configure audio session for remote control
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Failed to set up audio session: \(error)")
            }
            
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
                    
                    // Check if we should generate a new gradient (every 10 seconds while playing)
                    if self.isPlaying && (timeSeconds - self.lastGradientChangeTime) >= 10.0 {
                        self.generateNewGradient()
                        self.lastGradientChangeTime = timeSeconds
                    }
                }
            }
            
            self.player = newPlayer
            newPlayer.play()
            isPlaying = true
            
            // Setup remote command center
            setupRemoteTransportControls()
            
            // Update Now Playing info
            updateNowPlayingInfo()
            
            // Reset gradient timer
            lastGradientChangeTime = 0
        }
        
        func cleanupPlayer() {
            if let token = timeObserverToken {
                player?.removeTimeObserver(token)
                timeObserverToken = nil
            }
            player?.pause()
            player = nil
            cancellables.removeAll()
            
            // Stop gradient timer
            gradientTimer?.invalidate()
            gradientTimer = nil
            
            // Clean up remote command center
            let commandCenter = MPRemoteCommandCenter.shared()
            commandCenter.playCommand.removeTarget(nil)
            commandCenter.pauseCommand.removeTarget(nil)
            commandCenter.togglePlayPauseCommand.removeTarget(nil)
            commandCenter.nextTrackCommand.removeTarget(nil)
            commandCenter.previousTrackCommand.removeTarget(nil)
            commandCenter.skipForwardCommand.removeTarget(nil)
            commandCenter.skipBackwardCommand.removeTarget(nil)
            
            // Clear Now Playing info
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        }
        
        func togglePlayPause() {
            guard let player = player else { return }
            
            if isPlaying {
                player.pause()
            } else {
                player.play()
            }
            isPlaying.toggle()
            
            // Update Now Playing info when state changes
            updateNowPlayingInfo()
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
        private func setupRemoteTransportControls() {
            let commandCenter = MPRemoteCommandCenter.shared()
            

            // Enable and configure play command
            commandCenter.playCommand.isEnabled = true
            commandCenter.playCommand.addTarget { [weak self] event in
                guard let self = self else {
                    return .commandFailed
                }
                
                Task { @MainActor in
                    self.player?.play()
                    self.isPlaying = true
                    self.updateNowPlayingInfo()
                }
                
                return .success
            }
            
            // Enable and configure pause command  
            commandCenter.pauseCommand.isEnabled = true
            commandCenter.pauseCommand.addTarget { [weak self] event in
                guard let self = self else {
                    return .commandFailed
                }
                
                Task { @MainActor in
                    self.player?.pause()
                    self.isPlaying = false
                    self.updateNowPlayingInfo()
                }
                
                return .success
            }
            
            // Enable and configure toggle play/pause command
            commandCenter.togglePlayPauseCommand.isEnabled = true
            commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
                guard let self = self else {
                    return .commandFailed
                }
                
                Task { @MainActor in
                    self.togglePlayPause()
                }
                
                return .success
            }
            
            // Next track command
            commandCenter.nextTrackCommand.isEnabled = true
            commandCenter.nextTrackCommand.addTarget { [weak self] event in
                guard let self = self else { return .commandFailed }
                
                Task { @MainActor in
                    if self.canGoNext {
                        self.playNext()
                    }
                }
                
                return .success
            }
            
            // Previous track command
            commandCenter.previousTrackCommand.isEnabled = true
            commandCenter.previousTrackCommand.addTarget { [weak self] event in
                guard let self = self else { return .commandFailed }
                
                Task { @MainActor in
                    if self.canGoPrevious {
                        self.playPrevious()
                    }
                }
                
                return .success
            }
            
            // Skip forward command
            commandCenter.skipForwardCommand.isEnabled = true
            commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: seekInterval)]
            commandCenter.skipForwardCommand.addTarget { [weak self] event in
                guard let self = self else { return .commandFailed }
                
                Task { @MainActor in
                    self.seekForward()
                }
                
                return .success
            }
            
            // Skip backward command
            commandCenter.skipBackwardCommand.isEnabled = true
            commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: seekInterval)]
            commandCenter.skipBackwardCommand.addTarget { [weak self] event in
                guard let self = self else { return .commandFailed }
                
                Task { @MainActor in
                    self.seekBackward()
                }
                
                return .success
            }
            
        }
        
        private func loadAndPlayCurrentTrack() {
            // Clean up current player
            cleanupPlayer()
            
            // Reset state
            currentTime = 0
            duration = 0
            
            // Generate new gradient for new track
            generateNewGradient()
            
            // Setup new player for current track
            setupPlayer()
        }
        
        private func generateNewGradient() {
            // Select 3-4 random pastel colors
            let colorCount = Int.random(in: 3...4)
            var selectedColors: [Color] = []
            
            // Create a shuffled copy of available colors
            var availableColors = pastelColors.shuffled()
            
            for _ in 0..<colorCount {
                if !availableColors.isEmpty {
                    selectedColors.append(availableColors.removeFirst())
                }
            }
            
            // Select random gradient points
            let randomPoints = gradientPoints.randomElement() ?? (.topLeading, .bottomTrailing)
            
            currentGradientColors = selectedColors
            gradientStartPoint = randomPoints.0
            gradientEndPoint = randomPoints.1
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
        
        private func updateNowPlayingInfo() {
            var nowPlayingInfo = [String: Any]()
            
            // Set track metadata
            nowPlayingInfo[MPMediaItemPropertyTitle] = currentTrack.displayTitle
            
            if let artist = currentTrack.artist ?? currentTrack.creator?.joined(separator: ", ") {
                nowPlayingInfo[MPMediaItemPropertyArtist] = artist
            }
            
            // Set playback position and duration
            if let player = player, let currentItem = player.currentItem {
                let currentTime = currentItem.currentTime().seconds
                let duration = currentItem.duration.seconds
                
                if !currentTime.isNaN && currentTime.isFinite {
                    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
                }
                
                if !duration.isNaN && duration.isFinite {
                    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
                }
            }
            
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
            
            // Set the now playing info
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
}
