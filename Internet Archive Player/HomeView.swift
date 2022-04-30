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
    @State var showPlaylist = false
    @State var playingFile: ArchiveFileEntity? = nil
    @State var identifier = ""

    var body: some View {
        VStack(alignment:.leading, spacing: 0) {
            Tabs()
            PlayerControls()
                .frame(height: 130, alignment: .bottom)
        }
        .sheet(isPresented: $showPlaylist, content: {
            Playlist()
        })
        .sheet(item: $playingFile, content: { file in
            Detail(file.identifier!)
        })
        .ignoresSafeArea(.keyboard)
        .environmentObject(iaPlayer)
        .onReceive(PlayerControls.showPlayList) { shouldShow in
            withAnimation {
                self.showPlaylist = shouldShow
            }
        }
        .onReceive(PlayerControls.showPlayingDetails) { file in
            withAnimation {
                playingFile = file
            }
        }

    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

