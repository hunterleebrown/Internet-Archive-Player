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
    var identifier: String
    @State var descriptionExpanded = false
    
    init(_ identifier: String) {
        self.identifier = identifier
        self.viewModel = Detail.ViewModel(identifier)
    }
    
    var body: some View {
        VStack(alignment: .leading){
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
            .padding(0)
        }
        .navigationBarTitleDisplayMode(.inline)
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


//struct Detail_Previews: PreviewProvider {
//    static var previews: some View {
//        Detail(nil)
//    }
//}

extension Detail {
    @MainActor final class ViewModel: ObservableObject {
        let service: ArchiveService
        let identifier: String
        @Published var archiveDoc: ArchiveMetaData? = nil
        @Published var files = [ArchiveFile]()

        init(_ identifier: String) {
            self.service = ArchiveService()
            self.identifier = identifier
            self.getArchiveDoc()
        }
        
        public func getArchiveDoc(){
            Task {
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
    }
}
