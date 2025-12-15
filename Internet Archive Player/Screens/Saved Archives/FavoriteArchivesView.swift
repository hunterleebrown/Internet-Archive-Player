//
//  FavoriteArchivesView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/11/24.
//

import SwiftUI
import iaAPI

struct FavoriteArchivesView: View {
    @EnvironmentObject var iaPlayer: Player
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if iaPlayer.favoriteArchives.isEmpty {
                    VStack(alignment: .center, spacing: 10) {
                        Image(systemName: "heart.slash")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No Bookmarked Archives")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Add archives to your bookmarks by tapping the heart icon from the detail view")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                } else {
                    ForEach(iaPlayer.favoriteArchives, id: \.identifier) { archive in
                        NavigationLink(value: archive) {
                            FavoriteArchiveItemView(item: archive)
                        }
                        .listRowInsets(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                        .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: deleteArchives)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Spacer()
                    .frame(height: iaPlayer.playerHeight)
            }
            .padding()
            .listStyle(PlainListStyle())
            .navigationTitle("Bookmarks")
            .navigationDestination(for: ArchiveMetaDataEntity.self) { archive in
                Detail(archive.identifier ?? "")
            }
            .toolbar {

                if !iaPlayer.favoriteArchives.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
            }
            .onAppear {
                iaPlayer.refreshFavoriteArchives()
            }
        }
    }
    
    private func deleteArchives(at offsets: IndexSet) {
        for index in offsets {
            let archive = iaPlayer.favoriteArchives[index]
            if let identifier = archive.identifier {
                iaPlayer.removeFavoriteArchive(identifier: identifier)
            }
        }
    }
}

struct FavoriteArchivesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoriteArchivesView()
            .environmentObject(Player())
    }
}
