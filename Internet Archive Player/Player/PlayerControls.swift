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

    static var showPlayList = PassthroughSubject<Bool, Never>()
    static var showPlayingDetails = PassthroughSubject<ArchiveFile, Never>()

    var body: some View {
        GeometryReader{ g in
            VStack(alignment: .leading){
                Slider(value: $viewModel.progress,
                       in: 0...1,
                       onEditingChanged: sliderEditingChanged)
                    .accentColor(.fairyCream)
                    .frame(height:20)
                    .disabled(viewModel.playingFile == nil)

                HStack{
                    Text(viewModel.minimumValue())
                        .foregroundColor(.fairyCream)
                        .font(.system(size:9.0))

                    Spacer()

                    Text(viewModel.remainingValue())
                        .foregroundColor(.fairyCream)
                        .font(.system(size:9.0))
                }
                .padding(.leading, 5)
                .padding(.trailing, 5)
                .frame(height:10)

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
                                if let file = viewModel.playingFile {
                                    PlayerControls.showPlayingDetails.send(file)
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
                    
                    PlayerButton(.list, 20, {
                        PlayerControls.showPlayList.send(true)
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

    private func sliderEditingChanged(editingStarted: Bool) {
        if editingStarted {
            iaPlayer.shouldPauseSliderProgress(true)
        } else {
            iaPlayer.seekTo(with: viewModel.progress)
        }
    }


}

extension PlayerControls {
    final class ViewModel: ObservableObject {
        var cancellables = Set<AnyCancellable>()
        @Published var playing: Bool = false
        @Published var playingFile: ArchiveFile?
        @Published var progress: Double = 0.0
        @Published var duration: Double = 0.0


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

            iaPlayer.durationSubjectPublisher
                .removeDuplicates()
                .sink { dur in
                    self.duration = dur
                }
                .store(in: &cancellables)

        }

        public func minimumValue() -> String {
            if !duration.isNaN {
                return IAStringUtils.timeFormatted(minimumCalc)
            }
            return ""
        }

        public func remainingValue() -> String {
            return IAStringUtils.timeFormatted(remainingCalc)
        }

        private var minimumCalc: Int {
            if !duration.isNaN {
                return Int(progress * duration)
            }
            return 0
        }

        private var remainingCalc : Int {
            if !duration.isNaN {
                return (Int(duration) - minimumCalc)
            }
            return 0
        }

    }
}

struct PlayerControls_Previews: PreviewProvider {
    static var previews: some View {
        PlayerControls()
    }
}
