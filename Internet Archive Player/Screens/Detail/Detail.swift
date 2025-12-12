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
    @Environment(\.dismiss) private var dismiss
    private var identifier: String
    @State private var descriptionExpanded = false
    @State private var playlistAddAllAlert = false
    @State private var isPresented = false

    @State var playlistErrorAlertShowing: Bool = false
    @State var favoritesErrorAlertShowing: Bool = false
    @State var favoriteArchivesErrorAlertShowing: Bool = false

    @State var otherPlaylistPresented = false

    @State var scrollOffset: CGFloat = CGFloat.zero
    @State var hideNavigationBar: Bool = false

    @State var backgroundBlur: Double = 0.0
    @State var isLoading = true

    @State var backgroundURL: URL?
    static var backgroundPass = PassthroughSubject<URL, Never>()

    var detailCornerRadius: CGFloat = 5.0

    init(_ identifier: String, isPresented: Bool = false) {
        self.identifier = identifier
        self.isPresented = isPresented
    }

    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.fairyRed)
                    Text("Loading archive details...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else {
                mainContentView
            }
        }
        .navigationBarHidden(hideNavigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationDestination(item: $viewModel.createdPlaylist) { playlist in
            SingleListView(playlistEntity: playlist)
        }
        .task {
            viewModel.setSubscribers(iaPlayer)
            viewModel.passInPlayer(iaPlayer: iaPlayer)
            viewModel.checkFavoriteStatus(identifier: identifier)
            await viewModel.getArchiveDoc(identifier: identifier)
            isLoading = false
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
        .alert(PlayerError.alreadyOnFavoriteArchives.description, isPresented: $favoriteArchivesErrorAlertShowing) {
            Button("Okay", role: .cancel) { }
        }
        .onReceive(Detail.backgroundPass) { url in
            withAnimation(.linear(duration: 0.3)) {
                self.backgroundURL = url
            }
        }
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
    
    private var mainContentView: some View {
        ZStack {
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
                    HStack(spacing: 0) {
                        if (self.viewModel.archiveDoc?.description) != nil {
                            Button {
                                descriptionExpanded = true
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "info.circle")
                                        .font(.title2)
                                        .tint(.black)
                                    Text("Description")
                                        .font(.caption2)
                                        .foregroundColor(.black)
                                }
                                .frame(width: 80)
                                .padding(.vertical, 12)
                            }
                            
                            Divider()
                                .frame(height: 44)
                        }
                        
                        Button {
                            if viewModel.toggleFavoriteArchive(identifier: identifier) != nil {
                                favoriteArchivesErrorAlertShowing = true
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: viewModel.isFavoriteArchive ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .tint(.black)
                                Text("Bookmark")
                                    .font(.caption2)
                                    .foregroundColor(.black)
                            }
                            .frame(width: 80)
                            .padding(.vertical, 12)
                        }
                        
                        Divider()
                            .frame(height: 44)
                        
                        ShareLink(item: URL(string: "https://archive.org/details/\(identifier)")!) {
                            VStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up.circle")
                                    .font(.title2)
                                    .tint(.black)
                                Text("Share")
                                    .font(.caption2)
                                    .foregroundColor(.black)
                            }
                            .frame(width: 80)
                            .padding(.vertical, 12)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(detailCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: detailCornerRadius)
                            .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                    )
                }
            }
            .background(
                Color.white.opacity(0.5)
//                Color(avgColor(viewModel) ?? .white).opacity(0.5)
            )
//            .cornerRadius(detailCornerRadius)
            .frame(maxWidth: .infinity, alignment: .leading)
