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

    @Published var pressedStates: [Int: Bool] = [:]

    var player: AVPlayer? = nil

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.service = PlayerArchiveService()
    }

    public func passInPlayer(iaPlayer: Player) {
        self.iaPlayer = iaPlayer
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
                    Detail.backgroundPass.send(art)
                    self.uiImage = await IAMediaUtils.getImage(url: art)
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
}
