//
//  DraggableModifier.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 9/9/23.
//

import Foundation
import SwiftUI

struct DraggableModifier : ViewModifier {

    enum Direction {
        case vertical
        case horizontal
    }

    let direction: Direction

    @State private var draggedOffset: CGSize = .zero

    func body(content: Content) -> some View {
        content
        .offset(
            CGSize(width: direction == .vertical ? 0 : draggedOffset.width,
                   height: direction == .horizontal ? 0 : draggedOffset.height)
        )
        .gesture(
            DragGesture()
            .onChanged { value in
                self.draggedOffset = value.translation
            }
            .onEnded { value in
                self.draggedOffset = .zero
            }
        )
    }

}
