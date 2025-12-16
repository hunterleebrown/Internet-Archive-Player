//
//  HistoryDrawerView.swift
//  Internet Archive Player
//
//  Created on 12/14/24.
//

import SwiftUI
import CoreData

struct HistoryDrawerView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("History")
                    .font(.title)
                    .foregroundColor(.fairyCream)
                    .bold()
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.fairyCream)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            // History items list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.historyItems, id: \.stableID) { item in
                        HistoryItemRow(item: item)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        
                        if item.stableID != viewModel.historyItems.last?.stableID {
                            Divider()
                                .background(Color.fairyCream.opacity(0.3))
                                .padding(.leading, 76)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.fairyRed.opacity(0.95))
        .onAppear {
            viewModel.fetchHistory()
        }
    }
}

struct HistoryItemRow: View {
    let item: HistoryArchiveFileEntity
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Thumbnail
            CachedAsyncImage(
                url: item.iconUrl,
                content: { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .background(Color.black)
                        .cornerRadius(5)
                },
                placeholder: {
                    Color.black
                        .frame(width: 50, height: 50)
                        .cornerRadius(5)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.fairyCream.opacity(0.5))
                        )
                }
            )
            .frame(width: 50, height: 50)
            
            // Title, artist, and metadata
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.fairyCream)
                    .lineLimit(2)
                
                Text(item.displayArtist)
                    .font(.caption)
                    .foregroundColor(.fairyCream.opacity(0.8))
                    .lineLimit(1)
                
                // Metadata: played date and play count
                HStack(spacing: 8) {
                    Text(formattedPlayedAt)
                        .font(.caption2)
                        .foregroundColor(.fairyCream.opacity(0.6))
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.fairyCream.opacity(0.6))
                    
                    Text("Played \(item.playCount) time\(item.playCount == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(.fairyCream.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Play button
            Button(action: {
                // TODO: Play this history item
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.fairyCream)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // TODO: Navigate to detail or play item
        }
    }
    
    private var formattedPlayedAt: String {
        guard let playedAt = item.playedAt else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy HH:mm:ss"
        return formatter.string(from: playedAt)
    }
}

// MARK: - ViewModel
extension HistoryDrawerView {
    @MainActor
    class ViewModel: ObservableObject {
        @Published var historyItems: [HistoryArchiveFileEntity] = []
        
        private let context = PersistenceController.shared.container.viewContext
        
        func fetchHistory() {
            let fetchRequest = HistoryArchiveFileEntity.historyFetchRequest
            
            do {
                historyItems = try context.fetch(fetchRequest)
            } catch {
                print("Error fetching history: \(error.localizedDescription)")
                historyItems = []
            }
        }
        
        func clearHistory() {
            for item in historyItems {
                context.delete(item)
            }
            
            do {
                try context.save()
                historyItems = []
            } catch {
                print("Error clearing history: \(error.localizedDescription)")
            }
        }
    }
}

struct HistoryDrawerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.ignoresSafeArea()
            
            VStack {
                Spacer()
                HistoryDrawerView(isPresented: .constant(true))
                    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            }
        }
    }
}
