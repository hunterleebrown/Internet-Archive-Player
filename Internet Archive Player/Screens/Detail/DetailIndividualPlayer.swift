//
//  DetailIndividualPlayer.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/21/24.
//

import SwiftUI
import iaAPI
import AVKit
import Combine

struct DetailIndividualPlayer: View {
    @EnvironmentObject var iaPlayer: Player
    @Environment(\.dismiss) private var dismiss

    var archiveFile: ArchiveFile
    @StateObject private var viewModel: ViewModel

    init(archiveFile: ArchiveFile) {
        self.archiveFile = archiveFile
        _viewModel = StateObject(wrappedValue: ViewModel(archiveFile: archiveFile))
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: min(geometry.size.height * 0.03, 20)) {
                // Album art / Video player area
                ZStack {
                    if viewModel.isVideoFile {
                        if let player = viewModel.player {
                            VideoPlayer(player: player)
                                .frame(height: playerHeight(for: geometry.size))
                                .cornerRadius(12)
                                .shadow(radius: 10)
                        }
                    } else {
                        // Audio visualization
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.fairyRed.opacity(0.3), Color.fairyRed.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: playerHeight(for: geometry.size))
                            
                            VStack(spacing: 16) {
                                Image(systemName: viewModel.isPlaying ? "waveform" : "music.note")
                                    .font(.system(size: iconSize(for: geometry.size)))
                                    .foregroundColor(.fairyCream)
                                    .symbolEffect(.variableColor.iterative, options: .repeating, isActive: viewModel.isPlaying)
                                
                                if viewModel.isPlaying {
                                    Text("Now Playing")
                                        .font(.caption)
                                        .foregroundColor(.fairyCream)
                                }
                            }
                        }
                        .shadow(radius: 10)
                    }
                }
                .padding(.horizontal)

                // Title
                VStack(spacing: 4) {

                    if let title = archiveFile.title, title != archiveFile.name {
                        Text(title)
                            .font(.subheadline)
                            .foregroundColor(.fairyCream)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }

                    Text(archiveFile.name ?? "Unknown Track")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.fairyCream)
                        .lineLimit(2)
                }
                .padding(.horizontal)
                
                // Time slider
                VStack(spacing: 8) {
                    Slider(
                        value: $viewModel.currentTime,
                        in: 0...max(viewModel.duration, 1),
                        onEditingChanged: { editing in
                            viewModel.isSeeking = editing
                            if !editing {
                                viewModel.seek(to: viewModel.currentTime)
                            }
                        }
                    )
                    .tint(.fairyCream)
                    
                    HStack {
                        Text(viewModel.formatTime(viewModel.currentTime))
                            .font(.caption)
                            .foregroundColor(.fairyCream)
                            .monospacedDigit()
                        
                        Spacer()
                        
                        Text(viewModel.formatTime(viewModel.duration))
                            .font(.caption)
                            .foregroundColor(.fairyCream)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, 24)
                
                // Playback controls
                HStack(spacing: geometry.size.width > geometry.size.height ? 60 : 40) {
                    Button {
                        viewModel.seekBackward()
                    } label: {
                        Image(systemName: "gobackward.15")
                            .font(.title)
                            .foregroundColor(.fairyCream)
                    }
                    
                    Button {
                        viewModel.togglePlayPause()
                    } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: playButtonSize(for: geometry.size)))
                            .foregroundColor(.fairyCream)
                    }
                    
                    Button {
                        viewModel.seekForward()
                    } label: {
                        Image(systemName: "goforward.15")
                            .font(.title)
                            .foregroundColor(.fairyCream)
                    }
                }
                .padding(.vertical, min(geometry.size.height * 0.02, 20))
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.fairyRed)
        .presentationDragIndicator(.visible)
        .onAppear {
            iaPlayer.avPlayer.pause()
            viewModel.setupPlayer()
            if let player = viewModel.player {
                viewModel.togglePlayPause()
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
    
    // MARK: - Helper Functions
    
    private func playerHeight(for size: CGSize) -> CGFloat {
        // Use a percentage of the available height, with max/min bounds
        let isLandscape = size.width > size.height
        
        if isLandscape {
            // In landscape, use less vertical space
            return min(size.height * 0.4, 250)
        } else {
            // In portrait, can use more space
            return min(size.height * 0.35, 300)
        }
    }
    
    private func iconSize(for size: CGSize) -> CGFloat {
        let isLandscape = size.width > size.height
        return isLandscape ? 60 : 80
    }
    
    private func playButtonSize(for size: CGSize) -> CGFloat {
        let isLandscape = size.width > size.height
        return isLandscape ? 52 : 64
    }
}

// MARK: - View Model

extension DetailIndividualPlayer {
    @MainActor
    final class ViewModel: ObservableObject {
        var archiveFile: ArchiveFile
        var player: AVPlayer?
        private var timeObserver: Any?
        
        @Published var isPlaying = false
        @Published var currentTime: Double = 0
        @Published var duration: Double = 0
        @Published var isSeeking = false
        
        var isVideoFile: Bool {
            let videoExtensions = ["mp4", "mov", "m4v", "avi", "mkv", "mpg", "mpeg"]
            let fileName = archiveFile.name?.lowercased() ?? ""
            return videoExtensions.contains(where: { fileName.hasSuffix($0) })
        }
        
        init(archiveFile: ArchiveFile) {
            self.archiveFile = archiveFile
        }
        
        func setupPlayer() {
            guard let url = archiveFile.url else { return }
            
            let playerItem = AVPlayerItem(url: url)
            playerItem.preferredForwardBufferDuration = 30.0
            playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
            playerItem.preferredPeakBitRate = 0

            player = AVPlayer(playerItem: playerItem)
            
            // Load duration asynchronously using modern API
            Task { @MainActor in
                do {
                    let duration = try await playerItem.asset.load(.duration)
                    let durationSeconds = duration.seconds
                    if !durationSeconds.isNaN && !durationSeconds.isInfinite {
                        self.duration = durationSeconds
                    }
                } catch {
                    // Duration will be updated by time observer if load fails
                }
            }
            
            // Add simple time observer
            let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
            timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                guard let self = self, !self.isSeeking else { return }
                self.currentTime = time.seconds
                
                // Update duration if we didn't get it initially
                if let currentItem = self.player?.currentItem {
                    let itemDuration = currentItem.duration
                    if itemDuration.isValid, !itemDuration.seconds.isNaN, !itemDuration.seconds.isInfinite, self.duration == 0 {
                        self.duration = itemDuration.seconds
                    }
                }
            }
            
            // Observe when playback ends
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak self] _ in
                self?.isPlaying = false
                self?.player?.seek(to: .zero)
            }
        }
        
        func togglePlayPause() {
            guard let player = player else { return }
            
            if isPlaying {
                player.pause()
                isPlaying = false
            } else {
                player.play()
                isPlaying = true
            }
        }
        
        func seek(to time: Double) {
            let cmTime = CMTime(seconds: time, preferredTimescale: 600)
            player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        
        func seekBackward() {
            let newTime = max(currentTime - 15, 0)
            currentTime = newTime
            seek(to: newTime)
        }
        
        func seekForward() {
            let newTime = min(currentTime + 15, duration)
            currentTime = newTime
            seek(to: newTime)
        }
        
        func formatTime(_ time: Double) -> String {
            guard !time.isNaN && !time.isInfinite else { return "0:00" }
            
            let totalSeconds = Int(time)
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%d:%02d", minutes, seconds)
            }
        }
        
        func cleanup() {
            if let timeObserver = timeObserver {
                player?.removeTimeObserver(timeObserver)
                self.timeObserver = nil
            }
            player?.pause()
            player = nil
            NotificationCenter.default.removeObserver(self)
        }
        
        deinit {
            if let timeObserver = timeObserver {
                player?.removeTimeObserver(timeObserver)
            }
            NotificationCenter.default.removeObserver(self)
        }
    }
}
