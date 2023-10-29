//
//  TVDetail.swift
//  Internet Archive Player tvOS
//
//  Created by Hunter Lee Brown on 10/28/23.
//

import Foundation
import SwiftUI
import iaAPI
import AVKit
import Combine

struct TVDetail: View {

    @Environment(\.presentationMode) var presentation
    @StateObject private var viewModel = DetailViewModel()

    var doc: ArchiveMetaData
    static var backgroundPass = PassthroughSubject<URL, Never>()

    @State var imageUrl: URL?

    var body: some View {
        NavigationView {
            HStack(alignment: .top, spacing:20) {
                VStack(alignment: .leading, spacing:10) {
                    HStack(alignment: .top, spacing: 20) {

                        Button {
                            self.presentation.wrappedValue.dismiss()

                        } label: {
                            Image(systemName: "chevron.left")
                        }

                        Text(doc.archiveTitle ?? "")
                            .font(.largeTitle)
                            .multilineTextAlignment(.leading)
                            .frame(alignment: .center)
                    }
                    .frame(alignment: .topLeading)

                    if let artist = self.viewModel.archiveDoc?.artist ?? self.viewModel.archiveDoc?.creator?.joined(separator: ", "), !artist.isEmpty {
                        Text(artist)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                            .frame(alignment: .leading)

                    }


                    if (self.viewModel.archiveDoc?.description) != nil {
                        NavigationLink {
                            if let goodDoc = viewModel.archiveDoc {
                                DetailDescription(doc: goodDoc)
                            }
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.largeTitle)
                                .tint(.fairyRed)
                                .padding(10)
                        }
                    }

                    if self.viewModel.movieFiles.count > 0 {
                        Text("Movies")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.black)
                            .padding(5)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 5.0,
                                    style: .continuous
                                )
                                .fill(Color.white.opacity(0.5))
                            )
                        List {
                            ForEach(self.viewModel.movieFiles, id: \.self) { file in

                                NavigationLink {
                                    var player = AVPlayer(url: file.url!)

                                    VideoPlayer(player: player)
                                        .ignoresSafeArea()
                                        .onAppear() {
                                            player.play()
                                        }
                                        .onDisappear() {
                                            player.pause()
                                        }
                                } label: {
                                    Text(file.displayTitle)
                                        .padding(.leading, 5.0)
                                        .padding(.trailing, 5.0)
                                        .frame(alignment: .leading)
                                        .multilineTextAlignment(.leading)

                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }

                    Spacer()




                }

                AsyncImage(url: imageUrl, transaction: Transaction(animation: .spring())) { phase in
                    switch phase {
                    case .empty:
                        Color.clear

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .clipped()
                            .cornerRadius(10)

                    case .failure(_):
                        EmptyView()

                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width:800)
                .cornerRadius(10)

            }
            .padding(50)
            .frame(alignment: .topLeading)

        }
        .onReceive(TVDetail.backgroundPass) { url in
            withAnimation(.linear(duration: 0.3)) {
                imageUrl = url
            }
        }
        .onAppear() {
            if let identifier = doc.identifier {
                self.viewModel.getArchiveDoc(identifier: identifier)
            }
        }
    }
}

extension TVDetail {

    final class DetailViewModel: ObservableObject {
        let service: PlayerArchiveService
        @Published var archiveDoc: ArchiveMetaData? = nil
        @Published var audioFiles = [ArchiveFile]()
        @Published var movieFiles = [ArchiveFile]()
        @Published var playlistArchiveFiles: [ArchiveFile]?
        @Published var backgroundIconUrl: URL = URL(string: "http://archive.org")!
        @Published var uiImage: UIImage?

        var player: AVPlayer? = nil

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
                        self.movieFiles = desiredVideo(files:video)
                    }

                    if let art = doc.preferredAlbumArt {
                        //self.backgroundIconUrl = icon
                        TVDetail.backgroundPass.send(art)
                        //                        self.uiImage = await IAMediaUtils.getImage(url: art)
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
                player.play()
            }
        }

        public func stopPreview() {
            guard let player = self.player else { return }
            player.pause()
            self.player = nil
        }
    }

}
