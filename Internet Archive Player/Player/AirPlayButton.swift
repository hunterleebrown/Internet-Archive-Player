//
//  AirPlayButton.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/22/22.
//
// Copied from: https://stackoverflow.com/questions/60079607/how-to-display-the-airplay-menu-swiftui

import Foundation
import SwiftUI
import AVKit
import MediaPlayer
import AVFoundation
import UIKit

struct AirPlayButton: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<AirPlayButton>) -> UIViewController {
        return AirPLayViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<AirPlayButton>) {

    }
}

class AirPLayViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        _ = self.traitCollection.userInterfaceStyle == .dark

        let button = UIButton()
        let boldConfig = UIImage.SymbolConfiguration(scale: .large)
        let boldSearch = UIImage(systemName: "airplayaudio", withConfiguration: boldConfig)

        button.setImage(boldSearch, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
//        button.backgroundColor = .red
        button.tintColor = .fairyCream //isDarkMode ? .fairyCream : .fairyCream

        button.addTarget(self, action: #selector(self.showAirPlayMenu(_:)), for: .touchUpInside)
        self.view.addSubview(button)
    }

    @objc func showAirPlayMenu(_ sender: UIButton){ // copied from https://stackoverflow.com/a/44909445/7974174
        let rect = CGRect(x: 0, y: 0, width: 0, height: 0)
        let airplayVolume = MPVolumeView(frame: rect)
        airplayVolume.showsVolumeSlider = false
        self.view.addSubview(airplayVolume)
        for view: UIView in airplayVolume.subviews {
            if let button = view as? UIButton {
                button.sendActions(for: .touchUpInside)
                break
            }
        }
        airplayVolume.removeFromSuperview()
    }
}
