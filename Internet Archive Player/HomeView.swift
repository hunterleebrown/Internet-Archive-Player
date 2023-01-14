//
//  HomeView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI
import iaAPI
import AVKit

struct HomeView: View {
    @StateObject var iaPlayer = Player()
    @State var playingFile: ArchiveFileEntity? = nil
    @State var identifier = ""
    @State var playerControlsHeight: CGFloat = 0.0
    @State var showPlayerControls: Bool = true
    @State var showVideoPlayer: Bool = false

    var body: some View {
        ZStack(alignment: .leading) {
            ZStack(){
                //VideoPlayer(player: iaPlayer.avPlayer)
                CustomVideoPlayer(player: iaPlayer.avPlayer)
                VStack(alignment: .leading) {
                    HStack {
                        Button{
                            showVideoPlayer = false
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .padding(10)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.white, lineWidth: 2)
                                .opacity(0.85)
                        )
                        .frame(width: 44.0, height: 44.0, alignment: .center)
                        .padding(.leading, 20)
                        .padding(.top, 100)
                        Spacer()
                    }
                    .opacity(1.0)

                    Spacer()
                }
            }
            .ignoresSafeArea()
            .zIndex(showVideoPlayer ? 1 : 0)

            VStack(alignment:.center, spacing: 0) {
                Tabs()
                Button(action: {
                    withAnimation {
                        showPlayerControls.toggle()
                    }

                }, label: {
                    HStack(alignment: .center, spacing: 5.0) {
                        Text(expandeButtonText)
                            .font(.caption)
                            .foregroundColor(.fairyRed)
                        Image(systemName: expandImageString)
                    }
                })
                .frame(alignment: .center)
                .padding(5)

                PlayerControls()
                    .frame(height: playerHeight, alignment: .bottom)
                    .opacity(playerOpacity)
            }
            .background(Color("playerBackground"))
            .zIndex(showVideoPlayer ? 0 : 1)
            .sheet(item: $playingFile, content: { file in
                Detail(file.identifier!, isPresented: true)
            })
            .ignoresSafeArea(.keyboard)
            .environmentObject(iaPlayer)
            .onReceive(PlayerControls.showPlayingDetails) { file in
                withAnimation {
                    playingFile = file
                }
            }
        }
        .onReceive(PlayerControls.showVideo) { show in
            showVideoPlayer = show
        }
    }

    private var playerHeight: CGFloat {
        showPlayerControls ? 130 : 0
    }

    private var playerOpacity: Double {
        showPlayerControls ? 1.0 : 0
    }

    private var expandeButtonText: String {
        showPlayerControls ? "Hide Controls" : "Show Controls"
    }
    private var expandImageString: String {
        showPlayerControls ? "arrow.down" : "arrow.up"
    }

}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

