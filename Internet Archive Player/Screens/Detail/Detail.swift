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

    @State private var showFullscreenImage = false

    var detailCornerRadius: CGFloat = 5.0

    init(_ identifier: String, isPresented: Bool = false) {
        self.identifier = identifier
        self.isPresented = isPresented
    }

    var body: some View {
        ZStack {
            if isLoading {
                VStack(alignment: .center, spacing: 20) {
                    Spacer()
                    
                    // Animated icon with pulsing effect
                    ZStack {
                        Circle()
                            .fill(Color.fairyRed.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "archivebox")
                            .font(.system(size: 50))
                            .foregroundColor(.fairyRed)
                            .symbolEffect(.pulse, options: .repeating)
                    }
                    
                    Text("Loading Archive")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.primary)
                    
                    Text("Fetching details from the Internet Archive...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
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
        .fullScreenCover(isPresented: $showFullscreenImage) {
            if let url = backgroundURL {
                FullscreenImageViewer(imageURL: url, isPresented: $showFullscreenImage)
            }
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
                LazyVStack {

                    Spacer().frame(height: 300)

                    VStack(alignment: .leading, spacing:5) {
                        HStack(alignment: .top, spacing: 8) {
                            if backgroundURL != nil {
                                Button {
                                    showFullscreenImage = true
                                } label: {
                                    Image(systemName: "photo")
                                        .font(.title3)
                                        .foregroundColor(.black)
                                        .padding(8)
                                        .background(Color.white.opacity(0.3))
                                        .clipShape(Circle())
                                }
                            }

                            Text(self.viewModel.archiveDoc?.archiveTitle ?? "")
                                .font(.headline)
                                .bold()
                                .foregroundColor(Color(.black))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)

                            if backgroundURL != nil {
                                Spacer()
                                    .frame(width: 40)
                            }
                        }
                        .padding(.top, 10)
                        .padding(.horizontal, 10)

                        if let artist = self.viewModel.archiveDoc?.artist ?? self.viewModel.archiveDoc?.creator?.joined(separator: ", "), !artist.isEmpty {
                            Text(artist)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .frame(maxWidth: .infinity, alignment: .center)

                        }

                        VStack(alignment: .center) {
                            HStack(spacing: 10) {

                                if (self.viewModel.archiveDoc?.description) != nil {
                                    Button {
                                        descriptionExpanded = true
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: "info.circle")
                                                .font(.title2)
                                                .frame(height: 28)
                                                .tint(.black)
                                            Text("Description")
                                                .font(.caption2)
                                                .foregroundColor(.black)
                                        }
                                    }
                                    .frame(minWidth: 100)

                                    Divider()
                                        .frame(height: 44)
                                }

                                Button {
                                    if viewModel.toggleFavoriteArchive(identifier: identifier) != nil {
                                        favoriteArchivesErrorAlertShowing = true
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(systemName: viewModel.isFavoriteArchive ? "books.vertical.fill" : "books.vertical")
                                                .font(.title2)
                                                .frame(height: 28)
                                                .tint(.black)
                                            
                                            // Green checkmark badge when bookmarked
                                            if viewModel.isFavoriteArchive {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundStyle(.white, .green)
                                                    .offset(x: 6, y: -6)
                                            }
                                        }
                                        Text("Bookmark")
                                            .font(.caption2)
                                            .foregroundColor(.black)
                                    }
                                }
                                .frame(minWidth: 100)


                                Divider()
                                    .frame(height: 44)

                                ShareLink(item: URL(string: "https://archive.org/details/\(identifier)")!) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "square.and.arrow.up.circle")
                                            .font(.title2)
                                            .frame(height: 28)
                                            .tint(.black)
                                        Text("Share")
                                            .font(.caption2)
                                            .foregroundColor(.black)
                                    }
                                }
                                .frame(minWidth: 100)


                            }
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(detailCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: detailCornerRadius)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                            )

                            Spacer()
                                .frame(height:10)

                        }
                        .padding(.horizontal, 10)

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
                            VStack(alignment: .center, spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary.opacity(0.5))

                                Text("No Playable Files")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                Text("This archive doesn't contain audio or video files compatible with the app")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)

                                Link("View on archive.org", destination: URL(string: "https://archive.org/details/\(identifier)")!)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.fairyRed)
                                    .padding(.top, 4)
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.5))
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
                                                Text("Play All as New Playlist")
                                                    .font(.caption2)
                                                    .foregroundColor(.black)
                                            }
                                            .frame(width: 80)
                                            .padding(.vertical, 12)
                                        }

                                        Spacer()

                                        Menu {

                                            Button(action: {
                                                viewModel.playAllAudio(startPlayback: false)
                                            }){
                                                Label("Make Playlist \(self.viewModel.archiveDoc?.archiveTitle ?? "")", systemImage: PlayerButtonType.list.rawValue)
                                            }
                                            .frame(width: 44, height: 44)


                                            Button(action: {
                                                viewModel.playlistArchiveFiles = viewModel.audioFiles + viewModel.movieFiles
                                                otherPlaylistPresented = true
                                            }){
                                                Label("Add All to Playlist...", systemImage: PlayerButtonType.list.rawValue)
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

                                    Text("Tap a track to play it, or use Play All to queue everything.")
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


                                // Paginated audio files
                                ForEach(Array(viewModel.displayedAudioFiles.enumerated()), id: \.element.id) { i, file in
                                    HStack(alignment: .center, spacing: 5) {

                                        Image(systemName: PlayerButtonType.ear.rawValue)
                                            .frame(width: 33, height: 33)
                                            .background(viewModel.pressedStates[file.id] == true ? Color.fairyCreamAlpha : Color.fairyRedAlpha)
                                            .cornerRadius(10)
                                            .foregroundColor(viewModel.pressedStates[file.id] == true ? Color.fairyRedAlpha : Color.fairyCreamAlpha)
                                            .onTouchDownUp { pressed in
                                                viewModel.pressedStates[file.id] = pressed
                                                if pressed {
                                                    viewModel.previewAudio(file: file)
                                                } else {
                                                    viewModel.stopPreview()
                                                }
                                            }

                                        self.createFileView(file)
                                            .padding(.horizontal, 5)
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
                                    .onAppear {
                                        // Auto-load more when nearing the end
                                        if i == viewModel.displayedAudioFiles.count - 5 {
                                            viewModel.loadMoreAudioFiles()
                                        }
                                    }
                                }
                                
                                // Load More button (if there are more files)
                                if viewModel.hasMoreAudioFiles {
                                    Button {
                                        viewModel.loadMoreAudioFiles()
                                    } label: {
                                        HStack(spacing: 8) {
                                            if viewModel.isLoadingMore {
                                                ProgressView()
                                                    .tint(.fairyRed)
                                            } else {
                                                Image(systemName: "arrow.down.circle")
                                                    .font(.title3)
                                            }
                                            Text(viewModel.isLoadingMore ? "Loading..." : "Load More (\(viewModel.remainingAudioCount) remaining)")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundColor(.fairyRed)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.white.opacity(0.5))
                                        .cornerRadius(detailCornerRadius)
                                    }
                                    .disabled(viewModel.isLoadingMore)
                                    .padding(.vertical, 8)
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
                                        .scaledToFill()
                                        .transition(.opacity)
                                        .blur(radius: backgroundBlur)

                                case .failure(_):
                                    EmptyView()

                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(height: 400)
                            .clipped()
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


        let otherPlaylist = MenuAction(name: "Add to Playlist...", action:  {
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

struct FullscreenImageViewer: View {
    let imageURL: URL
    @Binding var isPresented: Bool
    @State private var showControls = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .tint(.white)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure(_):
                    VStack(spacing: 10) {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Failed to load image")
                            .foregroundColor(.gray)
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .onTapGesture {
                withAnimation {
                    showControls.toggle()
                }
            }

            if showControls {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    Spacer()
                }
                .transition(.opacity)
            }
        }
    }
}

