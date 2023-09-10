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

    init(_ identifier: String, isPresented: Bool = false) {
        self.identifier = identifier
        self.isPresented = isPresented
    }
    
    var body: some View {
        List {
            VStack(alignment: .center, spacing: 5.0) {
                if let iconUrl = viewModel.archiveDoc?.iconUrl {
                    AsyncImage (
                        url: iconUrl,
                        content: { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(minWidth:180, maxWidth: 180,
                                       minHeight: 180, maxHeight: 180)
                                .background(Color.black)
                        },
                        placeholder: {
                            Color.black
                        })
                    .frame(minWidth:180, maxWidth: 180,
                           minHeight: 180, maxHeight: 180)
                    .cornerRadius(15)
                    .shadow(color: .gray, radius: 5, x: 0, y: 5)

                }

                Text(self.viewModel.archiveDoc?.archiveTitle ?? "")
                    .font(.headline)
                    .bold()

                if let artist = self.viewModel.archiveDoc?.artist ?? self.viewModel.archiveDoc?.creator?.joined(separator: ", ") {
                    Text(artist)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }

                if let publisher = self.viewModel.archiveDoc?.publisher {
                    Text(publisher.joined(separator: ", "))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }

                if let desc = self.viewModel.archiveDoc?.description {
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
                                .stroke(Color.fairyRed)
                            )
                    }
                }

                

                HStack() {
                    Text("Files")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.fairyRed)
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
                    }
                    .highPriorityGesture(TapGesture())
                }
                .padding(10)

                LazyVStack(alignment: .leading) {
                    if self.viewModel.audioFiles.count > 0 {
                        Text("Audio")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.fairyRed)
                            .padding(.horizontal, 10)

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
                            .foregroundColor(.fairyRed)
                            .padding(.horizontal, 10)

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

            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowSeparator(.hidden)
            .padding(10)
        }
        .listStyle(PlainListStyle())
        .navigationTitle("Archive")
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
        .navigationBarItems(trailing:
                                Button(action: {
        }) {
            Image(systemName: "heart")
                .tint(.fairyRed)
        })
//        .navigationBarColor(backgroundColor: UIColor(white: 1.0, alpha: 0.5), titleColor: .fairyRed)
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

