//
//  NewPlaylist.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 9/3/23.
//

import Foundation
import SwiftUI
import iaAPI
import Combine
import CoreData

struct NewPlaylist: View {
    @StateObject var viewModel = NewPlaylist.ViewModel()
    @State private var name: String = ""
    @Binding var isPresented: Bool


    var body: some View {
        VStack {
            TextField("New playlist name", text: $name)
                .padding()
            Button("Create") {
                viewModel.createPlaylist(name: name)
                isPresented = false
            }
            .padding()
            Spacer()

        }
        .navigationTitle("Create new playlist")

    }
}

extension NewPlaylist {
    final class ViewModel: NSObject, ObservableObject {

        private let listCreateController: NSFetchedResultsController<PlaylistEntity>

        override init() {
            listCreateController =             NSFetchedResultsController(fetchRequest:  PlaylistEntity.fetchRequestAllPlaylists(),
                                                                          managedObjectContext: PersistenceController.shared.container.viewContext,
                                                                          sectionNameKeyPath: nil,
                                                                          cacheName: nil)
            super.init()
        }

        func createPlaylist(name: String) {
            print(name)

            let newList = PlaylistEntity(context: PersistenceController.shared.container.viewContext)
            newList.name = name
            PersistenceController.shared.save()
        }

    }
}