//            .padding()



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

                }

                VStack(alignment: .leading) {

                    if self.viewModel.audioFiles.count > 0 {
                        VStack(alignment: .center, spacing: 8) {
                            HStack {
                                Text("Audio")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.black)

                                Spacer()

                                Button {
                                    viewModel.playAllAudio()
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: "play.circle")
                                            .resizable()
                                            .font(.title2)
                                            .frame(width:44, height: 44)
                                        Text("Play all")
                                            .font(.caption2)
                                            .foregroundColor(.black)
                                    }
                                    .frame(width: 80)
                                    .padding(.vertical, 12)
                                }

                                Spacer()

                                Menu {
                                    Button(action: {
                                        viewModel.playlistArchiveFiles = viewModel.audioFiles + viewModel.movieFiles
                                        otherPlaylistPresented = true
                                    }){
                                        HStack {
                                            Image(systemName: PlayerButtonType.list.rawValue)
                                            Text("Add all to a playlist ...")
                                        }
                                    }
                                    .frame(width: 44, height: 44)
                                } label: {
                                    HStack(spacing: 1.0) {
                                        Image(systemName: "plus")
                                        Image(systemName: PlayerButtonType.list.rawValue)
                                    }
                                    .padding(5)
                                }
                                .highPriorityGesture(TapGesture())


                            }
                            .tint(Color.black)

                            Text("Tapping a track individually will play it and add it to the Now Playing list.  Play all creates a new playlist with all tracks, and starts playing the first one.")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal, 8)
                                .padding(.bottom, 8)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(
                                cornerRadius: detailCornerRadius,
                                style: .continuous
                            )
                            .fill(Color.white.opacity(0.5))
                        )


                        ForEach(Array(self.viewModel.sortedAudioFilesCache.enumerated()), id: \.element.name) { index, file in
                            HStack(alignment: .center, spacing: 5) {
                                
                                Image(systemName: PlayerButtonType.ear.rawValue)
                                    .frame(width: 33, height: 33)
                                    .background(viewModel.pressedStates[index] == true ? Color.fairyCreamAlpha : Color.fairyRedAlpha)
                                    .cornerRadius(10)
                                    .foregroundColor(viewModel.pressedStates[index] == true ? Color.fairyRedAlpha : Color.fairyCreamAlpha)
                                    .onTouchDownUp { pressed in
                                        viewModel.pressedStates[index] = pressed
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
                    withAnimation(.easeIn(duration: 1)) {
                        self.hideNavigationBar = true
                        self.backgroundBlur = 10
                    }
                }
                if offset < 75 {
                    withAnimation(.easeIn(duration: 1)) {
                        self.hideNavigationBar = false
                        self.backgroundBlur = 0
                    }
                }
            }
            .background(

            VStack(spacing: 0) {
                if let img = self.backgroundURL,
                   let color = viewModel.averageColor {

                    ZStack(alignment: .top) {

                        Color(color)

                        AsyncImage(url: img, transaction: Transaction(animation: .spring())) { phase in
                            switch phase {
                            case .empty:
                                Color.clear

                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .transition(.opacity) // Apply the transition

//                                    .ignoresSafeArea()
//                                    .overlay(Rectangle().fill(Color(color).opacity(0.5)), alignment: .topTrailing)
                                    .blur(radius: backgroundBlur)
                                    .clipped()

                            case .failure(_):
                                EmptyView()

                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(minHeight: 200, alignment: .center)
                    }


                    if let gradient = viewModel.gradient {
                        LinearGradient(
                            gradient: gradient,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea() // Makes the gradient cover the entire screen
                    } else {
                        Color(color)
                    }

                }

            }
        )
        .listStyle(.plain)
        }
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

        let playlist = MenuAction(name: "Add file to Now Playing", action:  {
            do  {
                try iaPlayer.appendPlaylistItem(archiveFile)
            } catch PlayerError.alreadyOnPlaylist {
                self.playlistErrorAlertShowing = true
            } catch {

            }
        }, imageName: "list.bullet.rectangle.portrait")

        let favorites = MenuAction(name: "Add file to Favorites", action:  {
            do  {
                try iaPlayer.appendFavoriteItem(file: archiveFile)
            } catch PlayerError.alreadyOnFavorites {
                self.favoritesErrorAlertShowing = true
            } catch {

            }
        }, imageName: "heart")


        let otherPlaylist = MenuAction(name: "Add to a playlist ...", action:  {
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
        Detail("wcd_ray-of-light_madonna_flac_lossless_522566").environmentObject(Player())
        //        Detail("13BinarySunsetAlternate").environmentObject(Player())
    }
}

