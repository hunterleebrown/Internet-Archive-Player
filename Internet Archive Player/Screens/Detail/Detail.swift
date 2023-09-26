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
    @StateObject private var viewModel = DetailViewModel()
    private var identifier: String
    @State private var descriptionExpanded = false
    @State private var playlistAddAllAlert = false
    @State private var isPresented = false

    @State var playlistErrorAlertShowing: Bool = false
    @State var favoritesErrorAlertShowing: Bool = false

    @State var otherPlaylistPresented = false

    @State var scrollOffset: CGFloat = CGFloat.zero
    @State var hideNavigationBar: Bool = false

    @State var backgroundBlur: Double = 0.0

    @State var backgroundURL: URL?
    static var backgroundPass = PassthroughSubject<URL, Never>()

    var detailCornerRadius: CGFloat = 5.0

    init(_ identifier: String, isPresented: Bool = false) {
        self.identifier = identifier
        self.isPresented = isPresented
    }

    var body: some View {
        ObservableScrollView(scrollOffset: $scrollOffset) {
            Spacer().frame(height: 300)
            VStack(alignment: .leading, spacing:5) {
                Text(self.viewModel.archiveDoc?.archiveTitle ?? "")
                    .font(.headline)
                    .bold()
                    .foregroundColor(Color(.black))
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .center)

                if let artist = self.viewModel.archiveDoc?.artist ?? self.viewModel.archiveDoc?.creator?.joined(separator: ", "), !artist.isEmpty {
                        Text(artist)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity, alignment: .center)

                }

                VStack(alignment: .center) {
                    HStack(spacing:20) {
                        if (self.viewModel.archiveDoc?.description) != nil {
                            Button {
                                descriptionExpanded = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.largeTitle)
                                    .tint(.fairyRed)
                                    .padding(10)
                            }
                        }
                        ShareLink(item: URL(string: "https://archive.org/details/\(identifier)")!) {
                            Image(systemName: "square.and.arrow.up.circle")
                                .font(.largeTitle)
                        }


                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .background(
                Color.white.opacity(0.5)
                //                Color(avgColor(viewModel) ?? .white).opacity(0.5)
            )
            .cornerRadius(detailCornerRadius)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()



            VStack(alignment: .center, spacing: 5.0) {

                if self.viewModel.audioFiles.isEmpty &&
                    self.viewModel.movieFiles.isEmpty {
                    VStack(alignment: .center) {
                        Text("No playable file for app")
                            .font(.body)
                            .padding(.top, 5)
                            .padding(.horizontal, 5)
                        Link("View on archive.org", destination: URL(string: "https://archive.org/details/\(identifier)")!)
                            .foregroundColor(.fairyRed)
                            .padding(.bottom, 5)
                            .padding(.horizontal, 5)
                    }
                    .background(
                        Color.white.opacity(0.5)
                    )
                    .cornerRadius(detailCornerRadius)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()

                } else {
                    HStack() {
                        Spacer()
                        Menu {
                            Button(action: {
                                viewModel.playlistArchiveFiles = viewModel.audioFiles + viewModel.movieFiles
                                otherPlaylistPresented = true
                            }){
                                HStack {
                                    Image(systemName: PlayerButtonType.list.rawValue)
                                    Text("Add all to list ...")
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
                            .padding(5)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: detailCornerRadius,
                                    style: .continuous
                                )
                                .fill(Color.white.opacity(0.5))
                            )
                        }
                        .highPriorityGesture(TapGesture())
                    }
                    .padding(10)

                }

                VStack(alignment: .leading) {

                    if self.viewModel.audioFiles.count > 0 {
                        Text("Audio")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.black)
                            .padding(5)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: detailCornerRadius,
                                    style: .continuous
                                )
                                .fill(Color.white.opacity(0.5))
                            )


                        ForEach(self.viewModel.sortedAudioFiles(), id: \.self) { file in
                            HStack(alignment: .center, spacing: 5) {
                                
                                Image(systemName: PlayerButtonType.ear.rawValue)
                                    .frame(width: 33, height: 33)
                                    .background(Color.fairyRedAlpha)
                                    .cornerRadius(10)
                                    .foregroundColor(.fairyCreamAlpha)
                                    .onTouchDownUp { pressed in
                                        if pressed {
                                            viewModel.previewAudio(file: file)
                                        } else {
                                            viewModel.stopPreview()
                                        }
                                    }

                                self.createFileView(file)
                                    .padding(.leading, 5.0)
                                    .padding(.trailing, 5.0)
                                    .onTapGesture {
                                        do  {
                                            try iaPlayer.checkDupes(archiveFile: file, list: iaPlayer.items, error: .alreadyOnPlaylist)
                                        } catch PlayerError.alreadyOnPlaylist {
                                            self.playlistErrorAlertShowing = true
                                            return
                                        } catch {}
                                        iaPlayer.playFile(file)
                                    }
                            }
                        }
                    }

                    if self.viewModel.movieFiles.count > 0 {
                        Text("Movies")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.black)
                            .padding(5)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: detailCornerRadius,
                                    style: .continuous
                                )
                                .fill(Color.white.opacity(0.5))
                            )

                        ForEach(self.viewModel.movieFiles, id: \.self) { file in
                            self.createFileView(file)
                                .padding(.leading, 5.0)
                                .padding(.trailing, 5.0)
                                .onTapGesture {
                                    do  {
                                        try iaPlayer.checkDupes(archiveFile: file, list: iaPlayer.items, error: PlayerError.alreadyOnPlaylist)
                                    } catch PlayerError.alreadyOnPlaylist {
                                        self.playlistErrorAlertShowing = true
                                        return
                                    } catch {}
                                    iaPlayer.playFile(file)
                                }
                        }
                    }
                }
                .padding(10)
            }
        }
        .onChange(of: scrollOffset) { scrollOfset, newScrollOffset in
            let offset = newScrollOffset + (self.hideNavigationBar ? 50 : 0) // note 1
            if offset > 25 {
                DispatchQueue.main.async {
                    withAnimation(.easeIn(duration: 1), {
                        self.hideNavigationBar = true
                        self.backgroundBlur = 10
                    })
                }
            }
            if offset < 75 {
                DispatchQueue.main.async {
                    withAnimation(.easeIn(duration: 1), {
                        self.hideNavigationBar = false
                        self.backgroundBlur = 0
                    })
                }
            }
        }
        .navigationBarHidden(hideNavigationBar)
        .background(
            ZStack (alignment: .top) {
                if let img = self.backgroundURL,
                   let avg = viewModel.uiImage,
                   let color = avg.averageColor {

                    Rectangle().fill(
                        Color(color)
                    )
                    .ignoresSafeArea()


                    AsyncImage(url: img, transaction: Transaction(animation: .spring())) { phase in
                        switch phase {
                        case .empty:
                            Color.clear

                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .overlay(Rectangle().fill(Color(color).opacity(0.5)), alignment: .topTrailing)
                                .blur(radius: backgroundBlur)

                        case .failure(_):
                            EmptyView()

                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(minHeight: 200, alignment: .center)
                }

            }
        )
        .listStyle(.plain)
        //        .navigationTitle("Archive")
        .toolbarBackground( Color.clear, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear() {
            self.viewModel.getArchiveDoc(identifier: self.identifier)
            self.viewModel.setSubscribers(iaPlayer)
            self.viewModel.passInPlayer(iaPlayer: iaPlayer)
        }
        .sheet(isPresented: $descriptionExpanded) {
            if let doc = self.viewModel.archiveDoc {
                DetailDescription(doc: doc)
            }
        }
        .sheet(isPresented: $otherPlaylistPresented) {
            if let files = viewModel.playlistArchiveFiles {
                OtherPlaylist(isPresented: $otherPlaylistPresented, archiveFiles: files)
            }
        }
        .alert(PlayerError.alreadyOnPlaylist.description, isPresented: $playlistErrorAlertShowing) {
            Button("Okay", role: .cancel) { }
        }
        .alert(PlayerError.alreadyOnFavorites.description, isPresented: $favoritesErrorAlertShowing) {
            Button("Okay", role: .cancel) { }
        }
        .onReceive(Detail.backgroundPass) { url in
            withAnimation(.linear(duration: 0.3)) {
                self.backgroundURL = url
            }
        }
        .opacity(self.backgroundURL != nil ? 1 : 0)
        .edgesIgnoringSafeArea(.top)
        .safeAreaInset(edge: .top, content: {
            Spacer()
                .frame(height: 20)
        })
        .safeAreaInset(edge: .bottom, content: {
            Spacer()
                .frame(height: iaPlayer.playerHeight)
        })
    }

    func complementaryColor(_ viewModel: DetailViewModel) -> UIColor? {
        guard let avg = viewModel.uiImage,
              let color = avg.averageColor else { return nil }

        return color.complement
    }

    func avgColor(_ viewModel: DetailViewModel) -> UIColor? {
        guard let avg = viewModel.uiImage else { return nil }
        return avg.averageColor
    }

    func createFileView(_ archiveFile: ArchiveFile) -> FileView {
        FileView(archiveFile,
                 showDownloadButton: false,
                 backgroundColor: self.viewModel.playingFile?.url?.absoluteURL == archiveFile.url?.absoluteURL ? .fairyRed : .fairyRedAlpha,
                 textColor: self.viewModel.playingFile?.url?.absoluteURL == archiveFile.url?.absoluteURL ? .fairyCream : .white,
                 ellipsisAction: self.menuActions(archiveFile: archiveFile) )
    }

    private func menuActions(archiveFile: ArchiveFile) -> [MenuAction] {
        var actions = [MenuAction]()

        let playlist = MenuAction(name: "Add to Now Playing", action:  {
            do  {
                try iaPlayer.appendPlaylistItem(archiveFile)
            } catch PlayerError.alreadyOnPlaylist {
                self.playlistErrorAlertShowing = true
            } catch {

            }
        }, imageName: "list.bullet.rectangle.portrait")

        let favorites = MenuAction(name: "Add to Favorites", action:  {
            do  {
                try iaPlayer.appendFavoriteItem(file: archiveFile)
            } catch PlayerError.alreadyOnFavorites {
                self.favoritesErrorAlertShowing = true
            } catch {

            }
        }, imageName: "heart")


        let otherPlaylist = MenuAction(name: "Add to list ...", action:  {
            viewModel.playlistArchiveFiles = [archiveFile]
            otherPlaylistPresented = true
        }, imageName: "music.note.list")

        actions.append(playlist)
        actions.append(favorites)
        actions.append(otherPlaylist)

        return actions
    }
}


struct Detail_Previews: PreviewProvider {
    static var previews: some View {
        Detail("wcd_ray-of-light_madonna_flac_lossless_522566", isPresented: false).environmentObject(Player())
        //        Detail("13BinarySunsetAlternate", isPresented: false).environmentObject(Player())
    }
}

