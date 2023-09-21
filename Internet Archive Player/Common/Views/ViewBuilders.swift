//
//  ViewBuilders.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 9/20/23.
//

import Foundation
import SwiftUI

struct IAButton: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .padding()
            .frame(height: 33)
            .foregroundColor(Color.fairyRed)
            .background(
                RoundedRectangle(
                     cornerRadius: 10,
                     style: .continuous
                 )
                .stroke(Color.fairyRed)
            )

    }
}
