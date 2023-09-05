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

    static let shared = Player()

    @Published var showPlayingDetailView = false

    static var networkAlert = PassthroughSubject<Bool, Never>()

    public enum AdvanceDirection: Int {
        case forwards = 1
        case backwards = -1
    }

    var mainPlaylist: PlaylistEntity? = nil
    var favoritesPlaylist: PlaylistEntity? = nil

    public var playingFile: ArchiveFileEntity? {
        didSet {
            self.loadNowPlayingMediaArtwork()
        }
    }

    private var playingMediaType: MPNowPlayingInfoMediaType? = nil

    @Published var items: [ArchiveFileEntity] = [ArchiveFileEntity]()
    @Published var favoriteItems: [ArchiveFileEntity] = [ArchiveFileEntity]()

    @Published public var avPlayer: AVPlayer?

    private var observing = false
    fileprivate var observerContext = 0
    private var playing = false

    private var playingImage: MPMediaItemArtwork?

    var fileTitle: String?
    var fileIdentifierTitle: String?
    var fileIdentifier: String?
    var itemSubscritpions: Set<AnyCancellable> = Set<AnyCancellable>()

    let presentingController = AVPlayerViewController()

    private let playlistFetchController: NSFetchedResultsController<PlaylistEntity>
    private let favoritesFetchController: NSFetchedResultsController<PlaylistEntity>


    override init() {
        playlistFetchController =
        NSFetchedResultsController(fetchRequest:  PlaylistEntity.fetchRequest(playlistName: "main"),
                                   managedObjectContext: PersistenceController.shared.container.viewContext,
                                   sectionNameKeyPath: nil,
                                   cacheName: nil)

        favoritesFetchController =
        NSFetchedResultsController(fetchRequest:  PlaylistEntity.fetchRequest(playlistName: "favorites"),
                                   managedObjectContext: PersistenceController.shared.container.viewContext,
                                   sectionNameKeyPath: nil,
                                   cacheName: nil)
        super.init()
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
                mainPlaylist?.name = "main"
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
                favoritesPlaylist?.name = "favorites"
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
        guard let currentItem = avPlayer?.currentItem else { return }
        if let player = avPlayer {
            let duration = CMTimeGetSeconds(currentItem.duration)
            let sec = duration * Float64(sliderValue)
            let seakTime:CMTime = CMTimeMakeWithSeconds(sec, preferredTimescale: 600)
            player.seek(to: seakTime) { _ in
                self.shouldPauseSliderProgress(false)
            }
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
        self.playFile(archiveFileEntity)
    }

    public func appendPlaylistItem(archiveFileEntity: ArchiveFileEntity) throws {
        guard let playlist = mainPlaylist else { return }

        let sameValues = self.items.filter {$0.onlineUrl?.absoluteString == archiveFileEntity.onlineUrl?.absoluteString }
        guard sameValues.isEmpty else { throw PlayerError.alreadyOnPlaylist }

        playlist.addToFiles(archiveFileEntity)
        PersistenceController.shared.save()
    }

    public func appendFavoriteItem(_ item: ArchiveFile) throws {
        guard let playlist = favoritesPlaylist else { return }
        let archiveFileEntity = item.archiveFileEntity()

        let sameValues = self.favoriteItems.filter {$0.onlineUrl?.absoluteString == archiveFileEntity.onlineUrl?.absoluteString }
        guard sameValues.isEmpty else { throw PlayerError.alreadyOnFavorites }

        playlist.addToFiles(archiveFileEntity)
        PersistenceController.shared.save()
    }

    public func checkDupes(archiveFile: ArchiveFile) throws {
        let sameValues = self.items.filter {$0.onlineUrl?.absoluteString == archiveFile.url?.absoluteString }
        guard sameValues.isEmpty else { throw PlayerError.alreadyOnPlaylist }
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
            let archiveFileEntity = playlist.name == "main" ? items[index] : favoriteItems[index]
            if let playingFile = self.playingFile, playingFile == archiveFileEntity{
                self.stopPlaying()
            }
            self.deleteLocalFile(item: archiveFileEntity)
            playlist.removeFromFiles(archiveFileEntity)
            PersistenceController.shared.delete(archiveFileEntity, false)
        }
        PersistenceController.shared.save()
        self.playingFile = nil
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

        if let playingFile = playingFile, let index = items.firstIndex(of: playingFile) {
            guard items.indices.contains(index + 1) else { return }
            playFile(items[index + 1])
        }

    }

    public func playFile(_ archiveFile: ArchiveFile){
        guard let playlist = mainPlaylist else { return }
        let archiveFileEntity = archiveFile.archiveFileEntity()
        playlist.addToFiles(archiveFileEntity)
        PersistenceController.shared.save()
        playFile(archiveFileEntity)
    }

    // This should only be called by the playlist
    public func playFile(_ archiveFileEntity: ArchiveFileEntity){

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
        if let playingFile = self.playingFile, let index = items.firstIndex(of: playingFile) {
            guard items.indices.contains(index + advanceDirection.rawValue) else { return }
            playFile(items[index + advanceDirection.rawValue])
        }
    }

    private func loadAndPlay(_ playUrl: URL) {

        if let player = avPlayer {
            player.pause()
            if(self.observing) {
                player.removeObserver(self, forKeyPath: "rate", context: &observerContext)
                self.observing = false
            }
            self.setPlayingInfo(playing: false)
            avPlayer = nil
        }

        self.setActiveAudioSession()
        print(playUrl.absoluteString)
        avPlayer = AVPlayer(url: playUrl)
        avPlayer?.addObserver(self, forKeyPath: "rate", options:.new, context: &observerContext)
        self.observing = true
        avPlayer?.play()
        self.setPlayingInfo(playing: true)

        print("Playing File: ")
        dump(playingFile?.format)

        if playingFile?.format != "VBR MP3" {
            PlayerControls.showVideo.send(true)
        } else {
            PlayerControls.showVideo.send(false)
        }

    }

    private func stopPlaying() {
        if let player = avPlayer {
            player.pause()
            if(self.observing) {
                player.removeObserver(self, forKeyPath: "rate", context: &observerContext)
                self.observing = false
            }
            self.setPlayingInfo(playing: false)
            avPlayer = nil
            self.sliderProgressSubject.send(0)
        }
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

        if let player = avPlayer {
            if player.currentItem != nil && self.playing {
                player.pause()
                self.setPlayingInfo(playing: false)
            } else {
                player.play()
                self.setPlayingInfo(playing: true)
            }
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
        if let player = avPlayer {
            if player == object as! AVPlayer && "rate" == keyPath {
                DispatchQueue.main.async {
                    self.playing  = player.rate > 0.0
                    self.playingSubject.send(player.rate > 0.0)
                    self.monitorPlayback()
                }
            }

            if player == object as? AVPlayer && keyPath == #keyPath(AVPlayer.currentItem.status) {
                let newStatus: AVPlayerItem.Status
                if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                    newStatus = AVPlayerItem.Status(rawValue: newStatusAsNumber.intValue)!
                } else {
                    newStatus = .unknown
                }
                if newStatus == .failed {
                    NSLog("Error: \(String(describing: self.avPlayer?.currentItem?.error?.localizedDescription)), error: \(String(describing: self.avPlayer?.currentItem?.error))")
                }
            }
        }
    }

    private func monitorPlayback() {

        if let player = avPlayer {
            if(player.currentItem != nil) {
                let progress = CMTimeGetSeconds(player.currentTime()) / CMTimeGetSeconds((player.currentItem?.duration)!)
                self.sliderProgress = progress
                if !pauseSliderProgress {
                    DispatchQueue.main.async {
                        self.sliderProgressSubject.send(progress)
                        self.durationSubject.send(CMTimeGetSeconds((player.currentItem?.duration)!))
                        if progress < 1.0 {
                            self.liveNowPlaying(playing: true)
                        }
                    }
                }

                if(player.rate != 0.0) {
                    let delay = 0.1 * Double(NSEC_PER_SEC)
                    let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
                    DispatchQueue.main.asyncAfter(deadline: time) {
                        self.monitorPlayback()
                    }
                } else {
//                    DispatchQueue.main.async {
//                        self.liveNowPlaying(playing: false)
//                    }
                }
            }
            return
        }
    }

    private func elapsedSeconds()->Int {
        if let player = avPlayer {

            let calcTime = CMTimeGetSeconds((player.currentItem?.duration)!) - CMTimeGetSeconds(player.currentTime())
            if(!calcTime.isNaN) {
                let duration = CMTimeGetSeconds((player.currentItem?.duration)!)
                return Int(duration) - Int(calcTime)
            }
            return 0
        }

        return 0
    }

    public func setPlayingInfo(playing:Bool) {

//        if playing {
//            UIApplication.shared.beginReceivingRemoteControlEvents()
//        }

        let artist = self.playingFile?.displayArtist
        let fileTitle = self.playingFile?.displayTitle ?? self.fileIdentifierTitle

        var songInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()

        songInfo[MPMediaItemPropertyTitle] = fileTitle
        songInfo[MPMediaItemPropertyArtist] = artist
        songInfo[MPMediaItemPropertyAlbumArtist] = artist
        songInfo[MPMediaItemPropertyAlbumTitle] = self.fileIdentifierTitle
        songInfo[MPNowPlayingInfoPropertyPlaybackQueueCount] = self.items.count
        if let curFile = self.playingFile, let index = self.items.firstIndex(of: curFile) {
            songInfo[MPNowPlayingInfoPropertyPlaybackQueueIndex] = index
            songInfo[MPMediaItemPropertyMediaType] = curFile.isAudio ? MPMediaType.anyAudio.rawValue : MPMediaType.anyVideo.rawValue
        }

        if let image = self.playingImage {
            songInfo[MPMediaItemPropertyArtwork] = image
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
    }

    public func liveNowPlaying(playing: Bool) {

        if let player = self.avPlayer {
            let playBackRate = playing ? 1.0 : 0.0

            var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()

            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds((player.currentItem?.duration)!)
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.elapsedSeconds()
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playBackRate
//            nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
            //        nowPlayingInfo[MPNowPlayingInfoPropertyCurrentLanguageOptions] = metadata.currentLanguageOptions
            //        nowPlayingInfo[MPNowPlayingInfoPropertyAvailableLanguageOptions] = metadata.availableLanguageOptionGroups

            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }

    }


    private func getImage() async -> UIImage? {

        if let iconUrl = self.playingFile?.iconUrl {
            async let (data, _) = try! await URLSession.shared.data(from: iconUrl)
            return await UIImage(data: data)
        }

        return nil
    }
}

extension Player: NSFetchedResultsControllerDelegate {
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
      guard let playlist = controller.fetchedObjects?.first as? PlaylistEntity
      else { return }
      DispatchQueue.main.async {
          if let files = playlist.files?.array as? [ArchiveFileEntity] {

              switch playlist.name {
              case "main":
                  self.items = files
              case "favorites":
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
