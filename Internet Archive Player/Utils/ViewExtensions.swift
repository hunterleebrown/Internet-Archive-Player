//
//  ViewExtensions.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 9/9/23.
//

import Foundation
import SwiftUI
import UIKit

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func roundedCorner(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners) )
    }

}

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct ObservableScrollView<Content>: View where Content : View {
    @Namespace var scrollSpace
    @Binding var scrollOffset: CGFloat
    let content: () -> Content

    init(scrollOffset: Binding<CGFloat>,
         @ViewBuilder content: @escaping () -> Content) {
        _scrollOffset = scrollOffset
        self.content = content
    }

    var body: some View {
        ScrollView(.vertical) {
                content()
                    .background(GeometryReader { geo in
                        let offset = -geo.frame(in: .named(scrollSpace)).minY
                        Color.clear
                            .preference(key: ScrollViewOffsetPreferenceKey.self,
                                        value: offset)
                    })

        }
        .coordinateSpace(name: scrollSpace)
        .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
    }
}

extension View {
    /// A convenience method for applying `TouchDownUpEventModifier.`
    func onTouchDownUp(pressed: @escaping ((Bool) -> Void)) -> some View {
        self.modifier(TouchDownUpEventModifier(pressed: pressed))
    }
}

struct TouchDownUpEventModifier: ViewModifier {
    /// Keep track of the current dragging state. To avoid using `onChange`, we won't use `GestureState`
    @State var dragged = false

    /// A closure to call when the dragging state changes.
    var pressed: (Bool) -> Void
    func body(content: Content) -> some View {
        content
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !dragged {
                            dragged = true
                            pressed(true)
                        }
                    }
                    .onEnded { _ in
                        dragged = false
                        pressed(false)
                    }
            )
    }
}
