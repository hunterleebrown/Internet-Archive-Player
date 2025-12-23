//
//  AirPlayButton.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/22/22.
//

import SwiftUI
import AVKit

struct AirPlayButton: UIViewRepresentable {
    var tintColor: Color = .white
    var size: CGFloat = 20

    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.tintColor = UIColor(tintColor)
        routePickerView.activeTintColor = UIColor(tintColor)
        routePickerView.prioritizesVideoDevices = false // Set to true if you want video devices prioritized

        return routePickerView
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.tintColor = UIColor(tintColor)
        uiView.activeTintColor = UIColor(tintColor)
    }
}
