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
}

extension PlayerError: CustomStringConvertible {
    var description: String {
        switch self {
        case .alreadyOnPlaylist:
            return "Item is already on the playlist."
        }
    }
}


class Player: NSObject, ObservableObject {

    static let shared = Player()

    @Published var showPlayingDetailView = false

    public enum AdvanceDirection: Int {
        case forwards = 1
        case backwards = -1
    }

    private var mainPlaylist: PlaylistEntity? = nil
    public var playingFile: ArchiveFileEntity? = nil
    @Published var items: [ArchiveFileEntity] = [ArchiveFileEntity]()
    public var avPlayer: AVPlayer?
    private var observing = false
    fileprivate var observerContext = 0
    private var playing = false

    var fileTitle: String?
    var fileIdentifierTitle: String?
    var fileIdentifier: String?
    var mediaArtwork : MPMediaItemArtwork?
    var itemSubscritpions: Set<AnyCancellable> = Set<AnyCancellable>()

    private let playlistFetchController: NSFetchedResultsController<PlaylistEntity>

    override init() {
        playlistFetchController = NSFetchedResultsController(fetchRequest: PlaylistEntity.playlistFetchRequest,
                                                             managedObjectContext: PersistenceController.shared.container.viewContext,
                                                             sectionNameKeyPath: nil, cacheName: nil)
        super.init()
        playlistFetchController.delegate = self

        do {
          try playlistFetchController.performFetch()
          //items = playlistFetchController.fetchedObjects ?? []
            if let playlist = playlistFetchController.fetchedObjects?.first {
                mainPlaylist = playlist
                if let files = mainPlaylist?.files?.array as? [ArchiveFileEntity] {
                    items = files
                }
            } else {
                mainPlaylist = PlaylistEntity(context: PersistenceController.shared.container.viewContext)
                mainPlaylist?.name = "main"
                PersistenceController.shared.save()
            }

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
        guard let playlist = mainPlaylist else { return }
        let archiveFileEntity = item.archiveFileEntity()

        let sameValues = self.items.filter {$0.onlineUrl?.absoluteString == archiveFileEntity.onlineUrl?.absoluteString }
        guard sameValues.isEmpty else { throw PlayerError.alreadyOnPlaylist }

        playlist.addToFiles(archiveFileEntity)
        PersistenceController.shared.save()
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

    public func removePlaylistItem(at offsets: IndexSet){
        self.removePlayListEntities(at: offsets)
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

    private func removePlayListEntities(at offsets: IndexSet) {
        guard let playlist = mainPlaylist else { return }
        for index in offsets {
            let archiveFileEntity = items[index]
            self.deleteLocalFile(item: archiveFileEntity)
            playlist.removeFromFiles(archiveFileEntity)
            PersistenceController.shared.delete(archiveFileEntity, false)
        }
        PersistenceController.shared.save()
    }


    public func rearrangePlaylist(fromOffsets source: IndexSet, toOffset destination: Int) {
        guard let playlist = mainPlaylist else { return }
//        playlist.
//        //self.items.move(fromOffsets: source, toOffset: destination)

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
        self.loadAndPlay(archiveFileEntity.workingUrl!)
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


        if playing {
            UIApplication.shared.beginReceivingRemoteControlEvents()
        }

        let playBackRate = playing ? 1.0 : 0.0


        var songInfo : [String : AnyObject] = [
            MPNowPlayingInfoPropertyElapsedPlaybackTime : NSNumber(value: Double(self.elapsedSeconds()) as Double),
            MPMediaItemPropertyAlbumTitle: self.fileIdentifierTitle! as AnyObject,
            MPMediaItemPropertyPlaybackDuration : NSNumber(value: CMTimeGetSeconds((self.avPlayer?.currentItem?.duration)!) as Double),
            MPNowPlayingInfoPropertyPlaybackRate: playBackRate as AnyObject,
        ]

        songInfo[MPMediaItemPropertyTitle] = self.fileTitle as AnyObject?
        songInfo[MPMediaItemPropertyArtist] = self.playingFile?.artist as AnyObject
//        if let image = await getImage() {
//            songInfo[MPMediaItemPropertyArtwork] = image
//        }



            MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo

//        if let identifier = self.playingFile?.identifier {


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
//        }
    }

    private func getImage() async -> UIImage? {

        if let iconUrl = self.playingFile?.iconUrl {
            async let (data, _) = try! await URLSession.shared.data(from: iconUrl)
            return await UIImage(data: data)
        }

        return nil
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
      guard let playlist = controller.fetchedObjects?.first as? PlaylistEntity
      else { return }
      DispatchQueue.main.async {
          if let files = playlist.files?.array as? [ArchiveFileEntity] {
              self.items = files
          }
      }
  }
}
