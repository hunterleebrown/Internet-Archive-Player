//
//  PlayerControls.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/22/22.
//

import SwiftUI

struct PlayerControls: View {
    @Binding var showPlayer: Bool
    var body: some View {
        GeometryReader{ g in
            VStack{

                Text("Hunter Lee Brown")
                    .foregroundColor(.fairyCream)
                    .fontWeight(.bold)
                Text("This is a super very long title that I'm trying to make a point on")
                    .font(.system(size: g.size.height > g.size.width ? g.size.width * 0.2: g.size.height * 0.2))
                    .foregroundColor(.fairyCream)
                HStack {
                    PlayerButton(showPlayer ? .listFill : .list, 20, {
                        withAnimation {
                            self.showPlayer.toggle()
                        }
                    })
                    Spacer()
                    PlayerButton(.backwards)
                    Spacer()
                    PlayerButton(.play, 44.0)
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
        PlayerControls(showPlayer: .constant(false))
    }
}
