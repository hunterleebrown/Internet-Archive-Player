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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Create a new list")
                    .font(.title)
                    .foregroundColor(.fairyRed)
                    .bold()
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.fairyRed)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            // Content
            VStack(spacing: 16) {
                TextField("New list name", text: $name)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.systemGray6))
                    )
                    .onSubmit {
                        if !name.isEmpty {
                            viewModel.createPlaylist(name: name)
                            isPresented = false
                            dismiss()
                        }
                    }

                Button("Create") {
                    viewModel.createPlaylist(name: name)
                    isPresented = false
                    dismiss()
                }
                .buttonStyle(IAButton())
                .disabled(name.isEmpty)
            }
            .padding(20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
