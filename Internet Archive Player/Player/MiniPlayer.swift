//
//  Player.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI

struct MiniPlayer: View {
    @Binding var showPlayer: Bool
    var body: some View {
        VStack {
            PlayerControls(showPlaylist: $showPlayer)
        }
        .modifier(BackgroundColorModifier(backgroundColor: .fairyRed))
        .frame(height:98.0)
    }
}

struct MiniPlayer_Previews: PreviewProvider {
    static var previews: some View {
        MiniPlayer(showPlayer: .constant(false))
    }
}
