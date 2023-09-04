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

                self.movieFiles = doc.files.filter{ $0.format == .h264 }

            } catch {
                print(error)
            }
        }
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
