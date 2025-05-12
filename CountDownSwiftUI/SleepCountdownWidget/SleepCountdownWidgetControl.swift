//
//  SleepCountdownWidgetControl.swift
//  SleepCountdownWidget
//
//  Created by Sharik Mohamed on 24/03/2025.
//

import AppIntents
import SwiftUI
import WidgetKit
import ActivityKit

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

class SleepActivityManager: ObservableObject {
    @Published var isActivityActive = false
    private var activity: Activity<SleepCountdownWidgetAttributes>?
    
    init() {
        // Vérifier s'il existe déjà une activité active
        if let currentActivity = Activity<SleepCountdownWidgetAttributes>.activities.first {
            self.activity = currentActivity
            self.isActivityActive = true
        }
    }
    
    // Démarre l'activité lorsque appelé depuis l'application principale
    func startActivityFromView(bedtime: Date, wakeupTime: Date) {
        // Récupérer les paramètres personnalisables depuis UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.tempest.CountDownSwiftUI")
        let bedtimeIcon = defaults?.string(forKey: "bedtimeIcon") ?? "bed.double.fill"
        let wakeupIcon = defaults?.string(forKey: "wakeupIcon") ?? "alarm.fill"
        let alertIcon = defaults?.string(forKey: "alertIcon") ?? "exclamationmark.triangle.fill"
        let bedtimeText = defaults?.string(forKey: "bedtimeText") ?? "Time until bedtime"
        let wakeupText = defaults?.string(forKey: "wakeupText") ?? "Time until wake-up"
        let alertText = defaults?.string(forKey: "alertText") ?? "Sleep time running out!"
        
        // Calculer l'heure actuelle et les paramètres
        let now = Date()
        let calendar = Calendar.current
        
        // Normaliser les heures pour aujourd'hui
        let today = calendar.startOfDay(for: now)
        var bedtimeToday = calendar.date(bySettingHour: calendar.component(.hour, from: bedtime),
                                      minute: calendar.component(.minute, from: bedtime),
                                      second: 0,
                                      of: today)!
        
        var wakeupToday = calendar.date(bySettingHour: calendar.component(.hour, from: wakeupTime),
                                     minute: calendar.component(.minute, from: wakeupTime),
                                     second: 0,
                                     of: today)!
        
        // Si l'heure est déjà passée, ajouter un jour
        if bedtimeToday < now {
            bedtimeToday = calendar.date(byAdding: .day, value: 1, to: bedtimeToday)!
        }
        
        if wakeupToday < now {
            wakeupToday = calendar.date(byAdding: .day, value: 1, to: wakeupToday)!
        }
        
        // Calculer les différences en secondes
        let secondsToBedtime = calendar.dateComponents([.second], from: now, to: bedtimeToday).second ?? 0
        let secondsToWakeup = calendar.dateComponents([.second], from: now, to: wakeupToday).second ?? 0
        
        // Déterminer si nous montrons le compte à rebours avant le coucher ou avant le réveil
        let isBeforeBedtime = secondsToBedtime < secondsToWakeup
        let isSleepingPeriod = !isBeforeBedtime
        
        // Calculer le temps restant et la progression
        let timeRemaining = isBeforeBedtime ? Double(secondsToBedtime) : Double(secondsToWakeup)
        let maxTimeInSeconds = 24 * 3600.0 // 24 heures en secondes
        let progress = 1.0 - (timeRemaining / maxTimeInSeconds)
        
        // Créer les attributs pour l'activité
        let attributes = SleepCountdownWidgetAttributes(
            name: "Sleep Timer",
            bedtime: bedtime,
            wakeupTime: wakeupTime,
            startTime: now,
            endTime: isBeforeBedtime ? bedtimeToday : wakeupToday
        )
        
        // Créer l'état initial de l'activité
        let initialState = SleepCountdownWidgetAttributes.ContentState(
            timeRemaining: timeRemaining,
            isBeforeBedtime: isBeforeBedtime,
            isSleepingPeriod: isSleepingPeriod,
            progress: progress,
            bedtimeIcon: bedtimeIcon,
            wakeupIcon: wakeupIcon,
            alertIcon: alertIcon,
            bedtimeText: bedtimeText,
            wakeupText: wakeupText,
            alertText: alertText
        )
        
        do {
            self.activity = try Activity.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            self.isActivityActive = true
            
            // Démarrer les mises à jour régulières
            startUpdatingActivity()
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    // Met à jour l'activité avec le temps restant actuel
    private func updateActivity() {
        guard let activity = self.activity else { return }
        
        // Récupérer les attributs actuels
        let attributes = activity.attributes
        let bedtime = attributes.bedtime
        let wakeupTime = attributes.wakeupTime
        
        // Récupérer les paramètres personnalisables depuis UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.tempest.CountDownSwiftUI")
        let bedtimeIcon = defaults?.string(forKey: "bedtimeIcon") ?? "bed.double.fill"
        let wakeupIcon = defaults?.string(forKey: "wakeupIcon") ?? "alarm.fill"
        let alertIcon = defaults?.string(forKey: "alertIcon") ?? "exclamationmark.triangle.fill"
        let bedtimeText = defaults?.string(forKey: "bedtimeText") ?? "Time until bedtime"
        let wakeupText = defaults?.string(forKey: "wakeupText") ?? "Time until wake-up"
        let alertText = defaults?.string(forKey: "alertText") ?? "Sleep time running out!"
        
        // Calculer l'heure actuelle et les paramètres
        let now = Date()
        let calendar = Calendar.current
        
        // Normaliser les heures pour aujourd'hui
        let today = calendar.startOfDay(for: now)
        var bedtimeToday = calendar.date(bySettingHour: calendar.component(.hour, from: bedtime),
                                      minute: calendar.component(.minute, from: bedtime),
                                      second: 0,
                                      of: today)!
        
        var wakeupToday = calendar.date(bySettingHour: calendar.component(.hour, from: wakeupTime),
                                     minute: calendar.component(.minute, from: wakeupTime),
                                     second: 0,
                                     of: today)!
        
        // Si l'heure est déjà passée, ajouter un jour
        if bedtimeToday < now {
            bedtimeToday = calendar.date(byAdding: .day, value: 1, to: bedtimeToday)!
        }
        
        if wakeupToday < now {
            wakeupToday = calendar.date(byAdding: .day, value: 1, to: wakeupToday)!
        }
        
        // Calculer les différences en secondes
        let secondsToBedtime = calendar.dateComponents([.second], from: now, to: bedtimeToday).second ?? 0
        let secondsToWakeup = calendar.dateComponents([.second], from: now, to: wakeupToday).second ?? 0
        
        // Déterminer si nous montrons le compte à rebours avant le coucher ou avant le réveil
        let isBeforeBedtime = secondsToBedtime < secondsToWakeup
        let isSleepingPeriod = !isBeforeBedtime
        
        // Calculer le temps restant et la progression
        let timeRemaining = isBeforeBedtime ? Double(secondsToBedtime) : Double(secondsToWakeup)
        let maxTimeInSeconds = 24 * 3600.0 // 24 heures en secondes
        let progress = 1.0 - (timeRemaining / maxTimeInSeconds)
        
        // Si le temps est écoulé, terminer l'activité
        if timeRemaining <= 0 {
            Task {
                await activity.end(
                    ActivityContent(
                        state: activity.contentState,
                        staleDate: nil
                    ),
                    dismissalPolicy: .immediate
                )
                DispatchQueue.main.async {
                    self.isActivityActive = false
                    self.activity = nil
                }
            }
            return
        }
        
        // Créer le nouvel état
        let updatedState = SleepCountdownWidgetAttributes.ContentState(
            timeRemaining: timeRemaining,
            isBeforeBedtime: isBeforeBedtime,
            isSleepingPeriod: isSleepingPeriod,
            progress: progress,
            bedtimeIcon: bedtimeIcon,
            wakeupIcon: wakeupIcon,
            alertIcon: alertIcon,
            bedtimeText: bedtimeText,
            wakeupText: wakeupText,
            alertText: alertText
        )
        
        // Mettre à jour l'activité
        Task {
            await activity.update(
                ActivityContent(
                    state: updatedState,
                    staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date())
                )
            )
        }
    }
    
    // Met à jour l'activité toutes les 10 secondes
    private func startUpdatingActivity() {
        guard isActivityActive else { return }
        
        // Mettre à jour immédiatement
        updateActivity()
        
        // Puis programmer une mise à jour toutes les 10 secondes
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.startUpdatingActivity()
        }
    }
    
    // Termine l'activité
    func endActivityFromView() {
        guard let activity = self.activity else { return }
        
        Task {
            await activity.end(
                ActivityContent(
                    state: activity.contentState,
                    staleDate: nil
                ),
                dismissalPolicy: .immediate
            )
            
            DispatchQueue.main.async {
                self.isActivityActive = false
                self.activity = nil
            }
        }
    }
}
