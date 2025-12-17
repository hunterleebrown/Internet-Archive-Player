//
//  DetailViewModel.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 7/8/23.
//

import Foundation
import SwiftUI
import iaAPI
import UIKit
import Combine
import AVKit

final class DetailViewModel: ObservableObject {
    private var iaPlayer: Player?
    let service: PlayerArchiveService
    @Published var archiveDoc: ArchiveMetaData? = nil
    @Published var audioFiles = [ArchiveFile]()
    @Published var movieFiles = [ArchiveFile]()
    @Published var playingFile: ArchiveFileEntity?
    @Published var playlistArchiveFiles: [ArchiveFile]?
    @Published var backgroundIconUrl: URL = URL(string: "http://archive.org")!
    @Published var uiImage: UIImage?
    @Published var averageColor: UIColor?
    @Published var gradient: Gradient?
    @Published var isFavoriteArchive: Bool = false
    @Published var createdPlaylist: PlaylistEntity?

    @Published var pressedStates: [ArchiveFile.ID: Bool] = [:]

    // MARK: - Pagination Properties
    private let itemsPerPage = 10
    @Published var displayedAudioFiles: [ArchiveFile] = []
    @Published var currentAudioPage = 0
    @Published var isLoadingMore = false
    
    var hasMoreAudioFiles: Bool {
        displayedAudioFiles.count < sortedAudioFilesCache.count
    }
    
    var remainingAudioCount: Int {
        sortedAudioFilesCache.count - displayedAudioFiles.count
    }

    // Cached sorted audio files
    var sortedAudioFilesCache: [ArchiveFile] {
        audioFiles.sorted { lf, rf in
            if let lTrack = Int(lf.track ?? ""), let rTrack = Int(rf.track ?? "") {
                return lTrack < rTrack
            }
            return false
        }
    }

