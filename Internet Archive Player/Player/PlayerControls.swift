//
//  PlayerControls.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/22/22.
//

import SwiftUI

struct PlayerControls: View {
    @EnvironmentObject var playlistViewModel: Playlist.ViewModel
    @EnvironmentObject var iaPlayer: IAPlayer
    
    @Binding var showPlaylist: Bool
    @State var playing: Bool = false
    
    var body: some View {
        GeometryReader{ g in
            VStack{
                
                VStack(){
                    Text(iaPlayer.playingFile?.file.title ?? iaPlayer.playingFile?.file.name ?? "")
                        .foregroundColor(.fairyCream)
                        .fontWeight(.bold)
                    Text(iaPlayer.playingFile?.doc.artist ??  iaPlayer.playingFile?.doc.creator ?? "")
                        .font(.system(size: g.size.height > g.size.width ? g.size.width * 0.2: g.size.height * 0.2))
                        .foregroundColor(.fairyCream)
                }
                .frame(height: 44.0, alignment: .center)
                .padding(.leading, 5.0)
                .padding(.trailing, 5.0)
                
                HStack {
                    
                    PlayerButton(showPlaylist ? .listFill : .list, 20, {
                        withAnimation {
                            self.showPlaylist.toggle()
                        }
                    })
                    Spacer()
                    PlayerButton(.backwards)
                    Spacer()
                    
                    PlayerButton(iaPlayer.playing ? .pause : .play, 44.0) {
                        iaPlayer.didTapPlayButton()
                    }
                    Spacer()
                    PlayerButton(.forwards)
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

struct PlayerControls_Previews: PreviewProvider {
    static var previews: some View {
        PlayerControls(showPlaylist: .constant(false))
    }
}
