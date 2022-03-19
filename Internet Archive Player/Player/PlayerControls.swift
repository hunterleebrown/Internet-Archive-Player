//
//  PlayerControls.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/22/22.
//

import SwiftUI

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
                        Spacer()
                    }

                    VStack(alignment: .trailing, spacing:5.0){
                        Text(iaPlayer.playingFile?.file.title ?? iaPlayer.playingFile?.file.name ?? "")
                            .font(.system(size: g.size.height > g.size.width ? g.size.width * 0.2: g.size.height * 0.2))
                            .foregroundColor(.fairyCream)
                            .fontWeight(.bold)
                            .frame(alignment:.leading)
                        Text(iaPlayer.playingFile?.artist ?? "")
                            .font(.system(size: g.size.height > g.size.width ? g.size.width * 0.2: g.size.height * 0.2))
                            .foregroundColor(.fairyCream)
                            .frame(alignment: .leading)
                    }
                    .frame(alignment: .leading)
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
        func goForwards(_ player: IAPlayer, _ list: [PlaylistItem]) {
            if let playingFile = player.playingFile, let index = list.firstIndex(of: playingFile) {
                guard list.indices.contains(index + 1) else { return }
                player.playFile(list[index + 1])
            }
        }
        func goBackwards(_ player: IAPlayer, _ list: [PlaylistItem]) {
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
