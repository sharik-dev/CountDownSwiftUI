// SleepEntry.swift
// CountDownSwiftUI
//
// Created by Sharik Mohamed on 24/03/2025.
//

import WidgetKit
import SwiftUI

struct SleepEntry: TimelineEntry {
    let date: Date
    
    // Paramètres de base
    let bedtime: Date
    let wakeupTime: Date
    let isDarkMode: Bool
    let accentColorString: String
    
    // Paramètres personnalisables pour les textes et icônes
    let bedtimeIcon: String
    let wakeupIcon: String
    let alertIcon: String
    let bedtimeText: String
    let wakeupText: String
    let alertText: String
    
    init(date: Date) {
        self.date = date
        
        // UserDefaults partagé avec l'identifiant correct
        let defaults = UserDefaults(suiteName: "group.com.tempest.CountDownSwiftUI")
        
        // Valeurs par défaut si non définies
        let defaultBedtime = Calendar.current.date(from: DateComponents(hour: 22, minute: 0))!
        let defaultWakeupTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0))!
        
        // Récupérer les valeurs depuis UserDefaults
        self.bedtime = defaults?.object(forKey: "bedtime") as? Date ?? defaultBedtime
        self.wakeupTime = defaults?.object(forKey: "wakeupTime") as? Date ?? defaultWakeupTime
        self.isDarkMode = defaults?.bool(forKey: "isDarkMode") ?? false
        self.accentColorString = defaults?.string(forKey: "accentColor") ?? "blue"
        
        // Récupérer les valeurs personnalisables
        self.bedtimeIcon = defaults?.string(forKey: "bedtimeIcon") ?? "bed.double.fill"
        self.wakeupIcon = defaults?.string(forKey: "wakeupIcon") ?? "alarm.fill"
        self.alertIcon = defaults?.string(forKey: "alertIcon") ?? "exclamationmark.triangle.fill"
        self.bedtimeText = defaults?.string(forKey: "bedtimeText") ?? "Time until bedtime"
        self.wakeupText = defaults?.string(forKey: "wakeupText") ?? "Time until wake-up"
        self.alertText = defaults?.string(forKey: "alertText") ?? "Sleep time running out!"
    }
} 