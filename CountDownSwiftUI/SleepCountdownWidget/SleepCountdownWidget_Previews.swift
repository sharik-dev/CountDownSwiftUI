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
        // Preview du petit widget en mode nuit
        SleepCountdownWidgetEntryView(entry: SleepEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Small Widget - Night Mode")
        
        // Preview du widget moyen en mode jour
        SleepCountdownWidgetEntryView(entry: SleepEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .environment(\.colorScheme, .light)
            .previewDisplayName("Medium Widget - Day Mode")
        
        // Preview du mode alerte
        SleepCountdownWidgetEntryView(entry: SleepEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Alert Mode")
    }
} 