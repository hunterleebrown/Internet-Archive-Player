//
//  HomeView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI
import iaAPI

struct HomeView: View {
    @StateObject var iaPlayer = Player()
    @State var playingFile: ArchiveFileEntity? = nil
    @State var identifier = ""
    @State var playerControlsCapacity: Double = 0
    @State var playerControlsHeight: CGFloat = 0.0
    @State var showPlayerControls: Bool = true

    var body: some View {
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

    private var playerHeight: CGFloat {
        showPlayerControls ? 130 : 0
    }

    private var playerOpacity: Double {
        showPlayerControls ? 1.0 : 0
    }

    private var expandeButtonText: String {
//        showPlayerControls ? "rectangle.compress.vertical" : "rectangle.expand.vertical"
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

