//
//  PlayerButton.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/22/22.
//

import SwiftUI

enum PlayerButtonType: String {
    case play = "play"
    case backwards = "backward.end"
    case forwards = "forward.end"
    case pause = "pause"
    case expand = "arrow.up.left.and.arrow.down.right"
    case list = "list.bullet.rectangle.portrait"
    case listFill = "list.bullet.rectangle.portrait.fill"

}

struct PlayerButton: View {
    var type: PlayerButtonType
    var size: CGFloat?
    var action: (() -> ())?
    init(_ type: PlayerButtonType, _ size: CGFloat? = 20.0, _ action: (()->())? = nil){
        self.type = type
        self.size = size
        self.action = action
    }
    var body: some View {
        Button(action: {
            if let doAction = action {
                doAction()
            }
        }){
            Image(systemName: type.rawValue)
                .resizable()
                .frame(width: size, height: size)
        }
        .accentColor(.fairyCream)
    }
}

struct PlayerButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayerButton(.play)
    }
}
