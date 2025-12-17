//
//  TVDetail.swift
//  Internet Archive Player tvOS
//
//  Created by Hunter Lee Brown on 10/28/23.
//

import Foundation
import SwiftUI
import iaAPI
import AVKit
import Combine

struct TVDetail: View {

    @Environment(\.presentationMode) var presentation
    @StateObject private var viewModel = DetailViewModel()

    var doc: ArchiveMetaData
    static var backgroundPass = PassthroughSubject<URL, Never>()

    @State var imageUrl: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero section with artwork and title (fixed at top)
            HStack(alignment: .top, spacing: 60) {
                // Album artwork
                if let imageUrl = imageUrl {
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 400, height: 400)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.8), radius: 30, x: 0, y: 15)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 400, height: 400)
                            .overlay(
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(2)
                            )
                    }
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 400, height: 400)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 120))
                                .foregroundColor(.white.opacity(0.3))
                        )
                }
                
                // Title and metadata
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(doc.archiveTitle ?? "Untitled")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if let artist = self.viewModel.archiveDoc?.artist ?? self.viewModel.archiveDoc?.creator?.joined(separator: ", "), !artist.isEmpty {
                            Text(artist)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                        }
                    }
                    
                    // Additional metadata
                    VStack(alignment: .leading, spacing: 8) {
                        if let publisher = doc.publisher, !publisher.isEmpty {
                            MetadataRow(label: "Publisher", value: publisher.joined(separator: ", "))
                        }
                    }
                                        
                    // Description button
                    if (self.viewModel.archiveDoc?.description) != nil {
                        NavigationLink {
                            if let goodDoc = viewModel.archiveDoc {
                                DetailDescription(doc: goodDoc)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "text.alignleft")
                                Text("Read Description")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .cornerRadius(12)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 60)
            .padding(.top, 60)
            .padding(.bottom, 40)
            
            // Files section (scrollable lists)
            if self.viewModel.movieFiles.count > 0 || self.viewModel.audioFiles.count > 0 {
                HStack(alignment: .top, spacing: 40) {
                    // Video files list (left side)
                    if self.viewModel.movieFiles.count > 0 {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Videos")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            List {
                                ForEach(self.viewModel.movieFiles, id: \.self) { file in
                                    NavigationLink {
                                        VideoPlayerWithPlaceholder(
                                            videoURL: file.url!,
                                            placeholderImageURL: imageUrl
                                        )
                                    } label: {
                                        FileRow(file: file)
                                    }
                                }
                            }
                            .listStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Audio files list (right side)
                    if self.viewModel.audioFiles.count > 0 {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Audio")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            List {
                                ForEach(self.viewModel.audioFiles, id: \.self) { file in
                                    NavigationLink {
                                        AudioPlayerView(
                                            audioFile: file,
                                            artworkURL: imageUrl,
                                            playlist: self.viewModel.audioFiles
                                        )
                                    } label: {
                                        FileRow(file: file)
                                    }
                                }
                            }
                            .listStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 60)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Blurred background image
                if let imageUrl = imageUrl {
                    GeometryReader { geometry in
                        AsyncImage(url: imageUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                                .clipped()
                                .blur(radius: 30)
                                .opacity(0.4)
                        } placeholder: {
                            Color.clear
                        }
                    }
                }
                
                // Dark overlay for text readability
                LinearGradient(
                    colors: [Color.black.opacity(0.7), Color.black.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
        .onReceive(TVDetail.backgroundPass) { url in
            withAnimation(.linear(duration: 0.3)) {
                imageUrl = url
            }
        }
        .onAppear() {
            if let identifier = doc.identifier {
                self.viewModel.getArchiveDoc(identifier: identifier)
            }
        }
    }
}

// MARK: - Supporting Views
struct FlowingCollectionsView: View {
    let collections: [Archive]
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(Array(collections.prefix(12).enumerated()), id: \.element.id) { index, archive in
                if let metadata = archive.metadata {
                    HStack(spacing: 8) {
                        // Collection thumbnail
                        AsyncImage(url: metadata.iconUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "folder")
                                        .font(.caption)
                                        .opacity(0.5)
                                )
                        }
                        
                        // Collection title
                        Text(metadata.archiveTitle ?? "Collection")
                            .font(.caption)
                            .opacity(0.9)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
            }
        }
    }
}

// Custom flow layout that wraps horizontally
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

private struct InfoBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundColor(.white.opacity(0.9))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.15))
        .cornerRadius(8)
    }
}

private struct MetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label + ":")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.callout)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(2)
        }
    }
}

