//
//  IAPlayer.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 2/6/22. And let's hope it works With Gusto!
//

import Foundation
import iaAPI
import MediaPlayer
import AVFoundation
import AVKit
import UIKit
import Combine
import CoreData
import SwiftUI

enum PlayerError: Error {
    case alreadyOnPlaylist
    case alreadyOnFavorites
    case alreadyOnFavoriteArchives
}

extension PlayerError: CustomStringConvertible {
    var description: String {
        switch self {
        case .alreadyOnPlaylist:
            return "Item is already on the playlist."
        case .alreadyOnFavorites:
            return "Items is already favorited."
        case .alreadyOnFavoriteArchives:
            return "Archive is already in Favorite Archives."
        }
    }
}

class Player: NSObject, ObservableObject {

    public enum AdvanceDirection: Int {
        case forwards = 1
        case backwards = -1
    }

    static let shared = Player()
    static var mainListName = "Now Playing"
    static var favoritesListName = "Favorites"

    @Published var showPlayingDetailView = false
    @Published var items: [ArchiveFileEntity] = [ArchiveFileEntity]()
    @Published var favoriteItems: [ArchiveFileEntity] = [ArchiveFileEntity]()
    @Published var favoriteArchives: [ArchiveMetaDataEntity] = [ArchiveMetaDataEntity]()
    @Published public var avPlayer: AVPlayer
    @Published public var playingFile: ArchiveFileEntity? {
        didSet {
            Home.showControlsPass.send(playingFile != nil)
            self.loadNowPlayingMediaArtwork()
        }
    }
    @Published public var playerHeight: CGFloat = 0

    @AppStorage("playerSkin") public var playerSkin: PlayerControlsSkin?  // Store as Data

    var useSkin: PlayerControlsSkin {
        get {
            playerSkin ?? .classic
        }
        set {
            playerSkin = newValue
            objectWillChange.send()
        }
    }

    @Published var sampleRate: String = "0"

    var playingPlaylist: PlaylistEntity? = nil {
        didSet {
            self.items = playingPlaylist?.files?.compactMap { $0 as? ArchiveFileEntity } ?? []
        }
    }

    var mainPlaylist: PlaylistEntity? = nil
    var favoritesPlaylist: PlaylistEntity? = nil

    public var nowPlayingSession: MPNowPlayingSession

    private var observing = false
    private var observingStatus = false
    fileprivate var observerContext = 0

    @Published var playing = false

    private var playingImage: MPMediaItemArtwork?
    private var artworkLoadTask: Task<Void, Never>?

    var fileIdentifierTitle: String?

    private let playlistFetchController: NSFetchedResultsController<PlaylistEntity>
    private let favoritesFetchController: NSFetchedResultsController<PlaylistEntity>