    var player: AVPlayer? = nil

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.service = PlayerArchiveService()
    }

    public func passInPlayer(iaPlayer: Player) {
        self.iaPlayer = iaPlayer
    }

    @MainActor
    public func getArchiveDoc(identifier: String) async {
        do {
            let doc = try await self.service.getArchiveAsync(with: identifier)
            self.archiveDoc = doc.metadata
            self.audioFiles = doc.non78Audio.sorted{
                guard let track1 = $0.track, let track2 = $1.track else { return false}
                return track1 < track2
            }
            
            // Initialize pagination with first page
            loadInitialAudioFiles()

            let video = doc.files.filter{ $0.isVideo }
            if video.count > 0 {
                self.movieFiles = desiredVideo(files:video)
            }

            if let art = doc.preferredAlbumArt {
                //self.backgroundIconUrl = icon
                Detail.backgroundPass.send(art)
                let image = await IAMediaUtils.getImage(url: art)
                self.uiImage = image
                
                // Process color and gradient once, in background
                if let image = image {
                    self.averageColor = image.averageColor
                    self.gradient = image.gradientToBlack()
                }
            }
        } catch {
            print(error)
        }
    }
    
    // MARK: - Pagination Methods
    
    func loadInitialAudioFiles() {
        currentAudioPage = 0
        displayedAudioFiles = Array(sortedAudioFilesCache.prefix(itemsPerPage))
    }
    
    func loadMoreAudioFiles() {
        guard !isLoadingMore && hasMoreAudioFiles else { return }
        
        isLoadingMore = true
        
        // Simulate a small delay for smooth UX (optional)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            
            let startIndex = (self.currentAudioPage + 1) * self.itemsPerPage
            let endIndex = min(startIndex + self.itemsPerPage, self.sortedAudioFilesCache.count)
            
            if startIndex < self.sortedAudioFilesCache.count {
                let newFiles = Array(self.sortedAudioFilesCache[startIndex..<endIndex])
                self.displayedAudioFiles.append(contentsOf: newFiles)
                self.currentAudioPage += 1
            }
            
            self.isLoadingMore = false
        }
    }
    
    func resetPagination() {
        currentAudioPage = 0
        displayedAudioFiles = []
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

    public func addAllFilesToPlaylist(player: Player) {
        audioFiles.forEach { file in
            do {
                try player.appendPlaylistItem(file)
            } catch PlayerError.alreadyOnPlaylist {

            } catch {

            }
        }
    }

    public func setSubscribers(_ player: Player) {
        player.playingFilePublisher
            .removeDuplicates()
            .sink { file in
                self.playingFile = file
            }
            .store(in: &cancellables)
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
            if let iaPlayer = self.iaPlayer {
                iaPlayer.avPlayer.pause()
            }
            player.play()
        }
    }

    public func stopPreview() {
        guard let player = self.player else { return }
        player.pause()
        self.player = nil
    }
    
    // MARK: - Favorite Archive Management
    
    public func checkFavoriteStatus(identifier: String) {
        guard let player = iaPlayer else { return }
        isFavoriteArchive = player.isFavoriteArchive(identifier: identifier)
    }
    
    public func toggleFavoriteArchive(identifier: String) -> PlayerError? {
        guard let archiveDoc = archiveDoc,
              let player = iaPlayer else { return nil }
        
        if isFavoriteArchive {
            // Remove from favorites
            player.removeFavoriteArchive(identifier: identifier)
            isFavoriteArchive = false
            return nil
        } else {
            // Add to favorites
            do {
                try player.addFavoriteArchive(archiveDoc)
                isFavoriteArchive = true
                return nil
            } catch PlayerError.alreadyOnFavoriteArchives {
                return .alreadyOnFavoriteArchives
            } catch {
                print("Error adding favorite archive: \(error)")
                return nil
            }
        }
    }
    
    // MARK: - Play All Audio
    
    public func playAllAudio() {
        guard let player = iaPlayer else { return }
        
        let sortedFiles = sortedAudioFilesCache
        guard !sortedFiles.isEmpty else { return }
        
        let playlistName = archiveDoc?.archiveTitle ?? "Playlist"
        let context = PersistenceController.shared.container.viewContext
        
        // Check if a playlist with this name already exists
        let fetchRequest = PlaylistEntity.fetchRequest(playlistName: playlistName)
        
        var playlistToUse: PlaylistEntity?
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let existingPlaylist = results.first {
                // Playlist exists - reorder it to match the original track order
                let existingFiles = existingPlaylist.files?.array as? [ArchiveFileEntity] ?? []
                let existingURLs = Set(existingFiles.compactMap { $0.url?.absoluteString })
                let newURLs = Set(sortedFiles.compactMap { $0.url?.absoluteString })
                
                // Check if the existing playlist is missing any files
                let missingURLs = newURLs.subtracting(existingURLs)
                
                // Add any missing files first
                if !missingURLs.isEmpty {
                    for file in sortedFiles {
                        if let urlString = file.url?.absoluteString, missingURLs.contains(urlString) {
                            let entity = file.archiveFileEntity()
                            existingPlaylist.addToFiles(entity)
                        }
                    }
                }
                
                // Now reorder the playlist to match the original track order from Details
                let allFiles = existingPlaylist.files?.array as? [ArchiveFileEntity] ?? []
                
                // Create a map of URL to entity for quick lookup
                var urlToEntity: [String: ArchiveFileEntity] = [:]
                for entity in allFiles {
                    if let urlString = entity.url?.absoluteString {
                        urlToEntity[urlString] = entity
                    }
                }
                
                // Build the new ordered array based on sortedFiles order
                var reorderedEntities: [ArchiveFileEntity] = []
                for file in sortedFiles {
                    if let urlString = file.url?.absoluteString,
                       let entity = urlToEntity[urlString] {
                        reorderedEntities.append(entity)
                    }
                }
                
                // Update the playlist with the reordered files
                existingPlaylist.files = NSOrderedSet(array: reorderedEntities)
                PersistenceController.shared.save()
                
                playlistToUse = existingPlaylist
            } else {
                // Create a new playlist
                let newPlaylist = PlaylistEntity(context: context)
                newPlaylist.name = playlistName
                
                // Add all sorted audio files to the new playlist
                for file in sortedFiles {
                    let entity = file.archiveFileEntity()
                    newPlaylist.addToFiles(entity)
                }
                
                PersistenceController.shared.save()
                playlistToUse = newPlaylist
            }
        } catch {
            print("Error fetching playlist: \(error)")
            return
        }
        
        // Start playing the first track from the playlist
        guard let playlist = playlistToUse,
              let files = playlist.files?.array as? [ArchiveFileEntity],
              let firstEntity = files.first else { return }
        
        // Use the actual entity from the playlist, not a newly created one
        player.playFileFromPlaylist(firstEntity, playlist: playlist)
        
        // Store the playlist for navigation
        createdPlaylist = playlist
    }
}
