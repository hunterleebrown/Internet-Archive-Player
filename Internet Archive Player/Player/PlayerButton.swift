//
//  PlayerButton.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/22/22.
//

import SwiftUI
import AVKit

enum PlayerButtonType: String {
    case video = "video"
    case play = "play.fill"
    case backwards = "backward.end.fill"
    case forwards = "forward.end.fill"
    case pause = "pause"
    case expand = "arrow.up.left.and.arrow.down.right"
    case list = "list.bullet.rectangle.portrait"
    case listFill = "list.bullet.rectangle.portrait.fill"
    case tv = "tv.circle"
    case magnifyingGlass = "magnifyingGlass"

}

struct PlayerButton: View {
    var type: PlayerButtonType
    var size: CGSize?
    var action: (() -> ())?
    init(_ type: PlayerButtonType, _ size: CGSize? = CGSize(width: 20.0, height: 20.0), _ action: (()->())? = nil){
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
                .frame(width: size?.width, height: size?.height)
        }
        .tint(.fairyCream)
    }
}

struct PlayerButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayerButton(.play)
    }
}
