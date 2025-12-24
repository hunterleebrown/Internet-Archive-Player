//
//  SearchFilters_tvOS.swift
//  Internet Archive Player tvOS
//
//  Created by Hunter Lee Brown on 12/20/25.
//

import Foundation
import SwiftUI
import iaAPI

struct SearchFilters_tvOS: View {
    @StateObject var viewModel: SearchFiltersViewModel
    @Binding var selectedFilter: SearchFilter?
    
    // Focus management for independent scrolling
    @Namespace private var topRowNamespace
    @Namespace private var userRowNamespace
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top Collections Row
            if !viewModel.items.isEmpty {
                filterRowSection(
                    title: "Top Collections",
                    filters: viewModel.items,
                    namespace: topRowNamespace
                )
            }
            
            // User Filters Row
            if !viewModel.userFilters.isEmpty {
                filterRowSection(
                    title: "My Used Filters",
                    filters: viewModel.userFilters,
                    namespace: userRowNamespace
                )
            }
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 8)
        .task {
            await viewModel.search()
        }
    }
    
    // MARK: - Filter Row Section
    
    @ViewBuilder
    private func filterRowSection(
        title: String,
        filters: [SearchFilter],
        namespace: Namespace.ID
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Section header
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))

                // Collection type indicator
                HStack(spacing: 4) {
                    Image(systemName: viewModel.collectionType == .movies ? "video" : "hifispeaker")
                        .font(.system(size: 16))
                    Text(viewModel.collectionType.rawValue.capitalized)
                        .font(.system(size: 16))
                }
            }
            
            // Horizontally scrolling filter buttons
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    // Clear Filter button
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = nil
                        }
                    } label: {
                        ClearFilterChip(isActive: selectedFilter != nil)
                    }
                    .buttonStyle(.plain)
                    
                    ForEach(filters) { filter in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        } label: {
                            FilterChip(
                                filter: filter,
                                isSelected: selectedFilter?.identifier == filter.identifier
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Clear Filter Chip

struct ClearFilterChip: View {
    let isActive: Bool
    @Environment(\.isFocused) var isFocused
    
    var body: some View {
        HStack(spacing: 8) {
            // X icon
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20))

            Text("Clear Filter")
                .font(.system(size: 18, weight: .medium))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minWidth: 140, maxHeight: 60)
        .opacity(isActive ? 1.0 : 0.6)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let filter: SearchFilter
    let isSelected: Bool
    @Environment(\.isFocused) var isFocused
    
    var body: some View {
        HStack(spacing: 8) {
            // Collection icon
            Group {
                if let image = filter.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                } else if let uiImage = filter.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                } else if filter.iconUrl != nil {
                    AsyncImage(url: filter.iconUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "folder")
                                    .font(.system(size: 14))
                            )
                    }
                } else {
                    // Default icon
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "folder")
                                .font(.system(size: 14))
                        )
                }
            }
            .frame(width: 36, height: 36)

            // Collection name and identifier
            VStack(alignment: .leading, spacing: 2) {
                Text(filter.name)
                    .font(.system(size: 18, weight: .medium))
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                
                if !filter.identifier.isEmpty {
                    Text(filter.identifier)
                        .font(.system(size: 14))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: 200, alignment: .leading)
            
            // Selected indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.fairyRed)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minWidth: 240, maxHeight: 60)
    }
}

// MARK: - Preview

struct SearchFilters_tvOS_Previews: PreviewProvider {
    static var previews: some View {
        SearchFilters_tvOS(
            viewModel: SearchFiltersViewModel(collectionType: .audio),
            selectedFilter: .constant(nil)
        )
        .background(Color.black)
    }
}
