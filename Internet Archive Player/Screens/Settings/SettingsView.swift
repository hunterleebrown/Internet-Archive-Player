//
//  SettingsView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/29/25.
//

import SwiftUI
import iaAPI

struct SettingsView: View {
    @EnvironmentObject var iaPlayer: Player

    @State private var playerSkin: PlayerControlsSkin = .classic

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                HStack{
                    Text("Player skin: ")
                        .foregroundColor(.fairyRed)
                    Picker("Player Skin", selection: $playerSkin) {
                        ForEach(PlayerControlsSkin.allCases, id: \.self) {
                            Text($0.rawValue.capitalized)
                        }
                        .onChange(of: playerSkin) {
                            withAnimation {
                                iaPlayer.playerSkin = playerSkin
                            }
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                NavigationLink(destination: DebugView()) {
                    Text("Debug")
                }

                Spacer()
            }
            .navigationTitle("Settings")
            .padding()
            .avoidPlayer()
            .task{
                if let skin = iaPlayer.playerSkin {
                    playerSkin = skin
                }
            }

        }
    }
}