private struct FileRow: View {
    let file: ArchiveFile
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: file.isVideo ? "play.rectangle.fill" : "music.note")
                .font(.title2)
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.15))
                .cornerRadius(10)
            
            // File info
            VStack(alignment: .leading, spacing: 4) {
                Text(file.displayTitle)
                    .font(.body)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(file.isVideo ? "Video" : "Audio")
                        .font(.caption)
                        .textCase(.uppercase)
                    
                    if let length = file.length, !length.isEmpty {
                        Text("•")
                        Text(length)
                            .font(.caption)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .listRowBackground(Color.white.opacity(0.05))
    }
}

extension TVDetail {

    final class DetailViewModel: ObservableObject {
        let service: PlayerArchiveService
        @Published var archiveDoc: ArchiveMetaData? = nil
        @Published var audioFiles = [ArchiveFile]()
        @Published var movieFiles = [ArchiveFile]()
        @Published var playlistArchiveFiles: [ArchiveFile]?
        @Published var backgroundIconUrl: URL = URL(string: "http://archive.org")!
        @Published var uiImage: UIImage?

        var player: AVPlayer? = nil

        private var cancellables = Set<AnyCancellable>()

        init() {
            self.service = PlayerArchiveService()
        }


        public func getArchiveDoc(identifier: String){
            Task { @MainActor in
                do {
                    let doc = try await self.service.getArchiveAsync(with: identifier)
                    self.archiveDoc = doc.metadata
                    self.audioFiles = doc.non78Audio.sorted{
                        guard let track1 = $0.track, let track2 = $1.track else { return false}
                        return track1 < track2
                    }

                    let video = doc.files.filter{ $0.isVideo }
                    if video.count > 0 {
                        self.movieFiles = desiredVideo(files:video)
                    }

                    if let art = doc.preferredAlbumArt {
                        //self.backgroundIconUrl = icon
                        TVDetail.backgroundPass.send(art)
                        //                        self.uiImage = await IAMediaUtils.getImage(url: art)
                    }
                } catch {
                    print(error)
                }
            }
        }

        private func desiredVideo(files: [ArchiveFile]) -> [ArchiveFile] {

            var goodFiles: [String: [ArchiveFile]] = [:]

            ArchiveFileFormat.allCases.forEach { format in
                goodFiles[format.rawValue] = files.filter {$0.format == format}
            }

            if let h264HD = goodFiles[ArchiveFileFormat.h264HD.rawValue], !h264HD.isEmpty{
                return h264HD
            }

            if let h264 = goodFiles[ArchiveFileFormat.h264.rawValue], !h264.isEmpty{
                return h264
            }

            if let h264IA = goodFiles[ArchiveFileFormat.h264IA.rawValue], !h264IA.isEmpty{
                return h264IA
            }

            if let mpg512 = goodFiles[ArchiveFileFormat.mpg512kb.rawValue], !mpg512.isEmpty{
                return mpg512
            }

            if let mp4HiRes = goodFiles[ArchiveFileFormat.mp4HiRes.rawValue], !mp4HiRes.isEmpty{
                return mp4HiRes
            }

            return files
        }

        public func sortedAudioFiles() -> [ArchiveFile] {
            return audioFiles.sorted { lf, rf in
                if let lTrack = Int(lf.track ?? ""), let rTrack = Int(rf.track ?? "") {
                    return lTrack < rTrack
                }
                return false
            }
        }

        public func previewAudio(file: ArchiveFile) {
            guard let url = file.url else { return }
            let item = AVPlayerItem(url: url)
            self.player = AVPlayer(playerItem: item)
            if let player = self.player {
                player.play()
            }
        }

        public func stopPreview() {
            guard let player = self.player else { return }
            player.pause()
            self.player = nil
        }
    }

}
// MARK: - Video Player with Placeholder
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

// MARK: - Audio Player View
struct AudioPlayerView: View {
    let audioFile: ArchiveFile
    let artworkURL: URL?
    let playlist: [ArchiveFile]? // Optional playlist
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var timeObserverToken: Any?
    @State private var currentTrackIndex: Int = 0
    @State private var playlistFiles: [ArchiveFile] = []
    @State private var seekIndicator: String? = nil // For showing +15s/-15s feedback
    
    // Seek interval in seconds (configurable)
    private let seekInterval: Double = 15
    
    // Convenience initializer for single file playback
    init(audioFile: ArchiveFile, artworkURL: URL?) {
        self.audioFile = audioFile
        self.artworkURL = artworkURL
        self.playlist = nil
    }
    
    // Full initializer with playlist support
    init(audioFile: ArchiveFile, artworkURL: URL?, playlist: [ArchiveFile]?) {
        self.audioFile = audioFile
        self.artworkURL = artworkURL
        self.playlist = playlist
    }
    
    var currentTrack: ArchiveFile {
        playlistFiles.isEmpty ? audioFile : playlistFiles[currentTrackIndex]
    }
    
