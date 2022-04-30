//
//  IAPlayer.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 2/6/22.
//

import Foundation
import iaAPI
import MediaPlayer
import AVFoundation
import AVKit
import UIKit
import Combine
import CoreData

class Player: NSObject, ObservableObject {

    static let shared = Player()

    @Published var showPlayingDetailView = false

    public enum AdvanceDirection: Int {
        case forwards = 1
        case backwards = -1
    }

    private var playingFile: ArchiveFileEntity? = nil
    @Published var items: [ArchiveFileEntity] = [ArchiveFileEntity]()
    private var avPlayer: AVPlayer?
    private var observing = false
    fileprivate var observerContext = 0
    private var playing = false

    var fileTitle: String?
    var fileIdentifierTitle: String?
    var fileIdentifier: String?
    var mediaArtwork : MPMediaItemArtwork?
    var itemSubscritpions: Set<AnyCancellable> = Set<AnyCancellable>()

    private let playlistFetchController: NSFetchedResultsController<ArchiveFileEntity>

    override init() {
        playlistFetchController = NSFetchedResultsController(fetchRequest: ArchiveFileEntity.playlistFetchRequest,
                                                             managedObjectContext: PersistenceController.shared.container.viewContext,
                                                             sectionNameKeyPath: nil, cacheName: nil)

        super.init()

        playlistFetchController.delegate = self

        do {
          try playlistFetchController.performFetch()
          items = playlistFetchController.fetchedObjects ?? []
        } catch {
          print("failed to fetch items!")
        }

        NotificationCenter.default.addObserver(self, selector: #selector(continuePlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        self.setUpRemoteCommandCenterEvents()
    }

    private let playingSubject = PassthroughSubject<Bool, Never>()
    public var playingPublisher: AnyPublisher<Bool, Never> {
        playingSubject.eraseToAnyPublisher()
    }

    private let itemsSubject = PassthroughSubject<[ArchiveFileEntity], Never>()
    public var itemsPublisher: AnyPublisher<[ArchiveFileEntity], Never> {
        itemsSubject.eraseToAnyPublisher()
    }
    public func sendItemsPlaylist() {
        itemsSubject.send(self.items)
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

    public func appendPlaylistItem(_ item: ArchiveFile){
        let entity = item.archiveFileEntity()
        if !self.items.contains(entity) {
            self.updatePlaylistSubscribers()
            PersistenceController.shared.save()
        }
    }

    public func getPlaylist() -> [ArchiveFileEntity] {
        return self.items
    }

    public func clearPlaylist() {
        for item in items {
            PersistenceController.shared.delete(item, false)
        }
        PersistenceController.shared.save()
        self.updatePlaylistSubscribers()
    }

    public func removePlaylistItem(at offsets: IndexSet){
        self.removePlayListEntities(at: offsets)
        self.updatePlaylistSubscribers()
    }

    private func removePlayListEntities(at offsets: IndexSet) {
        for index in offsets {
            let archiveFileEntity = items[index]
            PersistenceController.shared.delete(archiveFileEntity, false)
        }
        PersistenceController.shared.save()
    }


    public func rearrangePlaylist(fromOffsets source: IndexSet, toOffset destination: Int) {
        self.items.move(fromOffsets: source, toOffset: destination)
        self.updatePlaylistSubscribers()
    }

    private func updatePlaylistSubscribers() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.itemsSubject.send(self.items)
        }
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
        let entity = archiveFile.archiveFileEntity()
        PersistenceController.shared.save()
        playFile(entity)
    }

    public func playFile(_ archiveFileEntity: ArchiveFileEntity){
        self.fileTitle = archiveFileEntity.title ?? archiveFileEntity.name
        self.fileIdentifierTitle = archiveFileEntity.archiveTitle
        self.fileIdentifier = archiveFileEntity.identifier
        self.playingFile = archiveFileEntity
        self.playingFileSubject.send(archiveFileEntity)
        self.loadAndPlay(archiveFileEntity.url!)
    }


