//
//  HistoryDrawerView.swift
//  Internet Archive Player
//
//  Created on 12/14/24.
//

import SwiftUI

struct HistoryDrawerView: View {
    @Binding var isPresented: Bool
    
    // Mock data for now - will be replaced with actual Core Data later
    let mockHistoryItems: [MockHistoryItem] = [
        MockHistoryItem(title: "Grateful Dead - 1977-05-08 - Barton Hall", artist: "Grateful Dead", identifier: "gd77-05-08"),
        MockHistoryItem(title: "Dark Star", artist: "Grateful Dead", identifier: "gd77-05-08"),
        MockHistoryItem(title: "Estimated Prophet", artist: "Grateful Dead", identifier: "gd77-05-08"),
        MockHistoryItem(title: "Live at the Fillmore", artist: "Miles Davis", identifier: "miles-fillmore"),
        MockHistoryItem(title: "So What", artist: "Miles Davis", identifier: "miles-fillmore"),
    ]
    
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
                    ForEach(mockHistoryItems) { item in
                        HistoryItemRow(item: item)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        
                        if item.id != mockHistoryItems.last?.id {
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
    }
}

struct HistoryItemRow: View {
    let item: MockHistoryItem
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Thumbnail
            AsyncImage(
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
            
            // Title and artist
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.fairyCream)
                    .lineLimit(2)
                
                Text(item.artist)
                    .font(.caption)
                    .foregroundColor(.fairyCream.opacity(0.8))
                    .lineLimit(1)
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
}

// Mock history item for preview purposes
struct MockHistoryItem: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let identifier: String
    
    var iconUrl: URL? {
        let itemImageUrl = "https://archive.org/services/img/\(identifier)"
        return URL(string: itemImageUrl)
    }
}

struct HistoryDrawerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.ignoresSafeArea()
            
            VStack {
                Spacer()
                HistoryDrawerView(isPresented: .constant(true))
            }
        }
    }
}
