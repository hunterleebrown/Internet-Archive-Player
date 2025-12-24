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
    @State var isLoading = true

    var body: some View {
        ZStack {
            if isLoading {
                loadingView
            } else {
                contentView
            }
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
        .onChange(of: viewModel.archiveDoc) { _, newValue in
            if newValue != nil {
                // Add a small delay to ensure smooth transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isLoading = false
                    }
                }
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color.gray.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated icon with pulsing effect
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 250, height: 250)
                    
                    Image(systemName: "archivebox")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .symbolEffect(.pulse, options: .repeating)
                }
                
                VStack(spacing: 16) {
                    Text("Loading Archive")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Fetching details from the Internet Archive...")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 60)
                    
                    // Loading indicator
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                        .padding(.top, 20)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Content View
    private var contentView: some View {
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
                    if self.viewModel.sortedAudioFiles().count > 0 {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Audio")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            List {
                                ForEach(self.viewModel.sortedAudioFiles(), id: \.self) { file in
                                    NavigationLink {
                                        if let archiveDoc = self.viewModel.archiveDoc {
                                            AudioPlayerView(
                                                audioFile: file,
                                                artworkURL: imageUrl,
                                                archiveDoc: archiveDoc,
                                                playlist: self.viewModel.sortedAudioFiles()
                                            )
                                        }
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
                                
                // Dark overlay for text readability
                LinearGradient(
                    colors: [Color.black.opacity(0.7), Color.black.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Supporting Views (Private to TVDetail)

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
        
        // Error handling
        @Published var errorMessage: String?
        @Published var hasError: Bool = false

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
                    
                    // Clear any previous errors on success
                    self.hasError = false
                    self.errorMessage = nil
                    
                } catch let error as ArchiveServiceError {
                    // Handle specific Archive service errors
                    self.errorMessage = "Failed to load archive: \(error.description)"
                    self.hasError = true
                    print("ArchiveServiceError in getArchiveDoc: \(error.description)")
                    
                    // Also show in universal error overlay
                    ArchiveErrorManager.shared.showError(error)
                    
                } catch {
                    // Handle any other errors (except user cancellations)
                    let errorDescription = error.localizedDescription.lowercased()
                    guard !errorDescription.contains("cancelled") && !errorDescription.contains("canceled") else {
                        // User cancelled the operation, don't show error
                        return
                    }
                    
                    self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                    self.hasError = true
                    print("Unexpected error in getArchiveDoc: \(error)")
                    
                    // Also show in universal error overlay
                    ArchiveErrorManager.shared.showError(error)
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


