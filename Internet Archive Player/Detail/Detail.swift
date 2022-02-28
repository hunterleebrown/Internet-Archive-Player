//
//  Detail.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/24/22.
//

import SwiftUI
import iaAPI

struct Detail: View {
    @EnvironmentObject var playlistViewModel: Playlist.ViewModel
    @EnvironmentObject var iaPlayer: IAPlayer
    
    @ObservedObject var viewModel: Detail.ViewModel
    var doc: IASearchDoc?
    @State var descriptionExpanded = false
    
    init(_ doc: IASearchDoc?) {
        self.doc = doc
        self.viewModel = Detail.ViewModel(doc)
        //        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.fairyCream]
    }
    
    var body: some View {
        VStack(alignment: .leading){
            ScrollView {
                VStack(alignment: .center, spacing: 5.0) {
                    if let iconUrl = doc?.iconUrl {
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
                    Text(self.viewModel.archiveDoc?.title ?? "")
                        .font(.headline)
                        .bold()
                        .multilineTextAlignment(.center)
                    if let artist = self.viewModel.archiveDoc?.artist ?? self.viewModel.archiveDoc?.creator {
                        Text(artist)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }
                    
                }
                .padding(10)
                
                if let desc = self.viewModel.archiveDoc?.desc {

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
                    //                        .overlay(
                    //                            RoundedRectangle(cornerRadius: 5.0)
                    //                                .stroke(Color.gray, lineWidth: 1.0)
                    //                        )
                    //                        .shadow(color: Color.droopy, radius: 5, x: 0, y: 5)
                }

                
                LazyVStack(spacing:5.0) {
                    ForEach(self.viewModel.files, id: \.self) { file in
                        let playlistFile = PlaylistFile(file.copy())
                        FileView(playlistFile, ellipsisAction: {
                            if let archiveDoc = self.viewModel.archiveDoc?.copy() {
                                let vmFile = PlaylistFile(file.copy())
                                let playlistItem = PlaylistItem(vmFile, archiveDoc)
                                self.playlistViewModel.items.append(playlistItem)
                            }
                        })
                            .padding(.leading, 5.0)
                            .padding(.trailing, 5.0)
                            .onTapGesture {
                                if let archiveDoc = self.viewModel.archiveDoc?.copy() {
                                    let appVmFile = PlaylistFile(file.copy())
                                    let appPlaylistItem = PlaylistItem(appVmFile, archiveDoc)
                                    self.playlistViewModel.items.append(appPlaylistItem)
                                    iaPlayer.playFile(appPlaylistItem, playlistViewModel.items)
                                }
                            }
                    }
                }
            }
            .padding(0)
        }
        //        .modifier(BackgroundColorModifier(backgroundColor: Color.droopy))
        //        .navigationTitle(doc?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
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
        Detail(nil)
    }
}

extension Detail {
    final class ViewModel: ObservableObject {
        let service: IAService
        let searchDoc: IASearchDoc?
        @Published var archiveDoc: IAArchiveDoc? = nil
        @Published var files = [IAFile]()
        
        init(_ doc: IASearchDoc?) {
            self.service = IAService()
            self.searchDoc = doc
            self.getArchiveDoc()
        }
        
        private func getArchiveDoc(){
            guard let searchDoc = self.searchDoc,
                  let identifier = searchDoc.identifier else { return }
            
            self.service.archiveDoc(identifier: identifier) { result, error in
                self.archiveDoc = result
                guard let files = self.archiveDoc?.files else { return }
                
                files.forEach { f in
                    guard f.format == .mp3 else { return }
                    self.files.append(f)
                }
            }
        }
    }
}
