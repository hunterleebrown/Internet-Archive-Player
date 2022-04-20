//
//  Detail.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/24/22.
//

import SwiftUI
import iaAPI
import UIKit

struct Detail: View {
    @EnvironmentObject var iaPlayer: Player
    @StateObject var viewModel = Detail.ViewModel()
    private var identifier: String
    @State private var descriptionExpanded = false
    @State private var titleScrollOffset: CGFloat = .zero
    @State private var playlistAddAlert = false
    
    init(_ identifier: String) {
        self.identifier = identifier
    }
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .center, spacing: 5.0) {
                    if let iconUrl = viewModel.archiveDoc?.iconUrl {
                        AsyncImage(
                            url: iconUrl,
                            content: { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 200,
                                           maxHeight: 200)
                                    .background(Color.clear)
                            },
                            placeholder: {
                                ProgressView()
                            })
                        .cornerRadius(15)
                    }
                    Text(self.viewModel.archiveDoc?.archiveTitle ?? "")
                        .font(.headline)
                        .bold()
                        .multilineTextAlignment(.center)
                        .background(GeometryReader {
                            Color.clear.preference(key: ViewOffsetKey.self,
                                                   value: $0.frame(in: .named("scroll")).origin.y)
                        })
                        .onPreferenceChange(ViewOffsetKey.self) {
                            //                            print("offset >> \($0)")
                            titleScrollOffset = $0
                        }
                    
                    if let artist = self.viewModel.archiveDoc?.artist ?? self.viewModel.archiveDoc?.creator?.first {
                        Text(artist)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }
                    
                }
                .padding(10)
                
                if let desc = self.viewModel.archiveDoc?.description {
                    
                    VStack() {
                        Text(AttributedString(attString(desc: desc)))
                            .padding(5.0)
                            .onTapGesture {
                                withAnimation {
                                    self.descriptionExpanded.toggle()
                                }
                            }
                    }
                    .padding(10)
                    .background(Color.white)
                    .frame(height: self.descriptionExpanded ? nil : 100)
                    .frame(alignment:.leading)
                }
                
                
                LazyVStack(spacing:2.0) {
                    ForEach(self.viewModel.files, id: \.self) { file in
                        self.createFileView(file)
                            .padding(.leading, 5.0)
                            .padding(.trailing, 5.0)
                            .onTapGesture {
                                self.iaPlayer.appendPlaylistItem(file)
                                iaPlayer.playFile(file)
                            }
                    }
                }
            }
            .coordinateSpace(name: "scroll")
            .padding(0)
            .navigationTitle(titleScrollOffset < 0 ? viewModel.archiveDoc?.archiveTitle ?? "" : "")
            .onAppear() {
                self.viewModel.getArchiveDoc(identifier: self.identifier)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                HStack {
                    Button(action: {
                        playlistAddAlert = true
                    }) {
                        HStack(spacing: 1.0) {
                            Text("-->")
                            Image(systemName: PlayerButtonType.list.rawValue)
                                .tint(.fairyRed)
                        }
                    }
                    
                    Button(action: {
                    }) {
                        Image(systemName: "heart")
                            .tint(.fairyRed)
                    }
                }
                
            }
        }
        .navigationBarColor(backgroundColor: UIColor(white: 1.0, alpha: 0.85), titleColor: .black)
        .alert("Add all files to Playlist?", isPresented: $playlistAddAlert) {
            Button("No", role: .cancel) { }
            Button("Yes") {
                viewModel.addAllFilesToPlaylist(player: iaPlayer)
            }
        }
        
    }
    
    func createFileView(_ archiveFile: ArchiveFile) -> FileView? {
        return FileView(archiveFile, showDownloadButton: false, ellipsisAction: {
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
        let service: ArchiveService
        @Published var archiveDoc: ArchiveMetaData? = nil
        @Published var files = [ArchiveFile]()
        
        init() {
            self.service = ArchiveService()
        }
        
        public func getArchiveDoc(identifier: String){
            Task { @MainActor in
                do {
                    let doc = try await self.service.getArchiveAsync(with: identifier)
                    
                    withAnimation {
                        self.archiveDoc = doc.metadata
                        self.files = doc.non78Audio.sorted{
                            guard let track1 = $0.track, let track2 = $1.track else { return false}
                            return track1 < track2
                        }
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
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
