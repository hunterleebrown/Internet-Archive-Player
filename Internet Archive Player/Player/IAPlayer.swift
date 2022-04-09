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

class IAPlayer: NSObject, ObservableObject {
    @Published var showPlaylist = false
    @Published var playing = false
    @Published var minTime: String? = nil
    @Published var maxTime: String? = nil
    @Published var sliderProgress: Double = 0
    @Published var playingFile: PlaylistItem? = nil
    @Published public private(set) var items: [PlaylistItem] = [PlaylistItem]()

    var avPlayer: AVPlayer?
    var observing = false
    var playUrl: URL!

    fileprivate var observerContext = 0

    var fileTitle: String?
    var fileIdentifierTitle: String?
    var fileIdentifier: String?

    var mediaArtwork : MPMediaItemArtwork?

    var itemSubscritpions: Set<AnyCancellable> = Set<AnyCancellable>()

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(continuePlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        self.setUpRemoteCommandCenterEvents()
        $items.sink { playListItems in
            print("IAPlayer items are now: \(playListItems)");
        }.store(in: &itemSubscritpions)
    }

    public func appendPlaylistItem(_ item: PlaylistItem){
        if !self.items.contains(item) {
            self.items.append(item)
        }
    }

    public func clearPlaylist() {
        self.items.removeAll()
    }

    public func removePlaylistItem(at offsets: IndexSet){
        self.items.remove(atOffsets: offsets)
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

    func playFile(_ playerFile: PlaylistItem){

        self.fileTitle = playerFile.file.title ?? playerFile.file.name
        self.fileIdentifierTitle = playerFile.identifierTitle
        self.fileIdentifier = playerFile.identifier
        self.playUrl = playerFile.fileUrl()

        self.playingFile = playerFile

        self.loadAndPlay()
    }

    private func loadAndPlay() {

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

        avPlayer = AVPlayer(url: self.playUrl as URL)

        avPlayer?.addObserver(self, forKeyPath: "rate", options:.new, context: &observerContext)
        self.observing = true

        avPlayer?.play()
        self.setPlayingInfo(playing: true)

    }

    func didTapPlayButton() {

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

    func setActiveAudioSession(){
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
                self.playing  = player.rate > 0.0
                self.monitorPlayback()
            }
        }
    }

    func monitorPlayback() {

        if let player = avPlayer {
            if(player.currentItem != nil) {
                let progress = CMTimeGetSeconds(player.currentTime()) / CMTimeGetSeconds((player.currentItem?.duration)!)
                self.sliderProgress = progress;
                updatePlayerTimes()
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

    func updatePlayerTimes() {

        if let player = avPlayer {
            let calcTime = CMTimeGetSeconds((player.currentItem?.duration)!) - CMTimeGetSeconds(player.currentTime())
            if(!calcTime.isNaN) {
                minTime = IAStringUtils.timeFormatted(self.elapsedSeconds())
                maxTime = IAStringUtils.timeFormatted(Int(calcTime))
            }
        }
    }

    func elapsedSeconds()->Int {
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


    func setPlayingInfo(playing:Bool) {

        if let identifier = self.playingFile?.identifier {

            let imageView = UIImageView()
            let url = IAMediaUtils.imageUrlFrom(identifier)

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



    func setUpRemoteCommandCenterEvents() {
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
