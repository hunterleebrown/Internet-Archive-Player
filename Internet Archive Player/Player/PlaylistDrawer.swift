// PlaylistDrawer.swift
// Drawer view for playlist functionality
import SwiftUI

struct PlaylistDrawer: View {
    @EnvironmentObject var iaPlayer: Player
    @State private var expanded: Bool = false
    private let collapsedHeight: CGFloat = 22
    private let expandedHeight: CGFloat = 200
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    Text("Playlist")
                        .foregroundColor(.fairyCream)
                        .font(.caption)
                    
                    Image(systemName: expanded ? "chevron.down" : "chevron.up")
                        .foregroundColor(.fairyCream)
                        .font(.caption2)
                        .imageScale(.small)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: collapsedHeight)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring()) {
                    expanded.toggle()
                }
            }
            
            if expanded {
                // Compact list of playlist items
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            if let playlistFiles = iaPlayer.playingPlaylist?.files?.array as? [ArchiveFileEntity],
                               let playlist = iaPlayer.playingPlaylist {
                                ForEach(playlistFiles, id: \.self) { file in
                                    PlayerlistDrawerRow(
                                        file: file,
                                        isCurrentlyPlaying: file == iaPlayer.playingFile
                                    ) {
                                        iaPlayer.playFileFromPlaylist(file, playlist: playlist)
                                    }
                                    .id(file)
                                }
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                    }
                    .frame(height: expandedHeight - collapsedHeight)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        if let currentFile = iaPlayer.playingFile {
                            withAnimation {
                                proxy.scrollTo(currentFile, anchor: .center)
                            }
                        }
                    }
                    .onChange(of: iaPlayer.playingFile) { oldValue, newValue in
                        if let currentFile = newValue {
                            withAnimation {
                                proxy.scrollTo(currentFile, anchor: .center)
                            }
                        }
                    }
                }
            }

        }
        .background(Color.fairyRed.opacity(0.85))
        .frame(height: expanded ? expandedHeight : collapsedHeight)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(radius: expanded ? 8 : 2)
        .animation(.spring(), value: expanded)
    }
}

struct PlayerlistDrawerRow: View {
    let file: ArchiveFileEntity
    let isCurrentlyPlaying: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isCurrentlyPlaying ? "speaker.wave.2.fill" : "music.note")
                    .font(.caption2)
                    .foregroundColor(isCurrentlyPlaying ? .fairyRed : .fairyCream)
                    .frame(width: 12)
                
                Text(file.displayTitle)
                    .font(.caption2)
                    .foregroundColor(isCurrentlyPlaying ? .fairyRed : .fairyCream)
                    .fontWeight(isCurrentlyPlaying ? .semibold : .regular)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()
            }
            .padding(5)
            .frame(height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(isCurrentlyPlaying ? .fairyCream.opacity(0.90) : Color.clear)
        .cornerRadius(4)
    }
}

#Preview {
    PlaylistDrawer()
        .environmentObject(Player())
}

