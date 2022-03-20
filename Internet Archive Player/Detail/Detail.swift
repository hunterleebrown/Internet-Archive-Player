//
//  Detail.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/24/22.
//

import SwiftUI
import iaAPI

struct Detail: View {
    @EnvironmentObject var iaPlayer: IAPlayer
    @ObservedObject var viewModel: Detail.ViewModel
    var identifier: String?
    @State var descriptionExpanded = false
    
    init(_ identifier: String?) {
        self.identifier = identifier
        self.viewModel = Detail.ViewModel(identifier)
        //        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.fairyCream]
    }
    
    var body: some View {
        VStack(alignment: .leading){
            ScrollView {
                VStack(alignment: .center, spacing: 5.0) {
                    if let iconUrl = viewModel.archiveDoc?.iconUrl() {
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
                }

                
                LazyVStack(spacing:2.0) {
                    ForEach(self.viewModel.files, id: \.self) { file in

                        if let archiveDoc = self.viewModel.archiveDoc {
                            let appPlaylistItem = PlaylistItem(file, archiveDoc)
                            self.createFileView(appPlaylistItem)
                                .padding(.leading, 5.0)
                                .padding(.trailing, 5.0)
                                .onTapGesture {
                                    self.iaPlayer.appendPlaylistItem(appPlaylistItem)
                                    iaPlayer.playFile(appPlaylistItem)
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

    /**
     Filter out the annoying 78rpm collection files with "_78_" tracks
     */
    func createFileView(_ playlistItem: PlaylistItem) -> FileView? {

        if let name = playlistItem.file.name, let count = playlistItem.archiveDoc.files?.count {
            if count > 1 && playlistItem.archiveDoc.metadata.collection.contains("78rpm") && name.contains("78_") {
                return nil
            }
        }

        return FileView(playlistItem, showDownloadButton: false, ellipsisAction: {
            iaPlayer.appendPlaylistItem(playlistItem)
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
        Detail(nil)
    }
}

extension Detail {
    final class ViewModel: ObservableObject {
        let service: IAService
        let identifier: String?
        @Published var archiveDoc: IAArchiveDoc? = nil
        @Published var files = [IAFile]()
        
        init(_ identifier: String?) {
            self.service = IAService()
            self.identifier = identifier
            self.getArchiveDoc()
        }
        
        private func getArchiveDoc(){
            guard let identifier = identifier else { return }
            
//            self.service.archiveDoc(identifier: identifier) { result, error in
//                self.archiveDoc = result
//                guard let files = self.archiveDoc?.files else { return }
//
//                files.forEach { f in
//                    guard f.format == .mp3 else { return }
//                    self.files.append(f)
//                }
//            }
            self.service.mockArchiveDoc() { result, error in
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
