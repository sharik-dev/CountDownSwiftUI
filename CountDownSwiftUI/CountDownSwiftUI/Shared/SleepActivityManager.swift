//
//  SleepActivityManager.swift
//  CountDownSwiftUI
//
//  Created by User on 24/03/2025.
//

import ActivityKit
import Foundation

struct SleepCountdownWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var timeRemaining: TimeInterval
        var isBeforeBedtime: Bool
        var isSleepingPeriod: Bool
        var progress: Double
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
    var bedtime: Date
    var wakeupTime: Date
    var startTime: Date
    var endTime: Date
}
//
//  SleepActivityManager.swift
//  CountDownSwiftUI
//
//  Created by User on 24/03/2025.
//

import ActivityKit
import Foundation
import SwiftUI

class SleepActivityManager: ObservableObject {
    
    @Published var activity: Activity<SleepCountdownWidgetAttributes>?
    @Published var isActivityActive = false
    
    private var timer: Timer?
    
    init() {
        // Vérifier s'il y a des activités en cours au démarrage
        checkForRunningActivities()
    }
    
    private func checkForRunningActivities() {
        if #available(iOS 16.1, *) {
            for activity in Activity<SleepCountdownWidgetAttributes>.activities {
                self.activity = activity
                self.isActivityActive = true
                startUpdateTimer()
                break
            }
        }
    }
    
    func startActivity(bedtime: Date, wakeupTime: Date) {
        guard #available(iOS 16.1, *) else {
            print("Live Activities ne sont pas disponibles sur cette version d'iOS")
            return
        }
        
        // Vérifier si une activité est déjà en cours
        if isActivityActive {
            print("Une activité est déjà en cours")
            return
        }
        
        let now = Date()
        
        let attributes = SleepCountdownWidgetAttributes(
            name: "Sleep Timer",
            bedtime: bedtime,
            wakeupTime: wakeupTime,
            startTime: now,
            endTime: wakeupTime
        )
        
        // Déterminer l'état initial
        let initialState = createContentState(now: now, attributes: attributes)
        
        do {
            activity = try Activity.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            isActivityActive = true
            print("Activité de sommeil démarrée avec succès")
            
            // Démarrer le timer pour les mises à jour
            startUpdateTimer()
        } catch {
            print("Erreur lors du démarrage de l'activité: \(error.localizedDescription)")
        }
    }
    
    private func startUpdateTimer() {
        // Arrêter le timer existant s'il y en a un
        timer?.invalidate()
        
        // Créer un nouveau timer qui met à jour l'activité toutes les secondes
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateActivity()
        }
    }
    
    func updateActivity() {
        guard let activity = activity else { return }
        
        let now = Date()
        let updatedState = createContentState(now: now, attributes: activity.attributes)
        
        Task {
            await activity.update(using: updatedState)
        }
    }
    
    private func createContentState(now: Date, attributes: SleepCountdownWidgetAttributes) -> SleepCountdownWidgetAttributes.ContentState {
        let isSleepingPeriod = now > attributes.bedtime && now < attributes.wakeupTime
        
        // Calcul du temps restant
        let timeRemaining: TimeInterval
        if isSleepingPeriod {
            // Pendant la période de sommeil, afficher le temps jusqu'au réveil
            timeRemaining = attributes.wakeupTime.timeIntervalSince(now)
        } else {
            // En dehors de la période de sommeil, afficher le temps jusqu'au coucher
            // Si on est après le réveil, calculer jusqu'au prochain coucher
            if now < attributes.bedtime {
                timeRemaining = attributes.bedtime.timeIntervalSince(now)
            } else {
                // Ajouter 24h pour obtenir le prochain coucher
                let nextBedtime = Calendar.current.date(byAdding: .day, value: 1, to: attributes.bedtime)!
                timeRemaining = nextBedtime.timeIntervalSince(now)
            }
        }
        
        // Calcul de la progression
        let progress = calculateProgress(now: now, attributes: attributes, isSleepingPeriod: isSleepingPeriod)
        
        return SleepCountdownWidgetAttributes.ContentState(
            timeRemaining: timeRemaining,
            isBeforeBedtime: !isSleepingPeriod,
            isSleepingPeriod: isSleepingPeriod,
            progress: progress
        )
    }
    
    private func calculateProgress(now: Date, attributes: SleepCountdownWidgetAttributes, isSleepingPeriod: Bool) -> Double {
        if isSleepingPeriod {
            // Pendant la période de sommeil
            let totalSleepTime = attributes.wakeupTime.timeIntervalSince(attributes.bedtime)
            let elapsedSleepTime = now.timeIntervalSince(attributes.bedtime)
            return min(1.0, max(0.0, Double(elapsedSleepTime) / Double(totalSleepTime)))
        } else {
            // Avant le coucher ou après le réveil
            if now < attributes.bedtime {
                // Avant le coucher
                let totalWakeTime = attributes.bedtime.timeIntervalSince(attributes.wakeupTime)
                let elapsedWakeTime = now.timeIntervalSince(attributes.wakeupTime)
                return min(1.0, max(0.0, Double(elapsedWakeTime) / Double(totalWakeTime)))
            } else {
                // Après le réveil, avant le prochain coucher
                let nextBedtime = Calendar.current.date(byAdding: .day, value: 1, to: attributes.bedtime)!
                let totalWakeTime = nextBedtime.timeIntervalSince(attributes.wakeupTime)
                let elapsedWakeTime = now.timeIntervalSince(attributes.wakeupTime)
                return min(1.0, max(0.0, Double(elapsedWakeTime) / Double(totalWakeTime)))
            }
        }
    }
    
    func endActivity() {
        guard let activity = activity else { return }
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
            self.activity = nil
            self.isActivityActive = false
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

// Extension pour faciliter l'utilisation dans SwiftUI
extension SleepActivityManager {
    func startActivityFromView(bedtime: Date, wakeupTime: Date) {
        startActivity(bedtime: bedtime, wakeupTime: wakeupTime)
    }
    
    func endActivityFromView() {
        endActivity()
    }
}