    public func advancePlayer(_ advanceDirection: AdvanceDirection) {
        if let playingFile = self.playingFile, let index = items.firstIndex(of: playingFile) {
            guard items.indices.contains(index + advanceDirection.rawValue) else { return }
            playFile(items[index + advanceDirection.rawValue])
        }
    }

    private func loadAndPlay(_ playUrl: URL) {

        if playUrl.absoluteString.contains("https") {
            guard IAReachability.isConnectedToNetwork() else {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "networkAlert"), object: nil)
                return
            }
        }

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

        avPlayer = AVPlayer(url: playUrl)
        avPlayer?.addObserver(self, forKeyPath: "rate", options:.new, context: &observerContext)
        self.observing = true
        avPlayer?.play()
        self.setPlayingInfo(playing: true)

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
                    }
                }

                if(player.rate != 0.0) {
                    let delay = 0.1 * Double(NSEC_PER_SEC)
                    let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
                    DispatchQueue.main.asyncAfter(deadline: time) {
                        self.monitorPlayback()
                    }
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


    private func setPlayingInfo(playing:Bool) {

        if let identifier = self.playingFile?.identifier {

            if playing {
                UIApplication.shared.beginReceivingRemoteControlEvents()
            }
            

//            imageView.af.setImage(
//                withURL: url!,
//                placeholderImage: nil,
//                filter: nil,
//                progress: nil,
//                progressQueue: DispatchQueue.main,
//                imageTransition: UIImageView.ImageTransition.noTransition,
//                runImageTransitionIfCached: false) { [self] (response) in
//
//                    switch response.result {
//                    case .success(let image):
//                        self.mediaArtwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { (size) -> UIImage in
//                            image
//                        })
//
////                        self.controlsController?.playerIcon.image = image
////                        self.controlsController?.playerIcon.backgroundColor = UIColor.white
//
//                        let playBackRate = playing ? 1.0 : 0.0
//
//                        var songInfo : [String : AnyObject] = [
//                            MPNowPlayingInfoPropertyElapsedPlaybackTime : NSNumber(value: Double(self.elapsedSeconds()) as Double),
//                            MPMediaItemPropertyAlbumTitle: self.fileIdentifier! as AnyObject,
//                            MPMediaItemPropertyPlaybackDuration : NSNumber(value: CMTimeGetSeconds((self.avPlayer?.currentItem?.duration)!) as Double),
//                            MPNowPlayingInfoPropertyPlaybackRate: playBackRate as AnyObject
//                        ]
//
//                        if let artwork = self.mediaArtwork {
//                            songInfo[MPMediaItemPropertyArtwork] = artwork
//                        }
//
//                        songInfo[MPMediaItemPropertyTitle] = self.fileTitle as AnyObject?
//                        songInfo[MPMediaItemPropertyAlbumArtist] = self.playingFile?.artist as AnyObject
//
//
//                        MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
//
//
//                    case .failure(let error):
//                        print("-----------> player couldn't get image: \(error)")
//                        break
//                    }
//                }
        }
    }



    private func setUpRemoteCommandCenterEvents() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { event in
            self.avPlayer?.play()
            return .success
        }

        commandCenter.pauseCommand.addTarget { event in
            self.avPlayer?.pause()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { event in
            if let playingFile = self.playingFile, let index = self.items.firstIndex(of: playingFile) {
                guard self.items.indices.contains(index + 1) else { return .commandFailed }
                self.playFile(self.items[index + 1])
                return .success
            }
            return .commandFailed
        }

        commandCenter.previousTrackCommand.addTarget { event in
            if let playingFile = self.playingFile, let index = self.items.firstIndex(of: playingFile) {
                guard self.items.indices.contains(index - 1) else { return .commandFailed }
                self.playFile(self.items[index - 1])
                return .success
            }
            return .commandFailed
        }
    }

}

extension Player: NSFetchedResultsControllerDelegate {
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    guard let playlistItems = controller.fetchedObjects as? [ArchiveFileEntity]
      else { return }
      DispatchQueue.main.async {
          self.items = playlistItems
      }
  }
}
