//
//  SleepCountdownWidgetControl.swift
//  SleepCountdownWidget
//
//  Created by Sharik Mohamed on 24/03/2025.
//

import AppIntents
import SwiftUI
import WidgetKit

struct SleepCountdownWidgetControl: Widget {
    static let kind: String = "sharik.CountDownSwiftUI.SleepCountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: Self.kind,
            provider: SleepTimerProvider()
        ) { entry in
            SleepCountdownWidgetView(entry: entry)
        }
        .configurationDisplayName("Sleep Timer")
        .description("Control your sleep countdown timer.")
        .supportedFamilies([.systemSmall])
    }
}

struct SleepCountdownWidgetView: View {
    var entry: SleepTimerEntry
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: entry.isRunning ? "timer" : "timer.slash")
                    .foregroundStyle(entry.isRunning ? .green : .red)
                Text(entry.isRunning ? "Running" : "Stopped")
                    .font(.headline)
            }
            
            if entry.isRunning {
                Text(entry.statusText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text(entry.timeRemaining)
                    .font(.system(.title, design: .monospaced, weight: .bold))
                    .foregroundStyle(.primary)
            }
        }
        .padding()
    }
}

struct SleepTimerEntry: TimelineEntry {
    let date: Date
    let isRunning: Bool
    let statusText: String
    let timeRemaining: String
}

struct SleepTimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> SleepTimerEntry {
        SleepTimerEntry(
            date: Date(),
            isRunning: false,
            statusText: "",
            timeRemaining: ""
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SleepTimerEntry) -> Void) {
        let entry = SleepTimerEntry(
            date: Date(),
            isRunning: true,
            statusText: "Next: Bedtime",
            timeRemaining: "08:30"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepTimerEntry>) -> Void) {
        let userDefaults = UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")
        
        // Récupérer l'état du minuteur
        let isRunning = userDefaults?.bool(forKey: "timerRunning") ?? false
        
        var entries: [SleepTimerEntry] = []
        let currentDate = Date()
        
        // Si le minuteur n'est pas en marche, créer une entrée simple
        if !isRunning {
            let entry = SleepTimerEntry(
                date: currentDate,
                isRunning: false,
                statusText: "",
                timeRemaining: ""
            )
            entries.append(entry)
        } else {
            // Récupérer l'heure du coucher et du réveil
            let bedtime = userDefaults?.object(forKey: "bedtime") as? Date ??
                Calendar.current.date(from: DateComponents(hour: 22, minute: 0))!
            
            let wakeupTime = userDefaults?.object(forKey: "wakeupTime") as? Date ??
                Calendar.current.date(from: DateComponents(hour: 7, minute: 0))!
            
            // Calculer si on est avant l'heure du coucher
            let isBeforeBedtime = calculateIsBeforeBedtime(bedtime: bedtime, wakeupTime: wakeupTime)
            
            // Créer des entrées pour les prochaines heures
            for minuteOffset in stride(from: 0, to: 60, by: 5) {
                let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
                
                // Calculer le temps restant pour cette entrée
                let timeRemainingStr = calculateTimeRemaining(
                    isBeforeBedtime: isBeforeBedtime,
                    bedtime: bedtime,
                    wakeupTime: wakeupTime,
                    currentDate: entryDate
                )
                
                let entry = SleepTimerEntry(
                    date: entryDate,
                    isRunning: true,
                    statusText: "Prochain : \(isBeforeBedtime ? "Coucher" : "Réveil")",
                    timeRemaining: timeRemainingStr
                )
                entries.append(entry)
            }
        }
        
        // Créer une timeline avec les entrées
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func calculateIsBeforeBedtime(bedtime: Date, wakeupTime: Date) -> Bool {
        let calendar = Calendar.current
        let currentDate = Date()
        
        let bedComponents = calendar.dateComponents([.hour, .minute], from: bedtime)
        let wakeComponents = calendar.dateComponents([.hour, .minute], from: wakeupTime)
        let currentComponents = calendar.dateComponents([.hour, .minute], from: currentDate)
        
        let bedMinutes = bedComponents.hour! * 60 + bedComponents.minute!
        let wakeMinutes = wakeComponents.hour! * 60 + wakeComponents.minute!
        let currentMinutes = currentComponents.hour! * 60 + currentComponents.minute!
        
        if wakeMinutes < bedMinutes {
            // L'heure de réveil est le jour suivant
            return currentMinutes < wakeMinutes || currentMinutes >= bedMinutes
        } else {
            // L'heure de réveil est le même jour
            return currentMinutes >= wakeMinutes && currentMinutes < bedMinutes
        }
    }
    
    private func calculateTimeRemaining(isBeforeBedtime: Bool, bedtime: Date, wakeupTime: Date, currentDate: Date) -> String {
        let calendar = Calendar.current
        let targetTime = isBeforeBedtime ? bedtime : wakeupTime
        
        let targetComponents = calendar.dateComponents([.hour, .minute], from: targetTime)
        let currentComponents = calendar.dateComponents([.hour, .minute], from: currentDate)
        
        var targetMinutes = targetComponents.hour! * 60 + targetComponents.minute!
        let currentMinutes = currentComponents.hour! * 60 + currentComponents.minute!
        
        if !isBeforeBedtime && targetMinutes < currentMinutes {
            // La cible est demain
            targetMinutes += 24 * 60
        }
        
        var minutesRemaining = targetMinutes - currentMinutes
        if minutesRemaining < 0 {
            minutesRemaining += 24 * 60
        }
        
        let hours = minutesRemaining / 60
        let minutes = minutesRemaining % 60
        
        return String(format: "%02d:%02d", hours, minutes)
    }
}

// Ajoutez cette extension pour permettre l'aperçu du widget
#Preview(as: .systemSmall) {
    SleepCountdownWidgetControl()
} timeline: {
    SleepTimerEntry(
        date: .now,
        isRunning: true,
        statusText: "Prochain : Coucher",
        timeRemaining: "02:30"
    )
    SleepTimerEntry(
        date: .now,
        isRunning: false,
        statusText: "",
        timeRemaining: ""
    )
}
