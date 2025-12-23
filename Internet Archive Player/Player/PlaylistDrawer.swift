// PlaylistDrawer.swift
// Drawer view for playlist functionality
import SwiftUI

struct PlaylistDrawer: View {
    @EnvironmentObject var iaPlayer: Player
    @State private var expanded: Bool = false
    var skin: PlayerControlsSkin = .classic
    private let collapsedHeight: CGFloat = 33
    private let expandedHeight: CGFloat = 200
    
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                HStack(spacing: 15) {
                    Button(action: {
                        withAnimation(.spring()) {
                            expanded.toggle()
                        }
                    }) {
                        HStack(spacing: 5) {

                            if skin != .winAmp {
                                Text("Playlist")
                                    .foregroundColor(skin == .classic ? .fairyCream : .gray)
                                    .font(.caption)

                                Image(systemName: expanded ? "chevron.down" : "chevron.up")
                                    .foregroundColor(.fairyCream)
                                    .font(.caption2)
                                    .imageScale(.small)
                            } else {

                                VStack(spacing:2) {
                                    Rectangle()
                                        .fill(.white)
                                        .frame(height: 2)
                                    Rectangle()
                                        .fill(.gray)
                                        .frame(height: 2)
                                }

                                Text("Playlist")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                                    .monospaced(true)
                                    .textCase(.uppercase)
                                    .fontWeight(.heavy)

                                Image(systemName: expanded ? "chevron.down" : "chevron.up")
                                    .foregroundColor(.fairyCream)
                                    .font(.caption2)
                                    .imageScale(.small)

                                VStack(spacing:2) {
                                    Rectangle()
                                        .fill(.white)
                                        .frame(height: 2)
                                    Rectangle()
                                        .fill(.gray)
                                        .frame(height: 2)
                                }

                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .frame(height: 24)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .overlay {
                        if skin != .winAmp {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.fairyCream, lineWidth: 1)
                        }
                    }

                    if skin != .winAmp {
                        Spacer()

                        PlayerButton(.history, CGSize(width: 20, height: 20)) {
                            PlayerControls.toggleHistory.send()
                        }

                        AirPlayButton(tintColor: .fairyCream, size: 22)
                            .frame(width: 33, height: 33, alignment: .center)

                        PlayerButton(.hidePlay, CGSize(width: 20, height: 20)) {
                            withAnimation{
                                Home.showControlsPass.send(false)
                            }
                        }
                    }

                }
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity)
            }
            .frame(height: collapsedHeight)
            .contentShape(Rectangle())

            if expanded {
                // Compact list of playlist items
                ScrollViewReader { proxy in
                    if skin == .winAmp {
                        scrollView(proxy: proxy)
                            .winAmpValue()
                            .foregroundColor(.green)
                            .monospaced()
                    } else {
                        scrollView(proxy: proxy)
                            .foregroundColor(.fairyCream)
                    }
                }
            }
        }
        .frame(height: expanded ? expandedHeight : collapsedHeight)
        .animation(.spring(), value: expanded)
    }

    private func scrollView(proxy: ScrollViewProxy) -> some View {
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
            .padding(.vertical, 4)
        }
//                    .background(Color.fairyRed.brightness(-0.2))
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

struct PlayerlistDrawerRow: View {
    let file: ArchiveFileEntity
    let isCurrentlyPlaying: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isCurrentlyPlaying ? "speaker.wave.2.fill" : "music.note")
                    .font(.caption2)
//                    .foregroundColor(isCurrentlyPlaying ? .fairyRed : .fairyCream)
                    .frame(width: 12)
                
                Text(file.displayTitle)
                    .font(.caption2)
//                    .foregroundColor(isCurrentlyPlaying ? .fairyRed : .fairyCream)
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
//        .background(isCurrentlyPlaying ? .fairyCream.opacity(0.90) : Color.clear)
        .cornerRadius(4)
    }
}

#Preview {
    PlaylistDrawer()
        .environmentObject(Player())
}

