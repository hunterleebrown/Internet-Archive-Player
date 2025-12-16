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
            VStack(alignment: .leading, spacing:10) {
                HStack(alignment: .center, spacing: 50) {

                    VStack(alignment: .leading) {
                        Text(doc.archiveTitle ?? "")
                            .font(.largeTitle)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .frame(alignment: .leading)

                        if let artist = self.viewModel.archiveDoc?.artist ?? self.viewModel.archiveDoc?.creator?.joined(separator: ", "), !artist.isEmpty {
                            Text(artist)
                                .font(.caption)
                                .lineLimit(10)
                                .multilineTextAlignment(.leading)
                                .frame(alignment: .leading)
                        }
                    }
                    .padding(30)
                    .shadow(radius: 10)
//                    .background(Color.black)
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(alignment: .top, spacing: 100) {
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
                    .frame(width:800, alignment: .leading)

                    VStack(alignment: .leading) {

                        if (self.viewModel.archiveDoc?.description) != nil {
                            NavigationLink {
                                if let goodDoc = viewModel.archiveDoc {
                                    DetailDescription(doc: goodDoc)
                                }
                            } label: {
                                Text("Description")
                            }
                        }

                        Divider()

                        if self.viewModel.movieFiles.count > 0 {
                            Text("Files")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.white)
                                .padding(5)

                            List {
                                ForEach(self.viewModel.movieFiles, id: \.self) { file in

                                    NavigationLink {
                                        let player = AVPlayer(url: file.url!)

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
                                            .foregroundStyle(Color.fairyCream)

                                    }
                                    .listRowBackground(Color.fairyRed)

                                }
                            }
                            .cornerRadius(10)
                        }
                    }
                }
                .frame(height: 500)

                if let identifier = doc.identifier {
                    HStack(alignment: .top, spacing: 5) {
                        Text("Identifier:")
                            .font(.caption)
                            .bold()
                        Text(identifier)
                            .font(.caption)
                    }
                }

                if let publisher = doc.publisher, !publisher.isEmpty {
                    HStack(alignment: .top, spacing: 5) {
                        Text("Publisher:")
                            .font(.caption)
                            .bold()
                        Text(publisher.joined(separator: ", "))
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                    }
                }

                HStack(alignment: .top, spacing: 5) {
                    Text("Collection:")
                        .font(.caption)
                        .bold()
                    Text(doc.collection.joined(separator: ", "))
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .background(
//                LinearGradient(
//                    gradient: Gradient(
//                        stops: [
//                            .init(color: .fairyRed, location: 0),
//                            .init(color: .fairyRed.opacity(0.75), location: 0.33),
//                            .init(color: .fairyRed.opacity(0.5), location: 0.66),
//                            .init(color: .fairyRed.opacity(0.25), location: 1),
//                        ]
//                    ),
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .edgesIgnoringSafeArea(.all)

            )
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
