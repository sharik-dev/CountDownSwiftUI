//
//  CountDownSwiftUIApp.swift
//  CountDownSwiftUI
//
//  Created by Sharik Mohamed on 10/03/2025.
//

import SwiftUI
import WidgetKit

@main
struct CountDownSwiftUIApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        // Setup shared UserDefaults for app and widget
        setupSharedDefaults()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    
    private func setupSharedDefaults() {
        // Ensure we have a shared app group for the widget
        if let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI") {
            // Transfer any existing values from app defaults to shared defaults
            if let bedtime = UserDefaults.standard.object(forKey: "bedtime") as? Date {
                sharedDefaults.set(bedtime, forKey: "bedtime")
            } else {
                // Set default bedtime if none exists (10:00 PM)
                let defaultBedtime = Calendar.current.date(from: DateComponents(hour: 22, minute: 0))!
                sharedDefaults.set(defaultBedtime, forKey: "bedtime")
            }
            
            if let wakeupTime = UserDefaults.standard.object(forKey: "wakeupTime") as? Date {
                sharedDefaults.set(wakeupTime, forKey: "wakeupTime")
            } else {
                // Set default wake-up time if none exists (7:00 AM)
                let defaultWakeupTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0))!
                sharedDefaults.set(defaultWakeupTime, forKey: "wakeupTime")
            }
            
            // Transfer or set default for dark mode preference
            let isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
            sharedDefaults.set(isDarkMode, forKey: "isDarkMode")
            
            // Transfer or set default for accent color
            if let accentColor = UserDefaults.standard.string(forKey: "accentColor") {
                sharedDefaults.set(accentColor, forKey: "accentColor")
            } else {
                sharedDefaults.set("blue", forKey: "accentColor")
            }
            
            // Set default for timer running state if it doesn't exist
            if !sharedDefaults.contains(key: "timerRunning") {
                sharedDefaults.set(false, forKey: "timerRunning")
            }
            
            // Synchronize to ensure changes are saved
            sharedDefaults.synchronize()
            
            // Refresh widgets to reflect any changes
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            print("Error: Could not access shared UserDefaults. Widget functionality may be limited.")
        }
    }
}

// Extension to check if a key exists in UserDefaults
extension UserDefaults {
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
