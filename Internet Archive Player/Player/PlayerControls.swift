//
//  PlayerControls.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/22/22.
//

import SwiftUI
import iaAPI
import Combine

struct PlayerControls: View {
    @EnvironmentObject var iaPlayer: Player
    @StateObject var viewModel: PlayerControls.ViewModel = PlayerControls.ViewModel()
    @State var playing = false
    @State var showingPlaylist = false

    static var showPlayList = PassthroughSubject<Bool, Never>()
    static var showPlayingDetails = PassthroughSubject<String, Never>()

    var body: some View {
        GeometryReader{ g in
            VStack(alignment: .leading){
                ProgressView(value: viewModel.progress, total: 1)
                    .progressViewStyle(LinearProgressViewStyle(tint: .fairyCream))
                HStack(alignment: .top, spacing: 5.0){
                    if let playingFile = viewModel.playingFile {
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
                                if let identifier = viewModel.playingFile?.identifier {
                                    PlayerControls.showPlayingDetails.send(identifier)
                                }
                            }
                    }

                    VStack(alignment: .leading, spacing:2.0){
                        Text(viewModel.playingFile?.displayTitle ?? "")
                            .font(.caption)
                            .foregroundColor(.fairyCream)
                            .frame(maxWidth: .infinity, alignment:.leading)
                            .multilineTextAlignment(.leading)
                        Text(viewModel.playingFile?.artist ?? viewModel.playingFile?.creator?.joined(separator: ", ") ?? "")
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
                    
                    PlayerButton(showingPlaylist ? .listFill : .list, 20, {
                        showingPlaylist.toggle()
                        PlayerControls.showPlayList.send(showingPlaylist)
                    })
                    Spacer()
                    PlayerButton(.backwards) {
                        iaPlayer.advancePlayer(.backwards)
                    }
                    Spacer()

                    PlayerButton(viewModel.playing ? .pause : .play, 44.0) {
                        iaPlayer.didTapPlayButton()
                    }
                    Spacer()
                    PlayerButton(.forwards) {
                        iaPlayer.advancePlayer(.forwards)
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
            .onAppear() {
                viewModel.setSubscribers(iaPlayer)
            }
        }
    }




}

extension PlayerControls {
    final class ViewModel: ObservableObject {
        var cancellables = Set<AnyCancellable>()
        @Published var playing: Bool = false
        @Published var playingFile: ArchiveFile?
        @Published var progress: Double = 0.0

        func setSubscribers(_ iaPlayer: Player) {
            iaPlayer.playingPublisher
                .removeDuplicates()
                .sink { isPlaying in
                    self.playing = isPlaying
                }
                .store(in: &cancellables)

            iaPlayer.playingFilePublisher
                .removeDuplicates()
                .sink { file in
                    self.playingFile = file
                }
                .store(in: &cancellables)

            iaPlayer.sliderProgressPublisher
                .removeDuplicates()
                .sink { prog in
                    self.progress = prog
                }
                .store(in: &cancellables)
        }
    }
}

struct PlayerControls_Previews: PreviewProvider {
    static var previews: some View {
        PlayerControls()
    }
}
