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
    @Binding var showVideoPlayer: Bool

    static var showPlayingDetails = PassthroughSubject<ArchiveFileEntity, Never>()
    static var showVideo = PassthroughSubject<Bool, Never>()
    static var toggleHistory = PassthroughSubject<Void, Never>()

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

                    HStack(alignment: .center, spacing: 15) {

                        PlayerButton(.history, CGSize(width: 20, height: 20)) {
                            PlayerControls.toggleHistory.send()
                        }

                        if viewModel.isPlayingVideo {
                            PlayerButton(.video, CGSize(width: 20, height: 20)) {
                                showVideoPlayer = true
                            }
                        }

                        PlayerButton(.hidePlay, CGSize(width: 20, height: 20)) {
                            withAnimation{
                                Home.showControlsPass.send(false)
                            }
                        }

                        AirPlayButton()
                            .frame(width: 44, height: 44)
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
                    .font(.caption)
                    .frame(minWidth: 44.0)

                Spacer()

                Text(viewModel.remainingValue)
                    .foregroundColor(foregroundColor)
                    .font(.caption)
                    .frame(minWidth: 44.0)
            }

            HStack(alignment: .center, spacing: 10.0) {

                Spacer()

                PlayerButton(.backwards)  {
                    iaPlayer.advancePlayer(.backwards)
                }

                Spacer()

                PlayerButton(.bb) {
                }
                .onTouchDownUp { pressed in
                    if pressed {
                        iaPlayer.seek(forward: false)
                    } else {
                        iaPlayer.stopSeeking()
                    }
                }
                
                Spacer()

                PlayerButton(viewModel.playing ? .pause : .play, CGSize(width: 40, height: 40)) {
                    iaPlayer.didTapPlayButton()
                }

                Spacer()

                PlayerButton(.ff) {
                }
                .onTouchDownUp { pressed in
                    if pressed {
                        iaPlayer.seek(forward: true)
                    } else {
                        iaPlayer.stopSeeking()
                    }
                }

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

        weak var iaPlayer: Player?

        func setSubscribers(_ iaPlayer: Player) {
            self.iaPlayer = iaPlayer
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

        var isPlayingVideo: Bool {
            guard let file = playingFile else { return false }
            // Check if format is video-related
            // Video formats include: h.264, h264 HD, MPEG4, etc.
            // Audio format is typically "VBR MP3"
            return file.format != "VBR MP3" && file.format != nil
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
        PreviewWrapper()
            .environmentObject(Player())
    }
    
    struct PreviewWrapper: View {
        @State private var showVideoPlayer: Bool = false
        
        var body: some View {
            PlayerControls(showVideoPlayer: $showVideoPlayer)
        }
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
