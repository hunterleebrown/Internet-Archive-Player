//
//  PlayerControls.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/22/22.
//

import SwiftUI
import iaAPI
import Combine
import AVKit

struct PlayerControls: View {
    @EnvironmentObject var iaPlayer: Player
    @StateObject var viewModel: PlayerControls.ViewModel = PlayerControls.ViewModel()

    static var showPlayingDetails = PassthroughSubject<ArchiveFileEntity, Never>()
    static var showVideo = PassthroughSubject<Bool, Never>()

    var body: some View {
        VStack(alignment: .leading, spacing: 0.0){
            Slider(value: $viewModel.progress,
                   in: 0...1,
                   onEditingChanged: sliderEditingChanged)
            .tint(.fairyRed)
            .disabled(viewModel.playingFile == nil)

            HStack(alignment: .center, spacing: 5.0){
                Text(viewModel.minimumValue)
                    .foregroundColor(.fairyRed)
                    .font(.system(size:9.0))
                    .frame(width: 44.0)

                Spacer()
                if let file = viewModel.playingFile {
                    Button {
                        PlayerControls.showPlayingDetails.send(file)
                    } label: {
                        VStack(alignment: .center, spacing:2.0){
                            Text(viewModel.playingFile?.displayTitle ?? "")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.fairyRed)
                                .frame(maxWidth: .infinity, alignment:.center)
                                .multilineTextAlignment(.leading)
                            Text(viewModel.playingFile?.artist ?? viewModel.playingFile?.creator ?? "")
                                .font(.caption2)
                                .foregroundColor(.fairyRed)
                                .frame(maxWidth:. infinity, alignment: .center)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(5)
                        .overlay(
                              RoundedRectangle(cornerRadius: 10)
                                  .stroke(Color.fairyRed, lineWidth: 1)
                          )
                    }
                    .frame(maxHeight: 33.0)
                    .padding(5)
                }
                Spacer()

                Text(viewModel.remainingValue)
                    .foregroundColor(.fairyRed)
                    .font(.system(size:9.0))
                    .frame(width: 44.0)
            }
            .padding(.vertical, 10.0)

            HStack(alignment: .center, spacing: 10.0) {

                PlayerButton(.tv, CGSize(width: 30, height: 30)) {
                    PlayerControls.showVideo.send(true)
                }

//                CustomVideoPlayer(player: iaPlayer.avPlayer)
//                    .frame(width: 60, height: 40)
//                    .onTapGesture {
//                        PlayerControls.showVideo.send(true)
//                    }

//                VideoPlayer(player: iaPlayer.avPlayer)
//                    .frame(width: 60, height: 40)
//                    .onTapGesture {
//                        PlayerControls.showVideo.send(true)
//                    }

                Spacer()

                PlayerButton(.backwards) {
                    iaPlayer.advancePlayer(.backwards)
                }

                Spacer()

                PlayerButton(viewModel.playing ? .pause : .play, CGSize(width: 44.0, height: 44.0)) {
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
            .tint(.fairyCream)
            .padding(10)
        }
        .background(Color("playerBackground"))
        .onAppear() {
            viewModel.setSubscribers(iaPlayer)
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
        @Published var playingFile: ArchiveFileEntity?
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
                    DispatchQueue.main.async {
                        self.progress = prog
                    }
                }
                .store(in: &cancellables)

            iaPlayer.durationSubjectPublisher
                .removeDuplicates()
                .sink { dur in
                    DispatchQueue.main.async {
                        self.duration = dur
                    }
                }
                .store(in: &cancellables)

        }

        var minimumValue: String {
            if !duration.isNaN {
                return IAStringUtils.timeFormatted(minimumCalc)
            }
            return "00:00"
        }

        var remainingValue: String {
            return IAStringUtils.timeFormatted(remainingCalc)
        }

        private var minimumCalc: Int {
            if !duration.isNaN && !progress.isNaN{
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
            .environmentObject(Player())
    }
}

struct CustomVideoPlayer: UIViewControllerRepresentable {

    let player: AVPlayer?

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
//        controller.player = player
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
        uiViewController.view.layer.cornerRadius = 10.0
    }
}
