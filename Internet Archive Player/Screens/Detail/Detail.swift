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
            Spacer().frame(height: 200)
            VStack(alignment: .center, spacing: 5.0) {
                Text(self.viewModel.archiveDoc?.archiveTitle ?? "")
                    .font(.headline)
                    .bold()
                    .foregroundColor(.black)
                    .frame(alignment: .center)
                    .multilineTextAlignment(.center)

                if let artist = self.viewModel.archiveDoc?.artist ?? self.viewModel.archiveDoc?.creator?.joined(separator: ", "), !artist.isEmpty {
                    HStack(alignment: .top) {
//                        Text("Artist: ")
//                            .bold()
//                            .font(.subheadline)
//                            .foregroundColor(.black)

                        Text(artist)
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.black)
                    }
                }

                if let publisher = self.viewModel.archiveDoc?.publisher, !publisher.isEmpty {
                    HStack(alignment: .top) {
//                        Text("Publisher: ")
//                            .bold()
//                            .font(.subheadline)
//                            .foregroundColor(.black)
                        Text(publisher.joined(separator: ", "))
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.black)
                    }
                }
            }
            .padding()
            .background(
                Color.white.opacity(0.5)
            )
            .cornerRadius(detailCornerRadius)

            VStack(alignment: .center, spacing: 5.0) {

                if (self.viewModel.archiveDoc?.description) != nil {
                    Button {
                        descriptionExpanded = true
                    } label: {
                        Text("Description")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(Color.fairyRed)
                            .padding()
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 10,
                                    style: .continuous
                                )
                                .fill(Color.white.opacity(0.5))
                            )
                    }
                }

                HStack() {
                    Spacer()
                    Menu {
                        Button(action: {
                            viewModel.addAllFilesToPlaylist(player: iaPlayer)
                        }){
                            HStack {
                                Image(systemName: PlayerButtonType.list.rawValue)
                                Text("Add all to playlist")
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

                LazyVStack(alignment: .leading) {
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
                            self.createFileView(file)
                                .padding(.leading, 5.0)
                                .padding(.trailing, 5.0)
                                .onTapGesture {
                                    do  {
                                        try iaPlayer.checkDupes(archiveFile: file)
                                    } catch PlayerError.alreadyOnPlaylist {
                                        self.playlistErrorAlertShowing = true
                                        return
                                    } catch {}
                                    iaPlayer.playFile(file)
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
                                        try iaPlayer.checkDupes(archiveFile: file)
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
//            .listRowBackground(Color.clear)
//            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
//            .listRowSeparator(.hidden)
        }
        .onChange(of: scrollOffset, perform: { scrollOfset in
            let offset = scrollOfset + (self.hideNavigationBar ? 50 : 0) // note 1
            if offset > 25 {
                withAnimation(.easeIn(duration: 1), {
                    self.hideNavigationBar = true
                    self.backgroundBlur = 10
                })
            }
            if offset < 75 {
                withAnimation(.easeIn(duration: 1), {
                    self.hideNavigationBar = false
                    self.backgroundBlur = 0
                })
            }
        })
        .navigationBarHidden(hideNavigationBar)
        .background(
            ZStack (alignment: .top) {
                if let img = self.backgroundURL {

                    if let img = viewModel.uiImage, let color = img.averageColor {
                        Rectangle().fill(
                            Color(color)
                        )
                        .ignoresSafeArea()
                    }

                    AsyncImage (
                        url: img,
                        content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(10)
                        },
                        placeholder: {
                            Color.black
                        })
                    .padding(10)
//                    .overlay(Rectangle().fill(Color.white.opacity(0.3)), alignment: .topTrailing)
                    .blur(radius: backgroundBlur)
                    .cornerRadius(40)

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
        }
        .sheet(isPresented: $descriptionExpanded) {
            if let doc = self.viewModel.archiveDoc {
                DetailDescription(doc: doc)
            }
        }
        //        .sheet(isPresented: $otherPlaylistPresented) {
        //            if let archivefile = viewModel.playlistArchiveFile {
        //                OtherPlaylist(isPresented: $otherPlaylistPresented, archiveFile: archivefile)
        //            }
        //        }
//        .navigationBarItems(trailing:
//                                Button(action: {
//        }) {
//            Image(systemName: "heart")
//                .tint(.fairyRed)
//        })
//        //        .navigationBarColor(backgroundColor: UIColor(white: 1.0, alpha: 0.5), titleColor: .fairyRed)
        //        .alert("Add all files to Playlist?", isPresented: $playlistAddAllAlert) {
        //            Button("No", role: .cancel) { }
        //            Button("Yes") {
        //                viewModel.addAllFilesToPlaylist(player: iaPlayer)
        //            }
        //        }
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
        .safeAreaInset(edge: .bottom) {
            Spacer()
                .frame(height:100)
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
                try iaPlayer.appendFavoriteItem(archiveFile)
            } catch PlayerError.alreadyOnFavorites {
                self.favoritesErrorAlertShowing = true
            } catch {

            }
        }, imageName: "heart")


        //        let otherPlaylist = MenuAction(name: "Add to playlist ...", action:  {
        //            do  {
        ////                try iaPlayer.appendFavoriteItem(archiveFile)
        //                viewModel.playlistArchiveFile = archiveFile
        //                otherPlaylistPresented = true
        //
        //            } catch PlayerError.alreadyOnFavorites {
        ////                self.favoritesErrorAlertShowing = true
        //            } catch {
        //
        //            }
        //        }, imageName: "music.note.list")

        actions.append(playlist)
        actions.append(favorites)
        //        actions.append(otherPlaylist)

        return actions
    }
}


struct Detail_Previews: PreviewProvider {
    static var previews: some View {
        Detail("hunterleebrown-lovesongs")
    }
}

