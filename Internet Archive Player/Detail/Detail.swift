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
    @State private var playlistAddAlert = false
    @State private var navigationTitle = ""
    
    init(_ identifier: String) {
        self.identifier = identifier
    }
    
    var body: some View {
        VStack {
            ScrollView {
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
                        .background(GeometryReader {
                            Color.clear.preference(key: ViewOffsetKey.self,
                                                   value: $0.frame(in: .named("scroll")).origin.y)
                        })
                        .onPreferenceChange(ViewOffsetKey.self) { offset in
                            self.titleChange(offset: offset)
                        }

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
                }
                .padding(10)

                Divider()

                if let desc = self.viewModel.archiveDoc?.description {

                    VStack() {
                        Text(AttributedString(attString(desc: desc.joined(separator: ", "))))
                            .padding(10.0)
                            .onTapGesture {
                                withAnimation {
                                    self.descriptionExpanded.toggle()
                                }
                            }

                        Button(action: {
                            withAnimation {
                                self.descriptionExpanded.toggle()
                            }

                        }) {
                            Image(systemName: self.descriptionExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                                .tint(.fairyRed)
                        }
                        .frame(alignment: .center)
                    }
                    .padding(10)
                    .background(Color.fairyCream.cornerRadius(10.0).padding(10))
                    .frame(minWidth: 0, maxWidth:.infinity)
                    .frame(height: self.descriptionExpanded ? nil : 100)
                    .frame(alignment:.leading)


                }


                HStack() {
                    Text("Files")
                        .font(.subheadline)
                        .bold()

                    Spacer()
                    Button(action: {
                        playlistAddAlert = true
                    }) {
                        HStack(spacing: 1.0) {
                            Image(systemName: "plus")
                                .tint(.fairyRed)
                            Image(systemName: PlayerButtonType.list.rawValue)
                                .tint(.fairyRed)
                        }
                    }
                }
                .padding(10)

                Divider()

                LazyVStack(spacing:2.0) {
                    ForEach(self.viewModel.files, id: \.self) { file in
                        self.createFileView(file)
                            .padding(.leading, 5.0)
                            .padding(.trailing, 5.0)
                            .onTapGesture {
                                iaPlayer.playFile(file)
                            }
                        Divider()
                    }
                }
            }
            .coordinateSpace(name: "scroll")
            .padding(0)
            .navigationTitle(navigationTitle)
            .onAppear() {
                self.viewModel.getArchiveDoc(identifier: self.identifier)
                self.viewModel.setSubscribers(iaPlayer)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing:
                                    HStack {
                Button(action: {
                }) {
                    Image(systemName: "heart")
                        .tint(.fairyRed)
                }
            })
            .navigationBarColor(backgroundColor: UIColor(white: 1.0, alpha: 0.85), titleColor: .black)
            .alert("Add all files to Playlist?", isPresented: $playlistAddAlert) {
                Button("No", role: .cancel) { }
                Button("Yes") {
                    viewModel.addAllFilesToPlaylist(player: iaPlayer)
                }
            }
        }
    }
    
    private func titleChange(offset: CGFloat) {
        withAnimation(.linear(duration:1.0)) {
            navigationTitle = offset < 0 ? self.viewModel.archiveDoc?.archiveTitle ?? "" : ""
        }
    }
    
    func createFileView(_ archiveFile: ArchiveFile) -> FileView {
        FileView(archiveFile,
                 showDownloadButton: false,
                 backgroundColor: self.viewModel.playingFile?.url?.absoluteURL == archiveFile.url?.absoluteURL ? .fairyRed : .fairyRedAlpha,
                 textColor: self.viewModel.playingFile?.url?.absoluteURL == archiveFile.url?.absoluteURL ? .fairyCream : .white,
                 ellipsisAction: {
            iaPlayer.appendPlaylistItem(archiveFile)
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
                player.appendPlaylistItem(file)
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

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
