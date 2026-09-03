//
//  StablefordGolfApp.swift
//  StablefordGolf
//
//  Created by M4 on 4/9/2026.
//

import SwiftUI
import CoreData

@main
struct StablefordGolfApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
