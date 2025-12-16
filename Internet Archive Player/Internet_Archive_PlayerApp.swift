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
    @StateObject private var filterCache = CollectionFilterCache.shared
    
    var body: some Scene {
        WindowGroup {
            Home()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .task {
                    // Preload collection filters on app startup
                    await filterCache.preloadFilters()
                }
        }
        .onChange(of: scenePhase) { 
            persistenceController.save()
        }
    }
}
