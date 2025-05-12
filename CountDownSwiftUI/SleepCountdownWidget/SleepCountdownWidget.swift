//
//  SleepCountdownWidget.swift
//  SleepCountdownWidget
//
//  Created by Sharik Mohamed on 24/03/2025.
//

import WidgetKit
import SwiftUI
import UIKit

// Nous utilisons la classe BackgroundImageManager au lieu de cette classe locale

// Renommer Provider pour éviter les conflits
struct SleepCountdownProvider: TimelineProvider {
    typealias Entry = SleepEntry
    
    init() {
        // Observer les notifications de l'application pour mettre à jour le widget
        NotificationCenter.default.addObserver(forName: NSNotification.Name("RefreshWidget"), 
                                              object: nil, 
                                              queue: .main) { _ in
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func placeholder(in context: Context) -> SleepEntry {
        SleepEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SleepEntry) -> ()) {
        // Forcer un rechargement immédiat du widget
        let entry = SleepEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepEntry>) -> ()) {
        var entries: [SleepEntry] = []

        // Génération d'entrées moins fréquentes
        let currentDate = Date()
        
        // Arrondir à la minute la plus proche pour commencer
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)
        let startDate = calendar.date(bySettingHour: components.hour ?? 0,
                                    minute: components.minute ?? 0,
                                    second: 0,
                                    of: currentDate) ?? currentDate
        
        // Créer un nombre réduit d'entrées avec des intervalles plus longs
        // 5 entrées à 1 minute d'intervalle (au lieu de 10 entrées à 10 secondes)
        for i in 0..<5 {
            let entryDate = calendar.date(byAdding: .minute, value: i, to: startDate)!
            let entry = SleepEntry(date: entryDate)
            entries.append(entry)
        }

        // Demander une mise à jour après une période plus longue
        let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!))
        completion(timeline)
    }
}

