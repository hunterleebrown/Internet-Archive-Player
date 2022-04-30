//
//  Internet_Archive_PlayerApp.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI

@main
struct Internet_Archive_PlayerApp: App {
    @Environment(\.scenePhase) var scenePhase
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            HomeView()
                .onAppear() {
                    let appearance = UINavigationBarAppearance()
                    let style = NSMutableParagraphStyle()
                    style.alignment = .center
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                        .paragraphStyle: style
                    ]

                    appearance.largeTitleTextAttributes = attrs

                    UINavigationBar.appearance().scrollEdgeAppearance = appearance
                }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .onChange(of: scenePhase) { _ in
            persistenceController.save()
        }
    }
}
