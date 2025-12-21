//
//  PlayerSafeAreaModifier.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/21/24.
//

import SwiftUI

/// Modifier that adds safe area inset to avoid the player controls
struct AvoidPlayerModifier: ViewModifier {
    @EnvironmentObject var iaPlayer: Player
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if iaPlayer.playerHeight > 0 {
                    Spacer()
                        .frame(height: iaPlayer.playerHeight)
                }
            }
    }
}

extension View {
    /// Adds bottom safe area inset to avoid the player controls
    /// Automatically adjusts based on player visibility and height
    func avoidPlayer() -> some View {
        modifier(AvoidPlayerModifier())
    }
}
