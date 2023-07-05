//
//  Detail.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/24/22.
//

import SwiftUI
import iaAPI
import UIKit
import Combine

struct Detail: View {
    @EnvironmentObject var iaPlayer: Player
    @StateObject var viewModel = Detail.ViewModel()
    private var identifier: String
    @State private var descriptionExpanded = false
    @State private var titleScrollOffset: CGFloat = .zero
    @State private var playlistAddAllAlert = false
    @State private var isPresented = false

    @State var playlistErrorAlertShowing: Bool = false

    init(_ identifier: String, isPresented: Bool = false) {
        self.identifier = identifier
        self.isPresented = isPresented
    }
    
    var body: some View {
        List {
            VStack(alignment: .center, spacing: 5.0) {
                if let iconUrl = viewModel.archiveDoc?.iconUrl {
                    AsyncImage (
                        url: iconUrl,
                        content: { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(minWidth:180, maxWidth: 180,
                                       minHeight: 180, maxHeight: 180)
                                .background(Color.black)
                        },
                        placeholder: {
                            Color.black
                        })
                    .cornerRadius(15)
                }

                Text(self.viewModel.archiveDoc?.archiveTitle ?? "")
                    .font(.headline)
                    .bold()
//                    .multilineTextAlignment(.center)

                if let artist = self.viewModel.archiveDoc?.artist ?? self.viewModel.archiveDoc?.creator?.joined(separator: ", ") {
                    Text(artist)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }

                if let publisher = self.viewModel.archiveDoc?.publisher {
                    Text(publisher.joined(separator: ", "))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }

                if let desc = self.viewModel.archiveDoc?.descriptionHtml {
                    Text(AttributedString(desc))
                        .padding(10.0)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(5)
                }

                HStack() {
                    Text("Files")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.fairyRed)
                    Spacer()

                    Menu {
                        Button(action: {
                            viewModel.addAllFilesToPlaylist(player: iaPlayer)
                        }){
                            HStack {
                                Image(systemName: PlayerButtonType.list.rawValue)
                                Text("Add all to playlist")
                            }
                        }
                        .frame(width: 44, height: 44)
                    } label: {
                        HStack(spacing: 1.0) {
                            Image(systemName: "plus")
                                .tint(.fairyRed)
                            Image(systemName: PlayerButtonType.list.rawValue)
                                .tint(.fairyRed)
                        }
                    }
                    .highPriorityGesture(TapGesture())
                }
                .padding(10)

                LazyVStack(alignment: .leading) {
                    if self.viewModel.audioFiles.count > 0 {
                        Text("Audio")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.fairyRed)
                            .padding(.horizontal, 10)

                        ForEach(self.viewModel.sortedAudioFiles(), id: \.self) { file in
                            self.createFileView(file)
                                .padding(.leading, 5.0)
                                .padding(.trailing, 5.0)
                                .onTapGesture {
                                    do  {
                                        try iaPlayer.checkDupes(archiveFile: file)
                                    } catch PlayerError.alreadyOnPlaylist {
                                        self.playlistErrorAlertShowing = true
                                        return
                                    } catch {}
                                    iaPlayer.playFile(file)
                                }
                        }
                    }

                    if self.viewModel.movieFiles.count > 0 {
                        Text("Movies")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.fairyRed)
                            .padding(.horizontal, 10)

                        ForEach(self.viewModel.movieFiles, id: \.self) { file in
                            self.createFileView(file)
                                .padding(.leading, 5.0)
                                .padding(.trailing, 5.0)
                                .onTapGesture {
                                    do  {
                                        try iaPlayer.checkDupes(archiveFile: file)
                                    } catch PlayerError.alreadyOnPlaylist {
                                        self.playlistErrorAlertShowing = true
                                        return
                                    } catch {}
                                    iaPlayer.playFile(file)
                                }
                        }
                    }
                }

            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowSeparator(.hidden)
            .padding(10)
        }
        .listStyle(PlainListStyle())
        .navigationTitle("Archive")
        .onAppear() {
            self.viewModel.getArchiveDoc(identifier: self.identifier)
            self.viewModel.setSubscribers(iaPlayer)
        }
        .navigationBarItems(trailing:
                                Button(action: {
        }) {
            Image(systemName: "heart")
                .tint(.fairyRed)
        })
//        .navigationBarColor(backgroundColor: UIColor(white: 1.0, alpha: 0.5), titleColor: .fairyRed)
//        .alert("Add all files to Playlist?", isPresented: $playlistAddAllAlert) {
//            Button("No", role: .cancel) { }
//            Button("Yes") {
//                viewModel.addAllFilesToPlaylist(player: iaPlayer)
//            }
//        }
        .alert(PlayerError.alreadyOnPlaylist.description, isPresented: $playlistErrorAlertShowing) {
            Button("Okay", role: .cancel) { }
        }
    }

    func createFileView(_ archiveFile: ArchiveFile) -> FileView {
        FileView(archiveFile,
                 showDownloadButton: false,
                 backgroundColor: self.viewModel.playingFile?.url?.absoluteURL == archiveFile.url?.absoluteURL ? .fairyRed : .fairyRedAlpha,
                 textColor: self.viewModel.playingFile?.url?.absoluteURL == archiveFile.url?.absoluteURL ? .fairyCream : .white,
                 ellipsisAction: {
            do  {
                try iaPlayer.appendPlaylistItem(archiveFile)
            } catch PlayerError.alreadyOnPlaylist {
                self.playlistErrorAlertShowing = true
            } catch {
                
            }
        })
    }
}


struct Detail_Previews: PreviewProvider {
    static var previews: some View {
        Detail("hunterleebrown-lovesongs")
    }
}

extension Detail {
    final class ViewModel: ObservableObject {
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
}
