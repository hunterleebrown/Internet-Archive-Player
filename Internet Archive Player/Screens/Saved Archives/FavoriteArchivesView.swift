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
        NavigationView {
            List {
                if iaPlayer.favoriteArchives.isEmpty {
                    VStack(alignment: .center, spacing: 10) {
                        Image(systemName: "heart.slash")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No Favorite Archives")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Add archives to your favorites from the detail view")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                } else {
                    ForEach(iaPlayer.favoriteArchives, id: \.identifier) { archive in
                        NavigationLink(destination: Detail(archive.identifier ?? "")) {
                            FavoriteArchiveRow(archive: archive)
                        }
                    }
                    .onDelete(perform: deleteArchives)
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Favorite Archives")
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Done") {
//                        dismiss()
//                    }
//                }
                
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

struct FavoriteArchiveRow: View {
    let archive: ArchiveMetaDataEntity
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AsyncImage(
                url: archive.iconUrl,
                content: { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .background(Color.black)
                },
                placeholder: {
                    Color(.black)
                        .frame(width: 60, height: 60)
                })
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(archive.displayTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if let creator = archive.displayCreator {
                    Text(creator)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if let publisher = archive.displayPublisher {
                    Text(publisher)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if let mediatype = archive.mediatype {
                    HStack {
                        Image(systemName: mediatypeIcon(mediatype))
                            .font(.caption)
                        Text(mediatype.capitalized)
                            .font(.caption)
                    }
                    .foregroundColor(.fairyRed)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func mediatypeIcon(_ mediatype: String) -> String {
        switch mediatype.lowercased() {
        case "audio", "etree":
            return "hifispeaker"
        case "movies":
            return "video"
        default:
            return "questionmark.circle"
        }
    }
}

struct FavoriteArchivesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoriteArchivesView()
            .environmentObject(Player())
    }
}
