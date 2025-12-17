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
    @StateObject private var viewModel = ViewModel()
    @State private var isEditing = false
    
    // Adaptive grid layout - items will flow based on available width
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.filteredFavorites(from: iaPlayer.favoriteArchives).isEmpty {
                    VStack(alignment: .center, spacing: 16) {
                        Spacer()
                            .frame(height: 60)
                        
                        Image(systemName: viewModel.searchText.isEmpty ? "heart.slash" : "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text(viewModel.searchText.isEmpty ? "No Bookmarked Archives" : "No Results")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.primary)
                        
                        Text(viewModel.searchText.isEmpty ? "Add archives to your bookmarks by tapping the heart icon from the detail view" : "No bookmarks match '\(viewModel.searchText)'")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.filteredFavorites(from: iaPlayer.favoriteArchives), id: \.identifier) { archive in
                            ZStack(alignment: .topTrailing) {
                                // Main card with navigation
                                NavigationLink(value: archive) {
                                    FavoriteArchiveItemView(item: archive)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(isEditing)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            deleteArchive(archive)
                                        }
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
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Filter bookmarks")
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
            .task {
                iaPlayer.refreshFavoriteArchives()
                #if DEBUG
                viewModel.validateImageUrls(in: iaPlayer.favoriteArchives)
                #endif
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

// MARK: - ViewModel Extension
extension FavoriteArchivesView {
    @MainActor
    class ViewModel: ObservableObject {
        @Published var searchText: String = ""
        
        /// Filters the favorites based on the current search text
        /// - Parameter favorites: The array of favorite archives to filter
        /// - Returns: Filtered array of archives matching the search criteria
        func filteredFavorites(from favorites: [ArchiveMetaDataEntity]) -> [ArchiveMetaDataEntity] {
            guard !searchText.isEmpty else {
                return favorites
            }
            
            let searchLower = searchText.lowercased()
            
            return favorites.filter { archive in
                matchesSearch(archive, searchTerm: searchLower)
            }
        }
        
        /// Checks if an archive matches the search term
        /// - Parameters:
        ///   - archive: The archive to check
        ///   - searchTerm: The lowercased search term
        /// - Returns: True if the archive matches the search term
        private func matchesSearch(_ archive: ArchiveMetaDataEntity, searchTerm: String) -> Bool {
            // Search in title
            if let title = archive.archiveTitle?.lowercased(), 
               title.contains(searchTerm) {
                return true
            }

            // Search in creator
            if let creator = archive.creator?.lowercased(), 
               creator.contains(searchTerm) {
                return true
            }
            
            // Search in description
            if let description = archive.desc?.lowercased(), 
               description.contains(searchTerm) {
                return true
            }
            
            // Search in publisher
            if let publisher = archive.publisher?.lowercased(), 
               publisher.contains(searchTerm) {
                return true
            }
            
            return false
        }
        
        /// Debug helper to check for invalid URLs in favorites
        func validateImageUrls(in favorites: [ArchiveMetaDataEntity]) {
            #if DEBUG
            for archive in favorites {
                if let urlString = archive.iconUrlString {
                    if URL(string: urlString) == nil {
                        print("⚠️ Invalid URL for archive '\(archive.displayTitle)': \(urlString)")
                    }
                } else {
                    print("⚠️ Missing URL for archive '\(archive.displayTitle)'")
                }
            }
            #endif
        }
    }
}