    override init() {

        playlistFetchController =
        NSFetchedResultsController(fetchRequest:  PlaylistEntity.fetchRequest(playlistName: Self.mainListName),
                                   managedObjectContext: PersistenceController.shared.container.viewContext,
                                   sectionNameKeyPath: nil,
                                   cacheName: nil)

        favoritesFetchController =
        NSFetchedResultsController(fetchRequest:  PlaylistEntity.fetchRequest(playlistName: Self.favoritesListName),
                                   managedObjectContext: PersistenceController.shared.container.viewContext,
                                   sectionNameKeyPath: nil,
                                   cacheName: nil)

        let player = AVPlayer()
        self.avPlayer = player
        let session = MPNowPlayingSession(players: [player])
        self.nowPlayingSession = session

        super.init()
        
        // Clean up any orphaned files first, before loading playlists
        PersistenceController.shared.cleanupOrphans()
        
        sessionRemote(session: session)
        playlistFetchController.delegate = self
        favoritesFetchController.delegate = self

        // Setup playlists
        setupMainPlaylist()
        setupFavoritesPlaylist()
        
        // Load favorite archives
        favoriteArchives = PersistenceController.shared.fetchAllFavoriteArchives()

        NotificationCenter.default.addObserver(self, selector: #selector(continuePlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    // MARK: - Playlist Setup
    
    private func setupMainPlaylist() {
        do {
            try playlistFetchController.performFetch()
            if let playlist = playlistFetchController.fetchedObjects?.first {
                mainPlaylist = playlist
                if let files = mainPlaylist?.files?.array as? [ArchiveFileEntity] {
                    items = files
                }
            } else {
                // Create the main playlist if it doesn't exist
                mainPlaylist = PlaylistEntity(context: PersistenceController.shared.container.viewContext)
                mainPlaylist?.name = Self.mainListName
                mainPlaylist?.permanent = true
                PersistenceController.shared.save()
            }
        } catch {
            print("Failed to fetch main playlist: \(error.localizedDescription)")
        }
    }
    
    private func setupFavoritesPlaylist() {
        do {
            try favoritesFetchController.performFetch()
            if let favoritesList = favoritesFetchController.fetchedObjects?.first {
                favoritesPlaylist = favoritesList
                if let files = favoritesPlaylist?.files?.array as? [ArchiveFileEntity] {
                    favoriteItems = files
                }
            } else {
                // Create the favorites playlist if it doesn't exist
                favoritesPlaylist = PlaylistEntity(context: PersistenceController.shared.container.viewContext)
                favoritesPlaylist?.name = Self.favoritesListName
                favoritesPlaylist?.permanent = true
                PersistenceController.shared.save()
            }
        } catch {
            print("Failed to fetch favorites playlist: \(error.localizedDescription)")
        }
    }

    private let playingSubject = PassthroughSubject<Bool, Never>()
    public var playingPublisher: AnyPublisher<Bool, Never> {
        playingSubject.eraseToAnyPublisher()
    }

    private let playingFileSubject = PassthroughSubject<ArchiveFileEntity, Never>()
    public var playingFilePublisher: AnyPublisher<ArchiveFileEntity, Never> {
        playingFileSubject.eraseToAnyPublisher()
    }
    public func sendPlayingFileForPlaylist() {
        if let file = self.playingFile {
            playingFileSubject.send(file)
        }
    }

    private var sliderProgressSubject = PassthroughSubject<Double, Never>()
    public var sliderProgressPublisher: AnyPublisher<Double, Never> {
        sliderProgressSubject.eraseToAnyPublisher()
    }
    private var pauseSliderProgress = false
    public func shouldPauseSliderProgress(_ shouldPause: Bool){
        self.pauseSliderProgress = shouldPause
    }

    private let durationSubject = PassthroughSubject<Double, Never>()
    public var durationSubjectPublisher: AnyPublisher<Double, Never> {
        durationSubject.eraseToAnyPublisher()
    }

    public func seekTo(with sliderValue: Double) {
        guard let currentItem = avPlayer.currentItem else { return }
            let duration = CMTimeGetSeconds(currentItem.duration)
            let sec = duration * Float64(sliderValue)
            let seakTime:CMTime = CMTimeMakeWithSeconds(sec, preferredTimescale: 600)
            avPlayer.seek(to: seakTime) { _ in
                self.shouldPauseSliderProgress(false)
            }
    }

    public func appendPlaylistItem(_ item: ArchiveFile) throws {
        let archiveFileEntity = item.archiveFileEntity()
        try? self.appendPlaylistItem(archiveFileEntity: archiveFileEntity)
    }

    public func appendAndPlay(_ archiveFileEntity: ArchiveFileEntity) throws {
        do {
            try self.appendPlaylistItem(archiveFileEntity: archiveFileEntity)
        } catch (let error) {
            throw error
        }
        guard let list = mainPlaylist else { return }
        
        // Retrieve the actual entity from the playlist after saving
        // to ensure we're using the same object reference that exists in the playlist
        guard let files = list.files?.array as? [ArchiveFileEntity],
              let entityFromPlaylist = files.first(where: { $0.onlineUrl?.absoluteString == archiveFileEntity.onlineUrl?.absoluteString }) else {
            // Fallback to the passed entity if we can't find it
            self.playFileFromPlaylist(archiveFileEntity, playlist: list)
            return
        }
        
        self.playFileFromPlaylist(entityFromPlaylist, playlist: list)
    }

    public func appendPlaylistItem(archiveFileEntity: ArchiveFileEntity) throws {
        guard let playlist = mainPlaylist else { return }
        try checkDupes(archiveFile: archiveFileEntity, list: self.items, error: .alreadyOnPlaylist)
        playlist.addToFiles(archiveFileEntity)
        PersistenceController.shared.save()
    }

    public func appendFavoriteItem(file: ArchiveFile) throws {
        let archiveFileEntity = file.archiveFileEntity()
        try self.appendFavoriteItem(archiveFileEntity: archiveFileEntity)
    }

    public func appendFavoriteItem(archiveFileEntity: ArchiveFileEntity) throws {
        guard let playlist = favoritesPlaylist else { return }
        try checkDupes(archiveFile: archiveFileEntity, list: self.favoriteItems, error: .alreadyOnFavorites)

        playlist.addToFiles(archiveFileEntity)
        PersistenceController.shared.save()
    }

    // MARK: - Favorite Archives Management
    
    public func addFavoriteArchive(_ metaData: ArchiveMetaData) throws {
        try PersistenceController.shared.saveFavoriteArchive(metaData)
        refreshFavoriteArchives()
    }
    
    public func removeFavoriteArchive(identifier: String) {
        PersistenceController.shared.removeFavoriteArchive(identifier: identifier)
        refreshFavoriteArchives()
    }
    
    public func isFavoriteArchive(identifier: String) -> Bool {
        return PersistenceController.shared.isFavoriteArchive(identifier: identifier)
    }
    
    public func refreshFavoriteArchives() {
        let archives = PersistenceController.shared.fetchAllFavoriteArchives()
        DispatchQueue.main.async {
            self.favoriteArchives = archives
        }
    }

    public func checkDupes(archiveFile: ArchiveFileEntity, list: [ArchiveFileEntity], error: PlayerError) throws {
        let sameValues = list.filter {$0.onlineUrl?.absoluteString == archiveFile.onlineUrl?.absoluteString }
        guard sameValues.isEmpty else { throw error }
    }

    public func checkDupes(archiveFile: ArchiveFile, list: [ArchiveFileEntity], error: PlayerError) throws {
        let sameValues = list.filter {$0.onlineUrl?.absoluteString == archiveFile.url?.absoluteString }
        guard sameValues.isEmpty else { throw error }
    }

    public func getPlaylist() -> [ArchiveFileEntity] {
        return self.items
    }

    public func clearPlaylist() {
        guard let playlist = mainPlaylist else { return }
        for item in items {
            self.deleteLocalFile(item: item)
            playlist.removeFromFiles(item)
            PersistenceController.shared.delete(item, false)
        }
        PersistenceController.shared.save()
    }

    public func removeListItem(list: PlaylistEntity?, at offsets: IndexSet){
        self.removePlayListEntities(list: list, at: offsets)
    }


    private func deleteLocalFile(item: ArchiveFileEntity) {
        if item.isLocalFile(), let workingUrl = item.workingUrl {
            do {
                try Downloader.removeFile(at: workingUrl)
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }

    private func removePlayListEntities(list: PlaylistEntity?, at offsets: IndexSet) {
        guard let playlist = list else { return }
        guard let playlistFiles = playlist.files?.array as? [ArchiveFileEntity] else { return }
        
        for index in offsets {
            // Get the file directly from the playlist's files array
            guard playlistFiles.indices.contains(index) else { continue }
            let archiveFileEntity = playlistFiles[index]
            
            unsetPlayingFile(entity: archiveFileEntity)

            playlist.removeFromFiles(archiveFileEntity)
            PersistenceController.shared.save()

            if !PersistenceController.shared.isOnPlaylist(entity: archiveFileEntity) {
                self.deleteLocalFile(item: archiveFileEntity)
                PersistenceController.shared.delete(archiveFileEntity, false)
            }
        }
    }

    public func unsetPlayingFile<T: ArchiveFileDisplayable>(entity: T) {
        if let playingFile = self.playingFile,
           playingFile.onlineUrl?.absoluteString == entity.onlineUrl?.absoluteString {
            self.stopPlaying()
            self.playingFile = nil
        }
    }


    public func rearrangeList(list: PlaylistEntity?, fromOffsets source: IndexSet, toOffset destination: Int) {
        guard let playlist = list else { return }
        playlist.moveObject(indexes: source, toIndex: destination)
        PersistenceController.shared.save()
    }

    @objc func continuePlaying() {
        if self.items.count == 0 {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        }

        guard let list = playingPlaylist, let files = self.playingPlaylist?.files?.array as? [ArchiveFileEntity] else { return }

        if let playingFile = playingFile, let index = files.firstIndex(of: playingFile) {
            guard files.indices.contains(index + 1) else { return }
            playFileFromPlaylist(files[index + 1], playlist: list)
        }
    }

    public func playFile(_ archiveFile: ArchiveFile){
        guard let playlist = mainPlaylist else { return }
        let archiveFileEntity = archiveFile.archiveFileEntity()
        playlist.addToFiles(archiveFileEntity)
        PersistenceController.shared.save()
        
        // Retrieve the actual entity from the playlist after saving
        // to ensure we're using the same object reference that exists in the playlist
        guard let files = playlist.files?.array as? [ArchiveFileEntity],
              let entityFromPlaylist = files.first(where: { $0.onlineUrl?.absoluteString == archiveFile.url?.absoluteString }) else {
            // Fallback to the created entity if we can't find it
            self.playFileFromPlaylist(archiveFileEntity, playlist: playlist)
            return
        }
        
        self.playFileFromPlaylist(entityFromPlaylist, playlist: playlist)
    }

    public func playFileFromPlaylist(_ archiveFileEntity: ArchiveFileEntity, playlist: PlaylistEntity) {

        self.playingPlaylist = playlist
        if archiveFileEntity.isLocalFile() {
            guard archiveFileEntity.doesLocalFileExist() else {
                // Alert user the local file doesn't exist, do they want to play it online?
                return
            }
        }

        self.fileIdentifierTitle = archiveFileEntity.archiveTitle
        self.playingFile = archiveFileEntity
        self.playingFileSubject.send(archiveFileEntity)

        if archiveFileEntity.workingUrl!.absoluteString.contains("https") {
            // Check network connectivity on main actor
            Task { @MainActor in
                let isConnected = IAReachability.isConnectedToNetwork()
                if !isConnected {
                    ArchiveErrorManager.shared.showError(message: "The internet connection appears to be offline.")
                    return
                }
                
                // Create or update history entry
                self.updatePlayHistory(for: archiveFileEntity)
                
                self.loadAndPlay(archiveFileEntity.workingUrl!)
            }
        } else {
            // Create or update history entry
            self.updatePlayHistory(for: archiveFileEntity)
            
            self.loadAndPlay(archiveFileEntity.workingUrl!)
        }
    }
    
    /// Creates or updates a history entry for the played file
    private func updatePlayHistory(for archiveFileEntity: ArchiveFileEntity) {
        // Perform Core Data operations on the appropriate context
        let context = PersistenceController.shared.container.viewContext
        
        // Ensure we're on the main thread for viewContext
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.updatePlayHistory(for: archiveFileEntity)
            }
            return
        }
        
        // Check if history entry already exists with matching identifier and name
        let fetchRequest: NSFetchRequest<HistoryArchiveFileEntity> = HistoryArchiveFileEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@ AND name == %@", 
                                             archiveFileEntity.identifier ?? "", 
                                             archiveFileEntity.name ?? "")
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let existingHistory = results.first {
                // Update existing entry
                existingHistory.playedAt = Date()
                existingHistory.playCount += 1
            } else {
                // Create new history entry
                let historyEntity = HistoryArchiveFileEntity(context: context)
                historyEntity.identifier = archiveFileEntity.identifier
                historyEntity.name = archiveFileEntity.name
                historyEntity.title = archiveFileEntity.title
                historyEntity.artist = archiveFileEntity.artist
                historyEntity.creator = archiveFileEntity.creator
                historyEntity.archiveTitle = archiveFileEntity.archiveTitle
                historyEntity.track = archiveFileEntity.track
                historyEntity.size = archiveFileEntity.size
                historyEntity.format = archiveFileEntity.format
                historyEntity.length = archiveFileEntity.length
                historyEntity.url = archiveFileEntity.onlineUrl // Use computed onlineUrl
                historyEntity.playedAt = Date()
                historyEntity.playCount = 1
            }
            
            PersistenceController.shared.save()
            
            // Constrain history to 50 items by removing oldest entries
            trimHistoryToLimit()
            
        } catch {
            print("Error updating play history: \(error.localizedDescription)")
        }
    }
    
