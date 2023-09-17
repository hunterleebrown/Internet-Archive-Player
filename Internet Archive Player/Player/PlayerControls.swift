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

    var foregroundColor: Color = .fairyCream
    var backgroundColor: Color = .fairyRed.opacity(0.8)

    var body: some View {
        VStack(alignment: .leading, spacing: 5){

            if let file = viewModel.playingFile {
                HStack(alignment: .center) {

                    Button {
                        PlayerControls.showPlayingDetails.send(file)
                    } label: {
                        HStack(alignment: .center) {
                            AsyncImage(
                                url: file.iconUrl,
                                content: { image in
                                    image.resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 44,
                                               maxHeight: 44)
                                        .background(Color.black)

                                },
                                placeholder: {
                                    Color(.black)
                                        .frame(maxWidth: 44,
                                               maxHeight: 44)
                                })
                            .cornerRadius(5)
                            .frame(width: 44, height: 44, alignment: .leading)

                            VStack(alignment: .leading, spacing:2.0){
                                Text(viewModel.playingFile?.displayTitle ?? "")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(foregroundColor)
                                    .frame(maxWidth: .infinity, alignment:.leading)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                                Text(viewModel.playingFile?.artist ?? viewModel.playingFile?.creator ?? viewModel.playingFile?.archiveTitle ?? "")
                                    .font(.caption2)
                                    .foregroundColor(foregroundColor)
                                    .frame(maxWidth:. infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                        }
                    }

                    Spacer()

                    PlayerButton(viewModel.playing ? .pause : .play, CGSize(width: 40, height: 40)) {
                        iaPlayer.didTapPlayButton()
                    }

                }
            }

            Slider(value: $viewModel.progress,
                   in: 0...1,
                   onEditingChanged: sliderEditingChanged)
            .tint(foregroundColor)
            .disabled(viewModel.playingFile == nil)

            HStack(alignment: .center, spacing: 5.0){
                Text(viewModel.minimumValue)
                    .foregroundColor(foregroundColor)
                    .font(.system(size:9.0))
                    .frame(width: 44.0)

                Spacer()

                Text(viewModel.remainingValue)
                    .foregroundColor(foregroundColor)
                    .font(.system(size:9.0))
                    .frame(width: 44.0)
            }

            HStack(alignment: .center, spacing: 10.0) {

                Spacer()

                PlayerButton(.backwards) {
                    iaPlayer.advancePlayer(.backwards)
                }

                Spacer()

                AirPlayButton()
                    .frame(width: 44, height: 44)

                Spacer()

                PlayerButton(.forwards) {
                    iaPlayer.advancePlayer(.forwards)
                }

                Spacer()

            }
            .tint(foregroundColor)
        }
        .padding(5)
        .background(
            backgroundColor

            //            AsyncImage (
            //                url: viewModel.playingFile?.iconUrl,
            //                content: { image in
            //                    image
            //                        .resizable()
            //                        .aspectRatio(contentMode: .fill)
            //                },
            //                placeholder: {
            //                    Color.black
            //                })
            //            .overlay(Rectangle().fill(Color.white.opacity(0.3)), alignment: .topTrailing)
            //            .clipped()

        )
        .coordinateSpace(name: "playerControls")
        .cornerRadius(10)
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

    @EnvironmentObject var iaPlayer: Player

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.view.backgroundColor = UIColor.black
        controller.view.layer.cornerRadius = 10.0
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = iaPlayer.avPlayer
    }

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: ()) {
//        Player.shared.avPlayer = nil
    }
}
