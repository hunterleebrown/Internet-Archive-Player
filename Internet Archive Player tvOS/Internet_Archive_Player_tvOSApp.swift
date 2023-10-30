//
//  Internet_Archive_Player_tvOSApp.swift
//  Internet Archive Player tvOS
//
//  Created by Hunter Lee Brown on 10/28/23.
//

import SwiftUI

@main
struct Internet_Archive_Player_tvOSApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            TVSearchView()
        }
    }
}
