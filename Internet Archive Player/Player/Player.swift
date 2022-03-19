//
//  Player.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI

struct Player: View {
    var body: some View {
        VStack{
            PlayerControls()
        }
    }
}

struct Player_Previews: PreviewProvider {
    static var previews: some View {
        Player()
    }
}
