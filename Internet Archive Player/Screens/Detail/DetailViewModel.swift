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

final class DetailViewModel: ObservableObject {
    let service: PlayerArchiveService
    @Published var archiveDoc: ArchiveMetaData? = nil
    @Published var audioFiles = [ArchiveFile]()
    @Published var movieFiles = [ArchiveFile]()

    @Published var playingFile: ArchiveFileEntity?

    @Published var playlistArchiveFile: ArchiveFile?

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
//                    var h264HD = video.filter {$0.format == .h264HD || $0.format == .h264 || $0.format == .mpg512kb}
//                    self.movieFiles = h264HD.count > 0 ? h264HD : video
                    self.movieFiles = desiredVideo(files:video)
                }

            } catch {
                print(error)
            }
        }
    }

    private func desiredVideo(files: [ArchiveFile]) -> [ArchiveFile] {
//        var h264HD = files.filter {$0.format == .h264HD }
//        var h264 = files.filter { $0.format == .h264 }
//        var mpg512 = files.filter { $0.format == .mpg512kb }

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
}
