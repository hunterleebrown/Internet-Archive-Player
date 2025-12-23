//
//  SearchFilters.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 9/9/23.
//

import Foundation
import iaAPI
import SwiftUI
import UIKit

struct SearchFilters: View {
    
    // MARK: - Properties
    
    @StateObject var searchFiltersViewModel: SearchFiltersViewModel
    @Environment(\.dismiss) private var dismiss
    
    /// Binding to the currently selected filter in the parent view
    @Binding var selectedFilter: SearchFilter
    
    /// Callback when a filter is selected - allows parent to respond without tight coupling
    var onFilterSelected: ((SearchFilter) -> Void)?
    
    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Filter by Collection")
                    .font(.title2)
                    .foregroundColor(.fairyRed)
                    .bold()
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            // Collection type indicator
            HStack(spacing: 6) {
                Image(systemName: searchFiltersViewModel.collectionType == .movies ? "video" : "hifispeaker")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(searchFiltersViewModel.collectionType.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            Divider()
            
            // List of collections
            List {
                // Collection-based filters section
                Section {
                    ForEach(searchFiltersViewModel.items) { filter in
                        filterRow(for: filter)
                            .contentShape(Rectangle()) // Improve tap target
                            .onTapGesture {
                                handleFilterSelection(filter)
                            }
                    }
                } header: {
                    if !searchFiltersViewModel.userFilters.isEmpty {
                        Text("Top Collections")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.fairyRed)
                            .textCase(nil)
                            .padding(.top, 8)
                    }
                }
                
                // User filters section
                if !searchFiltersViewModel.userFilters.isEmpty {
                    Section {
                        ForEach(searchFiltersViewModel.userFilters) { filter in
                            filterRow(for: filter)
                                .contentShape(Rectangle()) // Improve tap target
                                .onTapGesture {
                                    handleFilterSelection(filter)
                                }
                        }
                    } header: {
                        Text("My Used Filters")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.fairyRed)
                            .textCase(nil)
                            .padding(.top, 8)
                    }
                }
            }
            .listStyle(.plain)
        }
        .presentationDragIndicator(.visible)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .task {
            // Use .task instead of .onAppear for proper async handling
            await searchFiltersViewModel.search()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Handles filter selection with proper state updates
    private func handleFilterSelection(_ filter: SearchFilter) {
        // Update the view model
        searchFiltersViewModel.collectionSelection = filter
        
        // Update the binding
        selectedFilter = filter
        
        // Notify parent through callback
        onFilterSelected?(filter)
        
        // Dismiss the sheet
        dismiss()
    }
    
    // MARK: - Helper Views
    
    /// Reusable filter row view
    @ViewBuilder
    private func filterRow(for filter: SearchFilter) -> some View {
        HStack(spacing: 10) {
            // Collection icon
            filterIcon(for: filter)
                .frame(width: 40, height: 40)
            
            // Collection name and identifier
            VStack(alignment: .leading, spacing: 2) {
                Text(filter.name)
                    .font(.subheadline)
                    .foregroundColor(isSelected(filter) ? .white : .primary)
                    .lineLimit(2)
                
                if !filter.identifier.isEmpty {
                    Text(filter.identifier)
                        .font(.caption2)
                        .foregroundColor(isSelected(filter) ? .white.opacity(0.8) : .secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Checkmark for selected
            if isSelected(filter) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.callout)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected(filter) ? Color.fairyRed : Color(UIColor.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected(filter) ? Color.fairyRed.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    /// Extracts the icon logic into a separate view builder
    @ViewBuilder
    private func filterIcon(for filter: SearchFilter) -> some View {
        Group {
            if let image = filter.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
            } else if let uiImage = filter.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
            } else if filter.iconUrl != nil {
                CachedAsyncImage(
                    url: filter.iconUrl,
                    content: { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .background(Color.black)
                    },
                    placeholder: {
                        Color(.systemGray5)
                            .frame(width: 40, height: 40)
                    })
                .cornerRadius(5)
            }
        }
    }
    
    /// Checks if a filter is currently selected
    private func isSelected(_ filter: SearchFilter) -> Bool {
        selectedFilter.identifier == filter.identifier
    }
}

struct SearchFilters_Previews: PreviewProvider {
    static var previews: some View {
        SearchFilters(
            searchFiltersViewModel: SearchFiltersViewModel(collectionType: .audio),
            selectedFilter: .constant(SearchFilter(name: "All", identifier: "")),
            onFilterSelected: { filter in
                print("Filter selected: \(filter.name)")
            }
        )
    }
}