struct SleepCountdownWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: SleepCountdownProvider.Entry
    @State private var alertIconOpacity: Double = 1.0
    @State private var opacity: Double = 1.0
    
    // Utiliser les valeurs de l'entrée
    var bedtime: Date { entry.bedtime }
    var wakeupTime: Date { entry.wakeupTime }
    var isDarkMode: Bool { entry.isDarkMode }
    
    // Utiliser les valeurs personnalisables
    var bedtimeIcon: String { entry.bedtimeIcon }
    var wakeupIcon: String { entry.wakeupIcon }
    var alertIcon: String { entry.alertIcon }
    var bedtimeText: String { entry.bedtimeText }
    var wakeupText: String { entry.wakeupText }
    var alertText: String { entry.alertText }
    
    var accentColor: Color {
        switch entry.accentColorString {
        case "red": return .red
        case "green": return .green
        case "purple": return .purple
        default: return .blue
        }
    }
    
    var isBeforeBedtime: Bool {
        let calendar = Calendar.current
        let now = entry.date
        
        // On utilise le calendrier pour normaliser les dates avec le même jour pour une comparaison correcte
        let today = calendar.startOfDay(for: now)
        
        // Créer des dates complètes pour aujourd'hui
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
        
        // Retourner vrai si le temps jusqu'au coucher est plus court
        return secondsToBedtime < secondsToWakeup
    }
    
    var timeRemainingFormatted: String {
        let calendar = Calendar.current
        
        // On utilise le calendrier pour normaliser les dates avec le même jour pour une comparaison correcte
        let today = calendar.startOfDay(for: entry.date)
        
        // Créer des dates complètes pour aujourd'hui et demain
        var targetDate = calendar.date(bySettingHour: calendar.component(.hour, from: isBeforeBedtime ? bedtime : wakeupTime),
                                     minute: calendar.component(.minute, from: isBeforeBedtime ? bedtime : wakeupTime),
                                     second: 0,
                                     of: today)!
        
        // Si l'heure cible est déjà passée, ajouter un jour
        if targetDate < entry.date {
            targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate)!
        }
        
        // Calculer la différence
        let timeRemaining = targetDate.timeIntervalSince(entry.date)
        
        // Formater avec les heures et minutes uniquement
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        
        return String(format: "%dh %02dm", hours, minutes)
    }
    
    var targetTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: isBeforeBedtime ? bedtime : wakeupTime)
    }

    // 🖌️ UI DU WIDGET - DÉBUT
    var body: some View {
        // Utiliser un conteneur transparent pour que la couleur s'étende aux bords
        GeometryReader { geometry in
            Color.clear
                .overlay(
                    ZStack {
                        // Fond coloré qui occupe tout l'espace
                        backgroundColor
                            .opacity(timeIsRunningOut() && !isBeforeBedtime ? opacity : 1.0)
                            .onAppear {
                                if timeIsRunningOut() && !isBeforeBedtime {
                                    withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                        opacity = 0.6
                                    }
                                }
                            }
                            .edgesIgnoringSafeArea(.all)
                        
                        // Interface principale qui diffère selon la taille du widget
                        if widgetFamily == .systemSmall {
                            smallWidget
                        } else {
                            mediumWidget
                        }
                    }
                )
        }
        .widgetBackground(backgroundColor: backgroundColor)
    }
    
    // Version simplifiée pour petit widget
    var smallWidget: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                
                Text(titleText)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.7)
            }
            .padding(.top, 2)
            
            // Utilisation de GeometryReader pour adapter la taille du texte
            GeometryReader { geometry in
                Text(timeRemainingFormatted)
                    .font(.system(size: min(geometry.size.width / 6, 32), weight: .bold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            }
            .frame(height: 30)
            
            Text(subtitleText)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
                .foregroundColor(.white.opacity(0.7))
                .minimumScaleFactor(0.7)
                .padding(.bottom, 2)
        }
        .padding(8)
    }
    
    // Version complète pour widget medium
    var mediumWidget: some View {
        GeometryReader { geo in
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                    
                    Text(titleText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.7)
                }
                .padding(.top, 4)
                
                // Utilisation de GeometryReader pour adapter la taille du texte
                Text(timeRemainingFormatted)
                    .font(.system(size: min(geo.size.width / 7, 42), weight: .bold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                
                Text(subtitleText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .padding(10)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
    
    // Fonction pour les éléments décoratifs - SUPPRIMÉE
    func decorations(geometry: GeometryProxy) -> some View {
        // Remplacer par EmptyView pour supprimer le point d'exclamation en arrière-plan
        return EmptyView()
    }
    // 🖌️ UI DU WIDGET - FIN
    
    // Propriétés calculées pour le texte et les couleurs
    var backgroundColor: Color {
        if timeIsRunningOut() && !isBeforeBedtime {
            return Color.red
        } else if isDarkMode {
            return Color.black
        } else {
            return accentColor
        }
    }
    
    var iconName: String {
        if isBeforeBedtime {
            return bedtimeIcon
        } else if timeIsRunningOut() {
            return alertIcon
        } else {
            return wakeupIcon
        }
    }
    
    var titleText: String {
        if isBeforeBedtime {
            return bedtimeText
        } else if timeIsRunningOut() {
            return alertText
        } else {
            return wakeupText
        }
    }
    
    var subtitleText: String {
        if timeIsRunningOut() && !isBeforeBedtime {
            return ""
        } else {
            return targetTimeFormatted
        }
    }
    
    // Calculer la progression pour la barre de progression
    func getProgress() -> Double {
        let calendar = Calendar.current
        let now = entry.date
        
        // On utilise le calendrier pour normaliser les dates avec le même jour pour une comparaison correcte
        let today = calendar.startOfDay(for: now)
        
        // Créer une date complète pour aujourd'hui
        var targetDate = calendar.date(bySettingHour: calendar.component(.hour, from: isBeforeBedtime ? bedtime : wakeupTime),
                                     minute: calendar.component(.minute, from: isBeforeBedtime ? bedtime : wakeupTime),
                                     second: 0,
                                     of: today)!
        
        // Si l'heure cible est déjà passée, ajouter un jour
        if targetDate < now {
            targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate)!
        }
        
        // Calculer la différence en secondes
        let totalSeconds = calendar.dateComponents([.second], from: now, to: targetDate).second ?? 0
        
        // Supposons une période maximale de 24 heures (86400 secondes)
        let maxSeconds = 24 * 3600
        
        // Inverser pour avoir une progression croissante (de 0 à 1)
        return 1.0 - (Double(totalSeconds) / Double(maxSeconds))
    }
    
    // Vérifie si l'heure du coucher est dépassée de 30 minutes
    func timeIsRunningOut() -> Bool {
        if isBeforeBedtime {
            return false // Pas d'alerte avant l'heure du coucher
        }
        
        let calendar = Calendar.current
        
        // Obtenir l'heure de coucher pour aujourd'hui
        var bedtimeComponents = calendar.dateComponents([.year, .month, .day], from: entry.date)
        let bedtimeTimeComponents = calendar.dateComponents([.hour, .minute], from: bedtime)
        bedtimeComponents.hour = bedtimeTimeComponents.hour
        bedtimeComponents.minute = bedtimeTimeComponents.minute
        let bedtimeToday = calendar.date(from: bedtimeComponents)!
        
        // Ajouter 30 minutes à l'heure du coucher
        let bedtimePlusThirtyMin = calendar.date(byAdding: .minute, value: 30, to: bedtimeToday)!
        
        // Vérifier si l'heure actuelle est après l'heure du coucher + 30 min
        // mais avant l'heure du réveil
        let isAfterBedtimePlusThirty = entry.date > bedtimePlusThirtyMin
        
        // Vérifier si le coucher était hier (si on est dans une nouvelle journée)
        let isNewDay = bedtimeToday > entry.date
        
        // Si c'est une nouvelle journée, vérifier si on est dans les 30 minutes après minuit
        let isWithinThirtyMinAfterMidnight = isNewDay && (calendar.dateComponents([.hour, .minute], from: entry.date).hour! * 60 + calendar.dateComponents([.hour, .minute], from: entry.date).minute! < 30)
        
        // L'alerte s'affiche seulement si on est après l'heure du coucher + 30 min
        // ou si c'est une nouvelle journée et on est dans les 30 minutes après minuit
        return isAfterBedtimePlusThirty || isWithinThirtyMinAfterMidnight
    }
    
    // Calcule le nombre d'heures de sommeil restantes
    func hoursSleepRemaining() -> String {
        let calendar = Calendar.current
        
        // Calcul similaire à timeIsRunningOut mais retourne les heures restantes
        let wakeComponents = calendar.dateComponents([.hour, .minute], from: wakeupTime)
        let currentComponents = calendar.dateComponents([.hour, .minute], from: entry.date)
        
        let currentMinutes = currentComponents.hour! * 60 + currentComponents.minute!
        let wakeMinutes = wakeComponents.hour! * 60 + wakeComponents.minute!
        
        let minutesToWakeup = wakeMinutes < currentMinutes ? 
            (wakeMinutes + 24 * 60) - currentMinutes : 
            wakeMinutes - currentMinutes
        
        let hours = minutesToWakeup / 60
        let minutes = minutesToWakeup % 60
        
        // Format pour le texte d'alerte - simplifié
        if hours > 0 {
            return String(format: "%dh%dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
}

struct SleepCountdownWidget: Widget {
    let kind: String = "SleepCountdownWidget"
    
    // Pour suivre la dernière mise à jour et éviter des rendus trop fréquents
    static var lastRefresh: Date = Date()
    static let minRefreshInterval: TimeInterval = 10 // minimum 10 secondes entre les mises à jour

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepCountdownProvider()) { entry in
            // Vérifier si le widget a été mis à jour récemment
            let now = Date()
            let shouldRefresh = now.timeIntervalSince(SleepCountdownWidget.lastRefresh) >= SleepCountdownWidget.minRefreshInterval
            
            if shouldRefresh {
                SleepCountdownWidget.lastRefresh = now
                
                let entryView = SleepCountdownWidgetEntryView(entry: entry)
                let needsPulse = entryView.timeIsRunningOut() && !entryView.isBeforeBedtime
                
                return entryView
                    .pulseIfNeeded(isActive: needsPulse)
                    .widgetBackground(backgroundColor: entryView.backgroundColor)
            } else {
                // Renvoyer une vue simple si la mise à jour est trop fréquente
                let entryView = SleepCountdownWidgetEntryView(entry: entry)
                let needsPulse = entryView.timeIsRunningOut() && !entryView.isBeforeBedtime
                
                return entryView
                    .pulseIfNeeded(isActive: needsPulse)
                    .widgetBackground(backgroundColor: entryView.backgroundColor)
            }
        }
        .configurationDisplayName("Compte à rebours sommeil")
        .description("Affiche le temps jusqu'au coucher ou réveil.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Extension pour appliquer le fond qui remplit tout l'espace
extension View {
    func widgetBackground(backgroundColor: Color) -> some View {
        if #available(iOS 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundColor
            }
        } else {
            return background(backgroundColor)
        }
    }
    
    // Effet de pulsation
    func pulseIfNeeded(isActive: Bool) -> some View {
        modifier(PulseViewModifier(isActive: isActive))
    }
}

// Modificateur pour l'effet de pulsation
struct PulseViewModifier: ViewModifier {
    let isActive: Bool
    @State private var opacity: Double = 1.0
    
    func body(content: Content) -> some View {
        if isActive {
            content
                .opacity(opacity)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        opacity = 0.6
                    }
                }
        } else {
            content
        }
    }
}

// Aide pour éviter les problèmes d'URL dans les groupes d'applications
extension URL {
    // Corrige les problèmes potentiels avec les URLs
    func normalizedURL() -> URL {
        // Assurons-nous que l'URL est correctement formée
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        
        // Assurons-nous que nous avons un chemin correct
        if !components.path.isEmpty && !components.path.hasPrefix("/") {
            components.path = "/" + components.path
        }
        
        return components.url ?? self
    }
}
