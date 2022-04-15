//
//  PlayerControls.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/22/22.
//

import SwiftUI
import iaAPI

struct PlayerControls: View {
    @EnvironmentObject var iaPlayer: IAPlayer
    @State var playing: Bool = false

    var viewModel: PlayerControls.ViewModel = PlayerControls.ViewModel()

    var body: some View {
        GeometryReader{ g in
            VStack(alignment: .leading){
                ProgressView(value: iaPlayer.sliderProgress, total: 1)
                    .progressViewStyle(LinearProgressViewStyle(tint: .fairyCream))
                HStack(alignment: .top, spacing: 5.0){
                    if let playingFile = iaPlayer.playingFile {
                        AsyncImage(
                            url: playingFile.iconUrl,
                            content: { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 44,
                                           maxHeight: 44)
                                    .background(Color.black)

                            },
                            placeholder: {
                                ProgressView()
                            })
                            .cornerRadius(5)
                            .frame(maxWidth: 44,
                                   maxHeight: 44)
                            .onTapGesture {
                                withAnimation {
                                    iaPlayer.showPlayingDetailView.toggle()
                                }
                            }
                    }

                    VStack(alignment: .leading, spacing:2.0){
                        Text(iaPlayer.playingFile?.title ?? iaPlayer.playingFile?.name ?? "")
                            .font(.caption)
                            .foregroundColor(.fairyCream)
                            .frame(maxWidth: .infinity, alignment:.leading)
                            .multilineTextAlignment(.leading)
                        Text(iaPlayer.playingFile?.artist ?? iaPlayer.playingFile?.creator?.joined(separator: ", ") ?? "")
                            .font(.caption2)
                            .foregroundColor(.fairyCream)
                            .frame(maxWidth:. infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 44.0)
                .padding(.leading, 5.0)
                .padding(.trailing, 5.0)

                HStack {
                    
                    PlayerButton(iaPlayer.showPlaylist ? .listFill : .list, 20, {
                        withAnimation {
                            iaPlayer.showPlaylist.toggle()
                        }
                    })
                    Spacer()
                    PlayerButton(.backwards) {
                        viewModel.goBackwards(iaPlayer, iaPlayer.items)
                    }
                    Spacer()

                    PlayerButton(iaPlayer.playing ? .pause : .play, 44.0) {
                        iaPlayer.didTapPlayButton()
                    }
                    Spacer()
                    PlayerButton(.forwards) {
                        viewModel.goForwards(iaPlayer, iaPlayer.items)
                    }
                    Spacer()
                    AirPlayButton()
                        .frame(width: 33.0, height: 33.0)
                }
                .accentColor(.fairyCream)
                .padding(.leading)
                .padding(.trailing)
            }
            .padding(.top, 5.0)
            .modifier(BackgroundColorModifier(backgroundColor: .fairyRed))
        }
    }




}

extension PlayerControls {
    final class ViewModel {
        func goForwards(_ player: IAPlayer, _ list: [ArchiveFile]) {
            if let playingFile = player.playingFile, let index = list.firstIndex(of: playingFile) {
                guard list.indices.contains(index + 1) else { return }
                player.playFile(list[index + 1])
            }
        }
        func goBackwards(_ player: IAPlayer, _ list: [ArchiveFile]) {
            if let playingFile = player.playingFile, let index = list.firstIndex(of: playingFile) {
                guard list.indices.contains(index - 1) else { return }
                player.playFile(list[index - 1])
            }
        }
    }
}

struct PlayerControls_Previews: PreviewProvider {
    static var previews: some View {
        PlayerControls()
    }
}