    var canGoNext: Bool {
        currentTrackIndex < playlistFiles.count - 1
    }
    
    var canGoPrevious: Bool {
        currentTrackIndex > 0
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
                    if let indicator = seekIndicator {
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
                    Text(currentTrack.displayTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    if let artist = currentTrack.artist ?? currentTrack.creator?.joined(separator: ", ") {
                        Text(artist)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Show track position if in playlist mode
                    if !playlistFiles.isEmpty {
                        Text("Track \(currentTrackIndex + 1) of \(playlistFiles.count)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // Time progress bar
                VStack(spacing: 8) {
                    ProgressView(value: currentTime, total: max(duration, 0.1))
                        .progressViewStyle(.linear)
                        .tint(.white)
                        .frame(width: 800)
                    
                    HStack {
                        Text(formatTime(currentTime))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text(formatTime(duration))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(width: 800)
                }
                
                // Playback controls
                HStack(spacing: 80) {
                    // Skip to previous track
                    Button(action: playPrevious) {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 44))
                    }
                    .disabled(!canGoPrevious)
                    
                    // Seek backward 15 seconds
                    Button(action: seekBackward) {
                        Image(systemName: "gobackward.\(Int(seekInterval))")
                            .font(.system(size: 44))
                    }
                    
                    // Play/Pause button
                    Button(action: togglePlayPause) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 44))
                    }
                    
                    // Seek forward 15 seconds
                    Button(action: seekForward) {
                        Image(systemName: "goforward.\(Int(seekInterval))")
                            .font(.system(size: 44))
                    }
                    
                    // Skip to next track
                    Button(action: playNext) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 44))
                    }
                    .disabled(!canGoNext)
                }
                .padding(.bottom, 40)
                
                Spacer()
            }
            .padding(.horizontal, 90)
            .padding(.top, 60)
        }
        .onAppear {
            // Initialize playlist
            if let playlist = playlist {
                playlistFiles = playlist
                // Find the starting index
                if let index = playlist.firstIndex(where: { $0.name == audioFile.name }) {
                    currentTrackIndex = index
                }
            } else {
                playlistFiles = [audioFile]
                currentTrackIndex = 0
            }
            setupPlayer()
        }
        .onDisappear {
            cleanupPlayer()
        }
    }
    
    private func playNext() {
        guard canGoNext else { return }
        currentTrackIndex += 1
        loadAndPlayCurrentTrack()
    }
    
    private func playPrevious() {
        guard canGoPrevious else { return }
        currentTrackIndex -= 1
        loadAndPlayCurrentTrack()
    }
    
    private func seekForward() {
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
    
    private func seekBackward() {
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
    
    private func showSeekIndicator(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            seekIndicator = text
        }
        
        // Hide after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.2)) {
                seekIndicator = nil
            }
        }
    }
    
    private func loadAndPlayCurrentTrack() {
        // Clean up current player
        cleanupPlayer()
        
        // Reset state
        currentTime = 0
        duration = 0
        
        // Setup new player for current track
        setupPlayer()
    }
    
    private func setupPlayer() {
        guard let url = currentTrack.url else { return }
        
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        
        // Observe player status to get duration
        playerItem.publisher(for: \.status)
            .sink { status in
                if status == .readyToPlay {
                    let durationSeconds = playerItem.duration.seconds
                    if !durationSeconds.isNaN && durationSeconds.isFinite {
                        duration = durationSeconds
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observe when track finishes to auto-advance
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .sink { _ in
                if canGoNext {
                    playNext()
                } else {
                    isPlaying = false
                }
            }
            .store(in: &cancellables)
        
        // Add periodic time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            let timeSeconds = time.seconds
            if !timeSeconds.isNaN && timeSeconds.isFinite {
                currentTime = timeSeconds
            }
        }
        
        self.player = newPlayer
        newPlayer.play()
        isPlaying = true
    }
    
    private func cleanupPlayer() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        player?.pause()
        player = nil
        cancellables.removeAll()
    }
    
    private func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && !time.isNaN else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

// MARK: - Player Time Observer (No longer needed, can be removed)
class PlayerTimeObserver: ObservableObject {
    var player: AVPlayer?
    var timeObserver: Any?
    var onTimeUpdate: ((TimeInterval, TimeInterval) -> Void)?
    
    init() {
        startObserving()
    }
    
    func startObserving() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self,
                  let player = self.player else { return }
            
            let currentTime = time.seconds
            let duration = player.currentItem?.duration.seconds ?? 0
            
            if !currentTime.isNaN && !duration.isNaN {
                self.onTimeUpdate?(currentTime, duration)
            }
        }
    }
    
    func stopObserving() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
    
    deinit {
        stopObserving()
    }
}

