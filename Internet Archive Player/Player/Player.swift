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

enum PlayerError: Error {
    case alreadyOnPlaylist
    case alreadyOnFavorites
}

extension PlayerError: CustomStringConvertible {
    var description: String {
        switch self {
        case .alreadyOnPlaylist:
            return "Item is already on the playlist."
        case .alreadyOnFavorites:
            return "Items is already favorited."
        }
    }
}

class Player: NSObject, ObservableObject {

    public enum AdvanceDirection: Int {
        case forwards = 1
        case backwards = -1
    }

    static let shared = Player()
    static var networkAlert = PassthroughSubject<Bool, Never>()
    static var mainListName = "Now Playing"
    static var favoritesListName = "Favorites"

    @Published var showPlayingDetailView = false
    @Published var items: [ArchiveFileEntity] = [ArchiveFileEntity]()
    @Published var favoriteItems: [ArchiveFileEntity] = [ArchiveFileEntity]()
    @Published public var avPlayer: AVPlayer
    @Published public var playingFile: ArchiveFileEntity? {
        didSet {
            Home.showControlsPass.send(playingFile != nil)
            self.loadNowPlayingMediaArtwork()
        }
    }
    @Published public var playerHeight: CGFloat = 160

    var playingPlaylist: PlaylistEntity? = nil {
        didSet {
            self.items = playingPlaylist?.files?.compactMap { $0 as? ArchiveFileEntity } ?? []
        }
    }

    var mainPlaylist: PlaylistEntity? = nil
    var favoritesPlaylist: PlaylistEntity? = nil

    private var playingMediaType: MPNowPlayingInfoMediaType? = nil
    public var nowPlayingSession: MPNowPlayingSession

    private var observing = false
    fileprivate var observerContext = 0
    private var playing = false

    private var playingImage: MPMediaItemArtwork?

    var fileTitle: String?
    var fileIdentifierTitle: String?
    var fileIdentifier: String?

    let presentingController = AVPlayerViewController()

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
        sessionRemote(session: session)
        playlistFetchController.delegate = self
        favoritesFetchController.delegate = self

        do {
          try playlistFetchController.performFetch()
            if let playlist = playlistFetchController.fetchedObjects?.first {
                mainPlaylist = playlist
                if let files = mainPlaylist?.files?.array as? [ArchiveFileEntity] {
                    items = files
                }
            } else {
                mainPlaylist = PlaylistEntity(context: PersistenceController.shared.container.viewContext)
                mainPlaylist?.name = Self.mainListName
                mainPlaylist?.permanent = true
                PersistenceController.shared.save()
            }
        } catch {
          print("failed to fetch items!")
        }

        do {
          try favoritesFetchController.performFetch()
            if let favoritesList = favoritesFetchController.fetchedObjects?.first {
                favoritesPlaylist = favoritesList
                if let files = favoritesPlaylist?.files?.array as? [ArchiveFileEntity] {
                    favoriteItems = files
                }
            } else {
                favoritesPlaylist = PlaylistEntity(context: PersistenceController.shared.container.viewContext)
                favoritesPlaylist?.name = Self.favoritesListName
                favoritesPlaylist?.permanent = true
                PersistenceController.shared.save()
            }
        } catch {
          print("failed to fetch favorite items!")
        }


