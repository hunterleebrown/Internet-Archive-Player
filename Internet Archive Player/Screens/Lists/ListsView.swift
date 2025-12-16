//
//  Lists.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 9/3/23.
//

import Foundation
import SwiftUI
import iaAPI
import Combine
import CoreData

struct ListsView: View {
    @StateObject var viewModel = ListsView.ViewModel()
    @EnvironmentObject var iaPlayer: Player

    var body: some View {
        NavigationStack {

            List {
                NavigationLink {
                    NewFavoritesView()
                }   label: {
                    HStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.fairyRed)
                            .font(.body)
                        Text("Favorites")
                            .foregroundColor(.fairyRed)
                            .fontWeight(.semibold)
                    }
                }

                ForEach(viewModel.lists, id: \.self) { list in
                    NavigationLink {
                        SingleListView(playlistEntity: list)
                    }   label: {
                        HStack(spacing: 12) {
                            if list.name == "Now Playing" {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.fairyRed)
                                    .font(.body)
                            } else {
                                Image(systemName: "music.note.list")
                                    .foregroundColor(.secondary)
                                    .font(.body)
                            }
                            Text(list.name ?? "Untitled Playlist")
                                .foregroundColor(list.name == "Now Playing" ? .fairyRed : .primary)
                                .fontWeight(list.name == "Now Playing" ? .semibold : .regular)
                        }
                    }
                }
                .onDelete(perform: viewModel.remove)
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Playlists")
            .toolbar {
                Button(action: {
                    Home.newPlaylistPass.send(true)
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.fairyRed)
                    Text("Create Playlist")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Spacer()
                    .frame(height: iaPlayer.playerHeight)
            }
        }
    }
}

extension ListsView {

    final class ViewModel: NSObject, ObservableObject {
        @Published var lists: [PlaylistEntity] = [PlaylistEntity]()
        private let listsFetchController: NSFetchedResultsController<PlaylistEntity>

        override init() {
            listsFetchController =
            NSFetchedResultsController(fetchRequest:  PlaylistEntity.fetchRequestAllPlaylists(),
                                       managedObjectContext: PersistenceController.shared.container.viewContext,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)

            super.init()
            listsFetchController.delegate = self

            do {
                try listsFetchController.performFetch()
                if let playlists = listsFetchController.fetchedObjects {
                    DispatchQueue.main.async {
                        if playlists.count > 0 {
                            self.lists = playlists.filter{!$0.permanent}
                        }
                    }
                }
            } catch {
                print("failed to fetch items!")
            }
        }


        func remove(at offsets: IndexSet) {
            for index in offsets {
                let list = lists[index]

                guard let files = list.files?.array as? [ArchiveFileEntity] else {
                    return
                }

                files.forEach { item in
                    if item.isLocalFile(), let workingUrl = item.workingUrl {
                        do {
                            try Downloader.removeFile(at: workingUrl)
                        } catch let error {
                            print(error.localizedDescription)
                        }
                    }
                }

                PersistenceController.shared.delete(list)
            }
        }
    }

}

extension ListsView.ViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let playlists = controller.fetchedObjects as? [PlaylistEntity]
        else { return }
        DispatchQueue.main.async {
            if playlists.count > 0 {
                self.lists = playlists.filter{!$0.permanent}
            }
        }
    }
}

#Preview {
    ListsView()
}
