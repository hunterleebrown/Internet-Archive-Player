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

class IAPlayer: NSObject, ObservableObject {

    var avPlayer: AVPlayer?
//    var controlsController : IAPlayerViewController?
    var observing = false
    @Published var playing = false
    var playUrl: URL!

    fileprivate var observerContext = 0


    static let sharedInstance: IAPlayer = {
        return IAPlayer()
    }()

    var fileTitle: String?
    var fileIdentifierTitle: String?
    var fileIdentifier: String?

    var mediaArtwork : MPMediaItemArtwork?

//    typealias PlaylistWithIndex = (list:IAList, index:Int)
//    var playingPlaylistWithIndex: PlaylistWithIndex?

    func playFile(file:IAFile, doc:IAArchiveDoc){

        self.fileTitle = file.title ?? file.name
        self.fileIdentifierTitle = doc.title
        self.fileIdentifier = doc.identifier
        self.playUrl = doc.fileUrl(file: file)

        self.loadAndPlay()
    }

    private func loadAndPlay() {

        if playUrl.absoluteString.contains("http") {
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

//            if let controller = self.controlsController, controller.playingProgress != nil {
//                controller.playingProgress.setValue(Float(0), animated: false)
//            }

//            self.setPlayingInfo(playing: false)
            avPlayer = nil
        }

        self.setActiveAudioSession()

//        if let controller = controlsController {
//            controller.nowPlayingTitle.text = self.fileTitle
//            controller.nowPlayingItemButton.setTitle(self.fileIdentifierTitle, for: .normal)
//            controller.displayNowPlayingTitle(message: self.fileTitle!)
//        }

        avPlayer = AVPlayer(url: self.playUrl as URL)

        avPlayer?.addObserver(self, forKeyPath: "rate", options:.new, context: &observerContext)
        self.observing = true

        avPlayer?.play()
//        self.setPlayingInfo(playing: true)

//        if let pI = playListWithIndex {
//            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
//
//            self.controlsController?.playList = pI.list
//            self.playingPlaylistWithIndex = pI
//
//            NotificationCenter.default.addObserver(self, selector: #selector(IAPlayer.continuePlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
//
//        } else {
//            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
//        }

    }

    func didTapPlayButton() {

        if let player = avPlayer {
            if player.currentItem != nil && self.playing {
                player.pause()
//                self.setPlayingInfo(playing: false)
            } else {
                player.play()
//                self.setPlayingInfo(playing: true)
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

        if let player = avPlayer { //, let controller = controlsController

            if player == object as! AVPlayer && "rate" == keyPath {
                print("rate changed: \(player.rate)")

                if player.rate == 0 {
//                    controller.playButton.setIAIcon(.iosPlayOutline, forState: UIControl.State())
                } else {
//                    controller.playButton.setIAIcon(.iosPauseOutline, forState: UIControl.State())
                }

                self.playing  = player.rate > 0.0
//                if controller.activityIndicator != nil {
//                    player.rate > 0.0 ? controller.activityIndicator.startAnimating() : controller.activityIndicator.stopAnimating()
//                }

//                self.monitorPlayback()
            }

        }
    }

}