        NotificationCenter.default.addObserver(self, selector: #selector(continuePlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
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

    private let sliderProgressSubject = PassthroughSubject<Double, Never>()
    public var sliderProgressPublisher: AnyPublisher<Double, Never> {
        sliderProgressSubject.eraseToAnyPublisher()
    }
    private var sliderProgress: Double = 0.0
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
        self.playFileFromPlaylist(archiveFileEntity, playlist: list)
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
        for index in offsets {
            let archiveFileEntity = playlist.name == Self.mainListName ? items[index] : favoriteItems[index]
            if let playingFile = self.playingFile, playingFile == archiveFileEntity{
                self.stopPlaying()
                self.playingFile = nil
            }
            playlist.removeFromFiles(archiveFileEntity)
            PersistenceController.shared.save()

            if !PersistenceController.shared.isOnPlaylist(entity: archiveFileEntity) {
                self.deleteLocalFile(item: archiveFileEntity)
                PersistenceController.shared.delete(archiveFileEntity, false)
            }
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

        guard let list = playingPlaylist, let files = self.playingPlaylist?.files as? [ArchiveFileEntity] else { return }

        if let playingFile = playingFile, let index = files.firstIndex(of: playingFile) {
            guard items.indices.contains(index + 1) else { return }
            playFileFromPlaylist(items[index + 1], playlist: list)
        }
    }

    public func playFile(_ archiveFile: ArchiveFile){
        guard let playlist = mainPlaylist else { return }
        let archiveFileEntity = archiveFile.archiveFileEntity()
        playlist.addToFiles(archiveFileEntity)
        PersistenceController.shared.save()
        self.playFileFromPlaylist(archiveFileEntity, playlist: playlist)
    }

    public func playFileFromPlaylist(_ archiveFileEntity: ArchiveFileEntity, playlist: PlaylistEntity) {

        self.playingPlaylist = playlist
        if archiveFileEntity.isLocalFile() {
            guard archiveFileEntity.doesLocalFileExist() else {
                // Alert user the local file doesn't exist, do they want to play it online?
                return
            }
        }

        self.fileTitle = archiveFileEntity.title ?? archiveFileEntity.name
        self.fileIdentifierTitle = archiveFileEntity.archiveTitle
        self.fileIdentifier = archiveFileEntity.identifier
        self.playingFile = archiveFileEntity
        self.playingFileSubject.send(archiveFileEntity)

        if archiveFileEntity.workingUrl!.absoluteString.contains("https") {
            guard IAReachability.isConnectedToNetwork() else {
                Player.networkAlert.send(true)
                return
            }
        }

        self.loadAndPlay(archiveFileEntity.workingUrl!)
    }


    public func advancePlayer(_ advanceDirection: AdvanceDirection) {

        guard let list = playingPlaylist, let files = self.playingPlaylist?.files?.array as? [ArchiveFileEntity] else { return }

        if let playingFile = self.playingFile, let index = files.firstIndex(of: playingFile) {
            guard items.indices.contains(index + advanceDirection.rawValue) else { return }
            playFileFromPlaylist(items[index + advanceDirection.rawValue], playlist: list)
        }
    }

    private func loadAndPlay(_ playUrl: URL) {

        avPlayer.pause()
        if(self.observing) {
            avPlayer.removeObserver(self, forKeyPath: "rate", context: &observerContext)
            self.observing = false
        }

        self.setActiveAudioSession()
        print(playUrl.absoluteString)
        let playerItem = AVPlayerItem(url: playUrl)
        avPlayer.addObserver(self, forKeyPath: "rate", options:.new, context: &observerContext)
        self.observing = true
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

    private func stopPlaying() {
            avPlayer.pause()
            if(self.observing) {
                avPlayer.removeObserver(self, forKeyPath: "rate", context: &observerContext)
                self.observing = false
            }
            self.sliderProgressSubject.send(0)
    }

    private func loadNowPlayingMediaArtwork() {
        guard let url = self.playingFile?.iconUrl else { return }
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.playingImage = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                        self?.setPlayingInfo(playing: false)
                    }
                }
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
            fatalError("Failure to session: \(error)")
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if avPlayer == object as! AVPlayer && "rate" == keyPath {
                DispatchQueue.main.async {
                    self.playing  = self.avPlayer.rate > 0.0
                    self.playingSubject.send(self.avPlayer.rate > 0.0)
                    self.monitorPlayback()
                }
            }

            if avPlayer == object as? AVPlayer && keyPath == #keyPath(AVPlayer.currentItem.status) {
                let newStatus: AVPlayerItem.Status
                if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                    newStatus = AVPlayerItem.Status(rawValue: newStatusAsNumber.intValue)!
                } else {
                    newStatus = .unknown
                }
                if newStatus == .failed {
                    print("Error: \(String(describing: self.avPlayer.currentItem?.error?.localizedDescription)), error: \(String(describing: self.avPlayer.currentItem?.error))")
                }
            }
    }

    private func monitorPlayback() {

            if(avPlayer.currentItem != nil) {
                let progress = CMTimeGetSeconds(avPlayer.currentTime()) / CMTimeGetSeconds((avPlayer.currentItem?.duration)!)
                self.sliderProgress = progress
                if !pauseSliderProgress {
                    DispatchQueue.main.async {
                        self.sliderProgressSubject.send(progress)
                        self.durationSubject.send(CMTimeGetSeconds((self.avPlayer.currentItem?.duration)!))
                    }
                }

                if(avPlayer.rate != 0.0) {
                    let delay = 0.1 * Double(NSEC_PER_SEC)
                    let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
                    DispatchQueue.main.asyncAfter(deadline: time) {
                        self.monitorPlayback()
                    }
                }
            }
            return
    }

    private func elapsedSeconds()->Int {
        let calcTime = CMTimeGetSeconds((avPlayer.currentItem?.duration)!) - CMTimeGetSeconds(avPlayer.currentTime())
        if(!calcTime.isNaN) {
            let duration = CMTimeGetSeconds((avPlayer.currentItem?.duration)!)
            return Int(duration) - Int(calcTime)
        }
        return 0
    }

    private func setPlayingInfo(playing:Bool) {

        let artist = self.playingFile?.displayArtist
        let fileTitle = self.playingFile?.displayTitle ?? self.fileIdentifierTitle

        if let playItem = avPlayer.currentItem {
            playItem.nowPlayingInfo = [
                MPMediaItemPropertyTitle : fileTitle ?? "",
                MPMediaItemPropertyArtist: artist ?? "",
                MPNowPlayingInfoPropertyPlaybackQueueCount: self.items.count,
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

    var seekTimer: Timer?
    let seekInterval: CMTime = CMTimeMakeWithSeconds(1, preferredTimescale: 600) // 1 second seek intervals

    private func sessionRemote(session: MPNowPlayingSession) {

        session.remoteCommandCenter.playCommand.addTarget { event in
            self.avPlayer.play()
            return .success
        }

        session.remoteCommandCenter.pauseCommand.addTarget { event in
            self.avPlayer.pause()
            return .success
        }

        session.remoteCommandCenter.togglePlayPauseCommand.addTarget { event in
            self.playing ? self.avPlayer.pause() : self.avPlayer.play()
            return .success
        }

        // Set up fast-forward command
        session.remoteCommandCenter.seekForwardCommand.addTarget(self, action: #selector(handleSeekForwardCommand))
        // Set up rewind command
        session.remoteCommandCenter.seekBackwardCommand.addTarget(self, action: #selector(handleSeekBackwardCommand))

        session.remoteCommandCenter.changePlaybackPositionCommand.addTarget { [weak self] remoteEvent in

            if let event = remoteEvent as? MPChangePlaybackPositionCommandEvent {
                let playerRate = self?.avPlayer.rate
                self?.avPlayer.seek(to: CMTime(seconds: event.positionTime, preferredTimescale: CMTimeScale(1000)), completionHandler: { [weak self](success) in
                     guard let self = self else {return}
                     if success, let r = playerRate {
                         self.avPlayer.rate = r
                     }
                 })
                 return .success
              }
            
            return .commandFailed
        }

        session.remoteCommandCenter.nextTrackCommand.addTarget { event in

            guard let list = self.playingPlaylist, let files = self.playingPlaylist?.files as? [ArchiveFileEntity] else { return .commandFailed }

            if let playingFile = self.playingFile, let index = files.firstIndex(of: playingFile) {
                guard self.items.indices.contains(index + 1) else { return .commandFailed }
                self.playFileFromPlaylist(self.items[index + 1], playlist: list)

                return .success
            }
            return .commandFailed
        }

        session.remoteCommandCenter.previousTrackCommand.addTarget { event in

            guard let list = self.playingPlaylist, let files = self.playingPlaylist?.files as? [ArchiveFileEntity] else { return .commandFailed }


            if let playingFile = self.playingFile, let index = files.firstIndex(of: playingFile) {
                guard self.items.indices.contains(index - 1) else { return .commandFailed }
                self.playFileFromPlaylist(self.items[index - 1], playlist: list)
                return .success
            }
            return .commandFailed
        }

    }

    @objc private func handleSeekForwardCommand(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        // Toggle the timer action
        self.seek(forward: true)
        return .success
    }

    @objc private func handleSeekBackwardCommand(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        // Toggle the timer action
        self.seek(forward: false)
        return .success
    }

    func seek(forward: Bool) {
        if seekTimer == nil {
            startSeeking(forward: forward)
        } else {
            stopSeeking()
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
