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
            HStack(alignment: .center) {
                Image(systemName: "music.note.list")
                    .font(.headline)
                    .foregroundColor(.fairyRed)
                Text("Create a new list")
                    .font(.headline)
                    .foregroundColor(.fairyRed)
            }
            .padding()
            TextField("New list name", text: $name)
                .padding()
                .cornerRadius(10)
                .onSubmit {
                    viewModel.createPlaylist(name: name)
                    isPresented = false
                }
            Button("Create") {
                viewModel.createPlaylist(name: name)
                isPresented = false
            }
            .buttonStyle(IAButton())
            .padding()
            Spacer()

        }
        .padding()
    }
}

extension NewPlaylist {
    final class ViewModel: NSObject, ObservableObject {

        private let listCreateController: NSFetchedResultsController<PlaylistEntity>

        override init() {
            listCreateController = NSFetchedResultsController(fetchRequest:  PlaylistEntity.fetchRequestAllPlaylists(),
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
struct NewPlaylistBindingPreview : View {
     @State
     private var value = false

     var body: some View {
         NewPlaylist(isPresented: $value)
     }
}

struct NewPlaylist_Preview: PreviewProvider {

    @State var showingNewPlaylist = false

    static var previews: some View {
        NewPlaylistBindingPreview()
    }

}
