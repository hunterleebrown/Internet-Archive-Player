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
    @State private var isEditing = false
    
    // Two-column grid layout
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if iaPlayer.favoriteArchives.isEmpty {
                    VStack(alignment: .center, spacing: 16) {
                        Spacer()
                            .frame(height: 60)
                        
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text("No Bookmarked Archives")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.primary)
                        
                        Text("Add archives to your bookmarks by tapping the heart icon from the detail view")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(iaPlayer.favoriteArchives, id: \.identifier) { archive in
                            ZStack(alignment: .topTrailing) {
                                // Main card with navigation
                                NavigationLink(value: archive) {
                                    FavoriteArchiveItemView(item: archive)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(isEditing)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteArchive(archive)
                                    } label: {
                                        Label("Remove Bookmark", systemImage: "heart.slash.fill")
                                    }
                                }
                                
                                // Delete button in edit mode
                                if isEditing {
                                    Button {
                                        withAnimation {
                                            deleteArchive(archive)
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .background(
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 24, height: 24)
                                            )
                                    }
                                    .offset(x: 8, y: -8)
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Spacer()
                    .frame(height: iaPlayer.playerHeight)
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("Bookmarks")
            .navigationDestination(for: ArchiveMetaDataEntity.self) { archive in
                Detail(archive.identifier ?? "")
            }
            .toolbar {
                if !iaPlayer.favoriteArchives.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(isEditing ? "Done" : "Edit") {
                            withAnimation {
                                isEditing.toggle()
                            }
                        }
                        .tint(.fairyRed)
                    }
                }
            }
            .onAppear {
                iaPlayer.refreshFavoriteArchives()
            }
        }
    }
    
    private func deleteArchive(_ archive: ArchiveMetaDataEntity) {
        if let identifier = archive.identifier {
            iaPlayer.removeFavoriteArchive(identifier: identifier)
        }
    }
}

struct FavoriteArchivesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoriteArchivesView()
            .environmentObject(Player())
    }
}
