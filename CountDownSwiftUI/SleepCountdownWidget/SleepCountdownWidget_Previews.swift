// SleepCountdownWidget_Previews.swift
// CountDownSwiftUI
//
// Created by Sharik Mohamed on 24/03/2025.
//

import SwiftUI
import WidgetKit

// 🖌️ PREVIEWS DU WIDGET POUR LE DÉVELOPPEMENT
struct SleepCountdownWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview du petit widget en mode nuit
            SleepCountdownWidgetEntryView(entry: SleepEntry(date: Date()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Petit Widget - Mode Nuit")
            
            // Preview du widget moyen en mode jour
            SleepCountdownWidgetEntryView(entry: SleepEntry(date: Date()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .environment(\.colorScheme, .light)
                .previewDisplayName("Widget Moyen - Mode Jour")
            
            // Preview du mode alerte
            SleepCountdownWidgetEntryView(entry: SleepEntry(date: Date()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Mode Alerte")
                
            // Ajouter des previews pour différentes tailles d'écran
            SleepCountdownWidgetEntryView(entry: SleepEntry(date: Date()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDevice("iPhone SE (3rd generation)")
                .previewDisplayName("iPhone SE")
                
            SleepCountdownWidgetEntryView(entry: SleepEntry(date: Date()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDevice("iPhone 15 Pro Max")
                .previewDisplayName("iPhone 15 Pro Max")
        }
    }
} 