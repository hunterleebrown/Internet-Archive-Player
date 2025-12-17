//
//  TVSearchView.swift
//  Internet Archive Player tvOS
//
//  Created by Hunter Lee Brown on 10/28/23.
//

import Foundation
import SwiftUI
import iaAPI
import Combine

struct TVSearchView: View {
    @StateObject var viewModel = TVSearchView.ViewModel()

    // Adaptive columns that adjust based on available space
    let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.items.isEmpty && !viewModel.isSearching {
                    // Empty state - matches iOS aesthetic
                    VStack(spacing: 30) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 120, weight: .thin))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolEffect(.pulse, options: .repeating)
                        
                        VStack(spacing: 12) {
                            Text("Search the Internet Archive")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                            
                            if !viewModel.noDataFound {
                                Text("Discover audio and video from the archive")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.5))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        if viewModel.noDataFound {
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Text("No results found")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                if let error = viewModel.archiveError {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                } else {
                                    Text("Try different search terms")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .padding(.top, 20)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 30)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.05))
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(maxWidth: 600)
                    .transition(.opacity.combined(with: .scale))
                } else if viewModel.isSearching && viewModel.items.isEmpty {
                    // Loading state
                    VStack(spacing: 25) {
                        ProgressView()
                            .scaleEffect(2)
                            .tint(.white.opacity(0.7))
                        
                        VStack(spacing: 8) {
                            Text("Searching...")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Exploring the archive")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .transition(.opacity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(Array(viewModel.items.enumerated()), id: \.element) { index, doc in
                                NavigationLink(destination: TVDetail(doc: doc)) {
                                    ItemCard(doc: doc)
                                }
                                .buttonStyle(CardButtonStyle())
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .opacity
                                ))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7).delay(Double(index) * 0.02), value: viewModel.items.count)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                    }
                }
            }
            .animation(.easeInOut, value: viewModel.items.isEmpty)
            .animation(.easeInOut, value: viewModel.isSearching)
            .searchable(text: $viewModel.searchText, prompt: "Search The Internet Archive")
        }
    }
}

// MARK: - Item Card
struct ItemCard: View {
    let doc: ArchiveMetaData
    @Environment(\.isFocused) var isFocused
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text(doc.archiveTitle ?? "")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Text(doc.formatDateString() ?? "")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))
            }
            .foregroundColor(.white)
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.8),
                        Color.black.opacity(0.4),
                        Color.clear
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .aspectRatio(1.2, contentMode: .fit)
        .background(
            AsyncImage(url: doc.iconUrl, transaction: Transaction(animation: .spring())) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.3)
                        ProgressView()
                            .tint(.white.opacity(0.5))
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .transition(.opacity.combined(with: .scale(scale: 1.1)))
                case .failure(_):
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.3))
                    }
                @unknown default:
                    Color.gray.opacity(0.3)
                }
            }
        )
        .clipped()
        .cornerRadius(12)
        .shadow(color: isFocused ? .white.opacity(0.3) : .clear, radius: 20, x: 0, y: 10)
    }
}

// MARK: - Card Button Style
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension TVSearchView {
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var items: [ArchiveMetaData] = []
        @Published var searchText: String = ""
        @Published var isSearching: Bool = false
        @Published var noDataFound: Bool = false
        @Published var archiveError: String?

        public let mediaTypes: [ArchiveMediaType] = [.audio, .movies]
        private var searchTask: Task<Void, Never>?
        private var page: Int = 1
        private let rows = 50

        let service: PlayerArchiveService

        init() {
            self.service = PlayerArchiveService()
            
            // Simple debounced search using Task
            Task { @MainActor in
                for await searchText in $searchText.values {
                    // Cancel previous search
                    searchTask?.cancel()
                    
                    let query = searchText.trimmingCharacters(in: .whitespaces)
                    
                    // Clear results if query is too short
                    guard query.count > 2 else {
                        items = []
                        noDataFound = false
                        archiveError = nil
                        continue
                    }
                    
                    // Debounce
                    try? await Task.sleep(for: .milliseconds(500))
                    
                    // Start search
                    searchTask = Task { @MainActor in
                        await performSearch(query: query)
                    }
                }
            }
        }
        
        private func performSearch(query: String) async {
            isSearching = true
            noDataFound = false
            archiveError = nil
            page = 1
            
            do {
                let data = try await service.searchAsync(
                    query: query,
                    mediaTypes: mediaTypes,
                    rows: rows,
                    page: page,
                    format: nil,
                    collection: nil
                )
                
                // Check if task was cancelled
                guard !Task.isCancelled else { return }
                
                items = data.response.docs
                isSearching = false
                
                if items.isEmpty {
                    noDataFound = true
                    archiveError = "No results found"
                }
                
            } catch let error as ArchiveServiceError {
                guard !Task.isCancelled else { return }
                archiveError = error.description
                noDataFound = true
                isSearching = false
            } catch {
                guard !Task.isCancelled else { return }
                isSearching = false
            }
        }
        
        func loadMore() async {
            guard !isSearching else { return }
            
            let query = searchText.trimmingCharacters(in: .whitespaces)
            guard query.count > 2 else { return }
            
            isSearching = true
            page += 1
            
            do {
                let data = try await service.searchAsync(
                    query: query,
                    mediaTypes: mediaTypes,
                    rows: rows,
                    page: page,
                    format: nil,
                    collection: nil
                )
                
                items.append(contentsOf: data.response.docs)
                isSearching = false
                
            } catch {
                isSearching = false
                page -= 1 // Revert page on failure
            }
        }
    }
}


struct Home_Preview: PreviewProvider {
    static var previews: some View {
        TVSearchView()
    }
}
