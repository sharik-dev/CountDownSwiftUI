//
//  CountDownSwiftUIApp.swift
//  CountDownSwiftUI
//
//  Created by Sharik Mohamed on 10/03/2025.
//

import SwiftUI
import WidgetKit
import DesignSystemKit
import UIKit

@main
struct CountDownSwiftUIApp: App {
    let persistenceController = PersistenceController.shared
    
    // Initialise le correctif pour le mode sombre
  
    init() {
        // Setup shared UserDefaults for app and widget
        setupSharedDefaults()
        
        // Forcer l'application entière en mode sombre
        UIWindow.appearance().overrideUserInterfaceStyle = .dark
        
        // Configuration des tableaux (listes) pour le mode sombre
        UITableView.appearance().backgroundColor = .black
        UITableViewCell.appearance().backgroundColor = .black
        
        // Configuration des contrôles de date et pickers
        UIDatePicker.appearance().overrideUserInterfaceStyle = .dark
        UIPickerView.appearance().overrideUserInterfaceStyle = .dark
        
        // Forcer le mode sombre pour les écrans de forme
        UINavigationBar.appearance().overrideUserInterfaceStyle = .dark
        UIScrollView.appearance().backgroundColor = .black
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.dsTheme, createTheme())
                .preferredColorScheme(.dark) // Forcer le mode sombre ici aussi
        }
    }
    
    private func createTheme() -> DSTheme {
        // Récupérer la préférence de couleur d'accentuation depuis UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")
        let accentColorString = sharedDefaults?.string(forKey: "accentColor") ?? "blue"
        // Forcer le mode sombre quoi qu'il arrive
        let isDarkMode = true
        
        // Créer la couleur d'accentuation
        let accentColor: Color
        switch accentColorString {
        case "blue":
            accentColor = Color(red: 0/255, green: 150/255, blue: 200/255)
        case "red":
            accentColor = Color(red: 255/255, green: 85/255, blue: 85/255)
        case "green":
            accentColor = Color(red: 50/255, green: 200/255, blue: 80/255)
        case "purple":
            accentColor = Color(red: 189/255, green: 147/255, blue: 249/255)
        default:
            accentColor = Color(red: 0/255, green: 150/255, blue: 200/255)
        }
        
        // Créer les couleurs de thème - toujours en mode sombre
        let backgroundColor = Color(red: 40/255, green: 42/255, blue: 54/255)
        let textColor = Color(red: 248/255, green: 248/255, blue: 242/255)
        
        return DSTheme(
            colors: DSTheme.Colors(
                primary: accentColor,
                secondary: Color(red: 98/255, green: 114/255, blue: 164/255),
                background: backgroundColor,
                text: textColor
            ),
            typography: DSTheme.Typography(
                title: .system(size: 20, weight: .bold),
                body: .system(size: 16, weight: .regular),
                caption: .system(size: 12, weight: .medium)
            )
        )
    }
    
    private func setupSharedDefaults() {
        // S'assurer que nous avons un groupe d'applications partagé pour le widget
        if let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI") {
            // Transférer les valeurs existantes des paramètres par défaut de l'application aux paramètres partagés
            if let bedtime = UserDefaults.standard.object(forKey: "bedtime") as? Date {
                sharedDefaults.set(bedtime, forKey: "bedtime")
            } else {
                // Définir l'heure de coucher par défaut si aucune n'existe (22h00)
                let defaultBedtime = Calendar.current.date(from: DateComponents(hour: 22, minute: 0))!
                sharedDefaults.set(defaultBedtime, forKey: "bedtime")
            }
            
            if let wakeupTime = UserDefaults.standard.object(forKey: "wakeupTime") as? Date {
                sharedDefaults.set(wakeupTime, forKey: "wakeupTime")
            } else {
                // Définir l'heure de réveil par défaut si aucune n'existe (7h00)
                let defaultWakeupTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0))!
                sharedDefaults.set(defaultWakeupTime, forKey: "wakeupTime")
            }
            
            // Transférer ou définir la valeur par défaut pour la préférence du mode sombre
            let isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
            sharedDefaults.set(isDarkMode, forKey: "isDarkMode")
            
            // Transférer ou définir la valeur par défaut pour la couleur d'accentuation
            if let accentColor = UserDefaults.standard.string(forKey: "accentColor") {
                sharedDefaults.set(accentColor, forKey: "accentColor")
            } else {
                sharedDefaults.set("blue", forKey: "accentColor")
            }
            
            // Définir l'état par défaut du minuteur en cours d'exécution s'il n'existe pas
            if !sharedDefaults.contains(key: "timerRunning") {
                sharedDefaults.set(false, forKey: "timerRunning")
            }
            
            // Synchroniser pour garantir que les modifications sont enregistrées
            sharedDefaults.synchronize()
            
            // Actualiser les widgets pour refléter les modifications
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            print("Erreur: Impossible d'accéder aux UserDefaults partagés. Les fonctionnalités du widget peuvent être limitées.")
        }
    }
}

// Extension to check if a key exists in UserDefaults
extension UserDefaults {
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
}

// Extension pour forcer le mode sombre dans les listes
extension View {
    func forceDarkMode() -> some View {
        self.onAppear {
            // Force tous les éléments UI en mode sombre
            UITableView.appearance().backgroundColor = .black
            UITableViewCell.appearance().backgroundColor = .black
            UIDatePicker.appearance().overrideUserInterfaceStyle = .dark
            UIView.appearance().overrideUserInterfaceStyle = .dark
        }
    }
}
