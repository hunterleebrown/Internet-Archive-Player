//
//  FileView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 2/10/22.
//

import Foundation
import SwiftUI
import iaAPI
import Combine

struct EntityFileCardView: View {

    @StateObject var viewModel: EntityFileCardView.ViewModel = EntityFileCardView.ViewModel()

    var archiveFile: ArchiveFileEntity
    var textColor = Color.white
    var backgroundColor: Color? = Color.gray
    var showImage: Bool = false
    @State var showDownloadButton = true
    var fileViewMode: FileViewMode = .detail
    var ellipsisAction: [MenuAction] = [MenuAction]()

    @State var backgroundURL: URL?
    static var backgroundPass = PassthroughSubject<URL, Never>()

    init(_ archiveFile: ArchiveFileEntity,
         showImage: Bool = false,
         backgroundColor: Color? = Color.fairyRedAlpha,
         textColor: Color = Color.fairyCream,
         fileViewMode: FileViewMode = .detail,
         ellipsisAction: [MenuAction] = [MenuAction]()) {

        self.archiveFile = archiveFile
        self.showImage = showImage
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.ellipsisAction = ellipsisAction
        self.fileViewMode = fileViewMode
    }
    
    var body: some View {
        
        HStack() {
            VStack(alignment: .leading, spacing: 0) {
                Text(archiveFile.displayTitle)
                    .bold()
                    .font(.caption)
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)

                if fileViewMode == .playlist {
                    Text(archiveFile.archiveTitle ?? "")
                        .font(.caption2)
                        .foregroundColor(textColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }

                HStack(alignment: .center, spacing: 5) {

                    Image(systemName: archiveFile.isVideo ? "video" : "hifispeaker")
                        .tint(.black)
                        .font(.caption2)

                    Text("· \(archiveFile.calculatedSize ?? "\"\"") mb")
                        .font(.caption2)
                        .foregroundColor(textColor)
                        .bold()
                    Text("· \(archiveFile.displayLength ?? "")")
                        .font(.caption2)
                        .foregroundColor(textColor)
                        .bold()
                    Image(systemName: showDownloadButton ? "cloud" : "iphone")
                        .font(.caption2)
                    Text(showDownloadButton ? "online" : "downloaded")
                        .font(.caption2)
                        .foregroundColor(textColor)
                }



                if viewModel.downloadProgress > 0 &&
                    viewModel.downloadProgress < 1 &&
                    !archiveFile.isLocalFile() {
                    ProgressView("Downloading", value: viewModel.downloadProgress, total:1)
                        .tint(.fairyRed)
                        .font(.caption2)
                }
            }
            .padding(5.0)
            Spacer()
            HStack() {

                    Menu {

                        ForEach(self.ellipsisAction, id: \.self) { menuItem in
                            Button(action: {
                                menuItem.action()
                            }){
                                HStack {
                                    if let imageName = menuItem.imageName {
                                        Image(systemName: imageName)
                                            .aspectRatio(contentMode: .fill)
                                            .foregroundColor(textColor)
                                    }
                                    Text(menuItem.name)
                                }
                            }
                            .frame(width: 44, height: 44)

                        }

                        if (showDownloadButton && archiveFile.format == "VBR MP3") {
                            Button(action: {
                                archiveFile.download(delegate: viewModel)
                            }) {
                                Image(systemName: "icloud.and.arrow.down")
                                    .aspectRatio(contentMode: .fill)
                                    .foregroundColor(textColor)
                                Text("Download")
                            }
                            .frame(width: 44, height: 44)
                        }


                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(textColor)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                    }
                    .highPriorityGesture(TapGesture())
            }
            .tint(textColor)
            .padding(5.0)
        }
        .background(
//            Color(uiColor:viewModel.uiImage?.averageColor ?? .black)

            AsyncImage(url: archiveFile.iconUrl, transaction: Transaction(animation: .spring())) { phase in
                switch phase {
                case .empty:
                    Color.clear

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 66, alignment: .top)


                case .failure(_):
                    EmptyView()

                @unknown default:
                    EmptyView()
                }
            }


        )
        .onReceive(EntityFileCardView.backgroundPass) { url in
            withAnimation(.linear(duration: 0.3)) {
                self.backgroundURL = url
            }
        }
        .cornerRadius(5.0)
        .onReceive(Downloader.downloadedSubject) { file in
            guard file.id == archiveFile.id else { return }
            showDownloadButton = false
        }
        .onAppear() {
            showDownloadButton = !archiveFile.isLocalFile()
            viewModel.loadImage(file: archiveFile)
        }
    }

}

struct EntityFileCardView_Previews: PreviewProvider {
    static var previews: some View {
        if let file = ArchiveFileEntity.firstEntity(context: PersistenceController.shared.container.viewContext) as? ArchiveFileEntity {
                EntityFileCardView(file, showImage: true)
        }
    }
}

extension EntityFileCardView {
    public class ViewModel: ObservableObject, FileViewDownloadDelegate {
        @Published var downloadProgress = 0.0
        @Published var uiImage: UIImage?

        public func loadImage(file: ArchiveFileEntity) {
            Task { @MainActor in
                if let icon = file.iconUrl {
                    EntityFileCardView.backgroundPass.send(icon)
                    self.uiImage = await IAMediaUtils.getImage(url: icon)
                }

            }
        }
    }
}
