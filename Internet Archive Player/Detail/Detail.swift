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
                    .foregroundColor(.black)
                    .bold()
                    .multilineTextAlignment(.center)
                if let artist = self.viewModel.archiveDoc?.artist ?? self.viewModel.archiveDoc?.creator?.joined(separator: ", ") {
                    Text(artist)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)

                }

                if let publisher = self.viewModel.archiveDoc?.publisher {
                    Text(publisher.joined(separator: ", "))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                }

                if let desc = self.viewModel.archiveDoc?.description {
                    Text(AttributedString(attString(desc: desc.joined(separator: ", "))))
                        .padding(10.0)
                        .frame(maxWidth: .infinity)
                }

                HStack() {
                    Text("Files")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.fairyRed)
                    Spacer()
                    Button(action: {
                        playlistAddAllAlert = true
                    }) {
                        HStack(spacing: 1.0) {
                            Image(systemName: "plus")
                                .tint(.fairyRed)
                            Image(systemName: PlayerButtonType.list.rawValue)
                                .tint(.fairyRed)
                        }
                    }
                    .tint(.fairyRed)
                }
                .padding(10)

                ForEach(self.viewModel.files, id: \.self) { file in
                    self.createFileView(file)
                        .padding(.leading, 5.0)
                        .padding(.trailing, 5.0)
                        .onTapGesture {
                            iaPlayer.playFile(file)
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
        .navigationBarColor(backgroundColor: UIColor(white: 1.0, alpha: 0.5), titleColor: .fairyRed)
        .alert("Add all files to Playlist?", isPresented: $playlistAddAllAlert) {
            Button("No", role: .cancel) { }
            Button("Yes") {
                viewModel.addAllFilesToPlaylist(player: iaPlayer)
            }
        }
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
//                self.playlistErrorAlertShowing = true
            } catch {
                
            }
        })
    }
    
    func attString(desc: String) -> NSAttributedString {
        if let data = desc.data(using: .unicode) {
            return try! NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                ],
                documentAttributes: nil)
        }
        return NSAttributedString()
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
        @Published var files = [ArchiveFile]()
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
                    self.files = doc.non78Audio.sorted{
                        guard let track1 = $0.track, let track2 = $1.track else { return false}
                        return track1 < track2
                    }
                    
                } catch {
                    print(error)
                }
            }
        }
        
        public func addAllFilesToPlaylist(player: Player) {
            files.forEach { file in
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
    }
}
