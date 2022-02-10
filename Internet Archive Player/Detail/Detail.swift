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
    @ObservedObject var viewModel: Detail.ViewModel
    var doc: IASearchDoc?
    @State var descriptionExpanded = false

    @Inject var iaPlayer: IAPlayer

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
                    //                        let html = "<div style='color:#ffffff; font-family: Arial, Helvetica, sans-serif;'>\(desc)</html>";
                    if let data = desc.data(using: .unicode),
                       let nsAttrString = try? NSAttributedString(
                        data: data,
                        options: [
                            .documentType: NSAttributedString.DocumentType.html,
                        ],
                        documentAttributes: nil) {
                        VStack() {
                            Text(AttributedString(nsAttrString))
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
                }

                LazyVStack(spacing:5.0) {
                    ForEach(self.viewModel.files, id: \.self) { file in
                        FileView(file)
                            .padding(.leading, 5.0)
                            .padding(.trailing, 5.0)
                            .onTapGesture {
                                if let archiveDoc = self.viewModel.archiveDoc {
                                    iaPlayer.playFile(file: file, doc: archiveDoc)
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



}

struct FileView: View {

    var iaFile: IAFile?
    init(_ file: IAFile){
        iaFile = file
    }

    var textColor = Color.droopy

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5.0)
                .fill(Color.white)
                .background(Color.white)
                .shadow(color: Color.droopy, radius: 2, x: 0, y: 2)

            HStack() {
                VStack() {
                    let title = fileTitle(iaFile)

                    if let name = iaFile?.name {
                        if title != name {
                            Text(title)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(textColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                        } else {
                            Text(title)
                                .font(.caption2)
                                .foregroundColor(textColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                        }
                    }


                    if let name = iaFile?.name {
                        if title != name {
                            Text(iaFile?.name ?? "")
                                .font(.caption2)
                                .foregroundColor(textColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(5.0)
                Spacer()
                HStack() {
                    VStack(alignment:.leading) {
                        Text("\(iaFile?.calculatedSize ?? "\"\"") mb")
                            .font(.caption2)
                            .foregroundColor(textColor)
                        Text(iaFile?.displayLength ?? "")
                            .font(.caption2)
                            .foregroundColor(textColor)
                    }

                    Button(action: {

                    }) {
                        Image(systemName: "icloud.and.arrow.down")
                            .accentColor(textColor)
                            .aspectRatio(contentMode: .fill)
                    }
                    .frame(width: 44, height: 44)

                    Button(action: {

                    }) {
                        Image(systemName: "ellipsis")
                            .accentColor(textColor)
                            .aspectRatio(contentMode: .fill)
                    }
                    .frame(width: 44, height: 44)
                }
                //            .frame(width:100)
                .padding(5.0)
            }
        }


        //        .background(Color.droopy)
        //        .cornerRadius(5.0)
        //        .overlay(
        //            Rectangle()
        //                .foregroundColor(Color.white)
        //        )
    }

    private func fileTitle(_ iaFile: IAFile?) -> String {
        return iaFile?.displayName ?? iaFile?.title ?? iaFile?.name ?? ""
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

extension IAFile: Hashable {
    public static func == (lhs: IAFile, rhs: IAFile) -> Bool {
        return lhs.name == rhs.name &&
        lhs.title == rhs.title &&
        lhs.format == rhs.format &&
        lhs.track == rhs.track
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(track)
        hasher.combine(name)
        hasher.combine(format)
    }
}
