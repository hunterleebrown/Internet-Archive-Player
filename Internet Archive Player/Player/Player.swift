//
//  Player.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI

struct Player: View {
    @Binding var showPlayer: Bool
    var body: some View {
        VStack{
            PlayerControls(showPlayer: $showPlayer)
        }
    }
}

struct Player_Previews: PreviewProvider {
    static var previews: some View {
        Player(showPlayer: .constant(false))
    }
}
