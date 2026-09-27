//
//  SysPocketApp.swift
//  SysPocket
//
//  Created by Jonathan Reeves on 9/26/26.
//

import SwiftUI
import SwiftData

@main
struct SysPocketApp: App {
    // Listens for background/foreground transitions
    @Environment(\.scenePhase) private var scenePhase
    
    // Instantiates our new security manager
    @State private var biometricService = BiometricService()
    
    @State private var store = SubscriptionManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Server.self,
            Webhook.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            // The Gatekeeper: Only show the dashboard if unlocked
            if biometricService.isUnlocked {
                DashboardView()
                    .environment(store)
                    .task {
                        await store.loadProducts()
                    }
            } else {
                LockScreenView(biometricService: biometricService)
            }
        }
        .modelContainer(sharedModelContainer)
        // Triggered every time the app state changes
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                // Instantly revert to the lock screen to hide sensitive server URLs from the app switcher
                biometricService.lock()
            }
        }
    }
}