    /// Trims history to maintain a maximum of 50 items
    private func trimHistoryToLimit(maxItems: Int = 50) {
        // Ensure we're on the main thread for viewContext
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.trimHistoryToLimit(maxItems: maxItems)
            }
            return
        }
        
        let context = PersistenceController.shared.container.viewContext
        
        // Fetch all history items sorted by playedAt (oldest first)
        let fetchRequest: NSFetchRequest<HistoryArchiveFileEntity> = HistoryArchiveFileEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "playedAt", ascending: true)]
        
        do {
            let allHistoryItems = try context.fetch(fetchRequest)
            let count = allHistoryItems.count
            
            // If we exceed the limit, delete the oldest items
            if count > maxItems {
                let itemsToDelete = allHistoryItems.prefix(count - maxItems)
                for item in itemsToDelete {
                    context.delete(item)
                }
                PersistenceController.shared.save()
                print("🗑️ Trimmed \(itemsToDelete.count) old history items. Now at \(maxItems) items.")
            }
        } catch {
            print("Error trimming history: \(error.localizedDescription)")
        }
    }


    public func advancePlayer(_ advanceDirection: AdvanceDirection) {

        guard let list = playingPlaylist, let files = self.playingPlaylist?.files?.array as? [ArchiveFileEntity] else { return }

        if let playingFile = self.playingFile, let index = files.firstIndex(of: playingFile) {
            guard files.indices.contains(index + advanceDirection.rawValue) else { return }
            playFileFromPlaylist(files[index + advanceDirection.rawValue], playlist: list)
        }
    }

    private func loadAndPlay(_ playUrl: URL) {

        avPlayer.pause()
        if(self.observing) {
            avPlayer.removeObserver(self, forKeyPath: "rate", context: &observerContext)
            self.observing = false
        }
        
        if(self.observingStatus) {
            avPlayer.removeObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem.status), context: &observerContext)
            self.observingStatus = false
        }

        self.setActiveAudioSession()
        print(playUrl.absoluteString)
        let playerItem = AVPlayerItem(url: playUrl)

        // Option #2: Increase buffer duration to preload more video data
        playerItem.preferredForwardBufferDuration = 30.0 // Load 30 seconds ahead

        // Option #5: Configure player item for better buffering
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        playerItem.preferredPeakBitRate = 0 // Let AVPlayer choose best quality based on network

        Task {
            await self.getAudioDetails(for: playerItem)
        }

        avPlayer.addObserver(self, forKeyPath: "rate", options:.new, context: &observerContext)
        self.observing = true
        
        // Add observer for player item status to catch errors
        avPlayer.addObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem.status), options: [.new, .initial], context: &observerContext)
        self.observingStatus = true

        avPlayer.replaceCurrentItem(with: playerItem)

        avPlayer.play()

        print("Playing File: ")
        dump(playingFile?.format)

        if playingFile?.format != "VBR MP3" {
            PlayerControls.showVideo.send(true)
        } else {
            PlayerControls.showVideo.send(false)
        }

    }

    private func getAudioDetails(for playerItem: AVPlayerItem) async {
        do {
            let tracks = try await playerItem.asset.loadTracks(withMediaType: .audio)
            guard let track = tracks.first else {
                await MainActor.run {
                    self.sampleRate = ""
                }
                print("No audio track found")
                return
            }

            let formatDescriptions = try await track.load(.formatDescriptions) as [CMAudioFormatDescription]
            guard let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescriptions.first!)?.pointee else {
                return
            }

            let sampleRateHz = basicDescription.mSampleRate
            let sampleRateKhz = sampleRateHz / 1000.0
//            print("Sample Rate: \(sampleRateKhz) kHz") //
            // Note: This method provides the static, inherent sample rate of the file, not the real-time playback frequency.

            await MainActor.run {
                self.sampleRate = "\(sampleRateKhz)"
            }

        } catch {
            print("Failed to load audio tracks: \(error.localizedDescription)")
        }
    }

    private func stopPlaying() {
            avPlayer.pause()
            if(self.observing) {
                avPlayer.removeObserver(self, forKeyPath: "rate", context: &observerContext)
                self.observing = false
            }
            
            if(self.observingStatus) {
                avPlayer.removeObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem.status), context: &observerContext)
                self.observingStatus = false
            }
            
            self.sliderProgressSubject.send(0)
    }

    private func loadNowPlayingMediaArtwork() {
        guard let url = self.playingFile?.iconUrl else { 
            // Clear artwork if no URL
            self.playingImage = nil
            self.setPlayingInfo(playing: false)
            return 
        }
        
        // Cancel any previous artwork loading task
        artworkLoadTask?.cancel()
        
        // Use the shared ImageCacheManager for loading and caching
        artworkLoadTask = ImageCacheManager.shared.loadImage(from: url) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let image):
                self.playingImage = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                self.setPlayingInfo(playing: false)
                
            case .failure(let error):
                print("Failed to load artwork: \(error.localizedDescription)")
                // Optionally clear artwork on error
                self.playingImage = nil
            }
        }
    }

    public func didTapPlayButton() {
        if avPlayer.currentItem != nil && self.playing {
            avPlayer.pause()
        } else {
            avPlayer.play()
        }
    }

    private func setActiveAudioSession(){
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        }
        catch {
            print("Failed to set audio session: \(error)")
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let player = object as? AVPlayer, player == avPlayer else { return }

        if keyPath == "rate" {
            DispatchQueue.main.async {
                self.playing  = self.avPlayer.rate > 0.0
                self.playingSubject.send(self.avPlayer.rate > 0.0)
                self.setPlayingInfo(playing: self.playing)
                self.monitorPlayback()
            }
        }

        if keyPath == #keyPath(AVPlayer.currentItem.status) {
            DispatchQueue.main.async {
                let newStatus: AVPlayerItem.Status
                if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                    newStatus = AVPlayerItem.Status(rawValue: newStatusAsNumber.intValue)!
                } else {
                    newStatus = .unknown
                }

                if newStatus == .failed {
                    print("❌ AVPlayer Error: \(String(describing: self.avPlayer.currentItem?.error?.localizedDescription)), error: \(String(describing: self.avPlayer.currentItem?.error))")

                    // Surface the error to the user via the universal error overlay
                    if let error = self.avPlayer.currentItem?.error {
                        let fileName = self.playingFile?.title ?? self.playingFile?.name ?? "Unknown file"
                        let errorMessage = "Failed to play \"\(fileName)\": \(error.localizedDescription)"
                        ArchiveErrorManager.shared.showError(message: errorMessage)
                    }
                }
            }
        }
    }

    private func monitorPlayback() {

            if(avPlayer.currentItem != nil) {
                let progress = CMTimeGetSeconds(avPlayer.currentTime()) / CMTimeGetSeconds((avPlayer.currentItem?.duration)!)
                if !pauseSliderProgress {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.sliderProgressSubject.send(progress)
                        self.durationSubject.send(CMTimeGetSeconds((self.avPlayer.currentItem?.duration)!))
                    }
                }

                if(avPlayer.rate != 0.0) {
                    // Update Now Playing info periodically during playback
                    self.setPlayingInfo(playing: true)
                    
                    let delay = 0.1 * Double(NSEC_PER_SEC)
                    let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
                    DispatchQueue.main.asyncAfter(deadline: time) { [weak self] in
                        self?.monitorPlayback()
                    }
                }
            }
            return
    }

    private func setPlayingInfo(playing:Bool) {

        let artist = self.playingFile?.displayArtist
        let fileTitle = self.playingFile?.displayTitle ?? self.fileIdentifierTitle

        if let playItem = avPlayer.currentItem {
            let currentTime = CMTimeGetSeconds(avPlayer.currentTime())
            let duration = CMTimeGetSeconds(playItem.duration)
            
            playItem.nowPlayingInfo = [
                MPMediaItemPropertyTitle : fileTitle ?? "",
                MPMediaItemPropertyArtist: artist ?? "",
                MPNowPlayingInfoPropertyPlaybackQueueCount: self.items.count,
                // Critical timing information for Apple Watch
                MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
                MPMediaItemPropertyPlaybackDuration: duration,
                MPNowPlayingInfoPropertyPlaybackRate: playing ? 1.0 : 0.0,
            ]
            if let image = self.playingImage {
                playItem.nowPlayingInfo?[MPMediaItemPropertyArtwork] = image
            }

            if let curFile = self.playingFile, let index = self.items.firstIndex(of: curFile) {
                playItem.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackQueueIndex] = index
                playItem.nowPlayingInfo?[MPMediaItemPropertyMediaType] = curFile.isAudio ? MPMediaType.anyAudio.rawValue : MPMediaType.anyVideo.rawValue
            }

            if let ft = fileTitle {
                let title = AVMutableMetadataItem()
                title.identifier = .commonIdentifierTitle
                title.value = ft as NSString
                title.extendedLanguageTag = "und"

                playItem.externalMetadata = [title]

            }
            self.nowPlayingSession.becomeActiveIfPossible()
            self.nowPlayingSession.automaticallyPublishesNowPlayingInfo = true

        }
    }

    private func sessionRemote(session: MPNowPlayingSession) {

        session.remoteCommandCenter.playCommand.addTarget { [weak self] event in
            self?.avPlayer.play()
            return .success
        }

        session.remoteCommandCenter.pauseCommand.addTarget { [weak self] event in
            self?.avPlayer.pause()
            return .success
        }

        session.remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            self?.playing ?? false ? self?.avPlayer.pause() : self?.avPlayer.play()
            return .success
        }

        // Skip forward command (15 seconds)
        session.remoteCommandCenter.skipForwardCommand.isEnabled = true
        session.remoteCommandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: 15)]
        session.remoteCommandCenter.skipForwardCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            let currentTime = self.avPlayer.currentTime()
            let skipTime = CMTimeAdd(currentTime, CMTime(seconds: 15, preferredTimescale: 1))
            self.avPlayer.seek(to: skipTime) { success in
                if success {
                    self.setPlayingInfo(playing: self.playing)
                }
            }
            return .success
        }
        
        // Skip backward command (15 seconds)
        session.remoteCommandCenter.skipBackwardCommand.isEnabled = true
        session.remoteCommandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: 15)]
        session.remoteCommandCenter.skipBackwardCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            let currentTime = self.avPlayer.currentTime()
            let skipTime = CMTimeSubtract(currentTime, CMTime(seconds: 15, preferredTimescale: 1))
            self.avPlayer.seek(to: skipTime) { success in
                if success {
                    self.setPlayingInfo(playing: self.playing)
                }
            }
            return .success
        }

        session.remoteCommandCenter.changePlaybackPositionCommand.addTarget { [weak self] remoteEvent in

            if let event = remoteEvent as? MPChangePlaybackPositionCommandEvent {
                let playerRate = self?.avPlayer.rate
                self?.avPlayer.seek(to: CMTime(seconds: event.positionTime, preferredTimescale: CMTimeScale(1000)), completionHandler: { [weak self](success) in
                     guard let self = self else {return}
                     if success, let r = playerRate {
                         self.avPlayer.rate = r
                         self.setPlayingInfo(playing: r > 0)
                     }
                 })
                 return .success
              }
            
            return .commandFailed
        }

        session.remoteCommandCenter.nextTrackCommand.addTarget { [weak self] event in

            guard let list = self?.playingPlaylist, let files = self?.playingPlaylist?.files?.array as? [ArchiveFileEntity] else { return .commandFailed }

            if let playingFile = self?.playingFile, let index = files.firstIndex(of: playingFile) {
                guard files.indices.contains(index + 1) else { return .commandFailed }
                let fileEnt = files[index + 1]
                self?.playFileFromPlaylist(fileEnt, playlist: list)

                return .success
            }
            return .commandFailed
        }

        session.remoteCommandCenter.previousTrackCommand.addTarget { [weak self] event in

            guard let list = self?.playingPlaylist, let files = self?.playingPlaylist?.files?.array as? [ArchiveFileEntity] else { return .commandFailed }

            if let playingFile = self?.playingFile, let index = files.firstIndex(of: playingFile) {
                guard files.indices.contains(index - 1) else { return .commandFailed }
                let fileEnt = files[index - 1]
                self?.playFileFromPlaylist(fileEnt, playlist: list)
                return .success
            }
            return .commandFailed
        }

    }
    
    // MARK: - Seeking Methods for PlayerControls
    
    var seekTimer: Timer?
    let seekInterval: CMTime = CMTimeMakeWithSeconds(1, preferredTimescale: 600) // 1 second seek intervals
    
    func seek(forward: Bool) {
        if seekTimer == nil {
            startSeeking(forward: forward)
        }
    }
    
    private func startSeeking(forward: Bool) {
        // Invalidate any existing timer
        seekTimer?.invalidate()
        
        // Start a timer to seek forward or backward in increments
        seekTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let currentTime = self.avPlayer.currentTime()
            let seekTime = forward ? CMTimeAdd(currentTime, self.seekInterval) : CMTimeSubtract(currentTime, self.seekInterval)
            self.avPlayer.seek(to: seekTime)
        }
    }
    
    func stopSeeking() {
        // Invalidate the timer and stop seeking
        seekTimer?.invalidate()
        seekTimer = nil
        // Reset playback rate to normal if necessary
        avPlayer.rate = 1.0
    }

    deinit {
        seekTimer?.invalidate()
        artworkLoadTask?.cancel()
        NotificationCenter.default.removeObserver(self)
        
        if observing {
            avPlayer.removeObserver(self, forKeyPath: "rate", context: &observerContext)
        }
        
        if observingStatus {
            avPlayer.removeObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem.status), context: &observerContext)
        }
    }
}

extension Player: NSFetchedResultsControllerDelegate {
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
      guard let playlist = controller.fetchedObjects?.first as? PlaylistEntity
      else { return }
      DispatchQueue.main.async {
          if let files = playlist.files?.array as? [ArchiveFileEntity] {

              switch playlist.name {
              case Player.mainListName:
                  self.items = files
              case Player.favoritesListName:
                  self.favoriteItems = files
              case .none:
                  print("no playlist name")
              case .some(_):
                  print("some what?")
              }
          }
      }
  }
}
