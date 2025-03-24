//
//  SleepCountdownWidget.swift
//  SleepCountdownWidget
//
//  Created by Sharik Mohamed on 10/03/2025.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline with entries every 15 minutes
        let currentDate = Date()
        for minuteOffset in stride(from: 0, to: 24 * 60, by: 15) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct SleepCountdownWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(SleepModel.isDarkMode() ? Color.black : Color.white)
            
            VStack(spacing: 8) {
                Text(SleepModel.isBeforeBedtime(currentTime: entry.date) ? "Time until bedtime" : "Time until wake-up")
                    .font(.caption)
                    .foregroundColor(SleepModel.isDarkMode() ? .white : .black)
                
                Text(SleepModel.getTimeRemaining(currentTime: entry.date))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(SleepModel.getAccentColor())
                
                Text(SleepModel.getTargetTimeFormatted())
                    .font(.caption2)
                    .foregroundColor(SleepModel.isDarkMode() ? .white.opacity(0.7) : .black.opacity(0.7))
            }
            .padding()
        }
    }
}

struct SleepCountdownWidget: Widget {
    let kind: String = "SleepCountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SleepCountdownWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Sleep Countdown")
        .description("Shows time until bedtime or wake-up.")
        .supportedFamilies([.systemSmall])
    }
}

struct SleepCountdownWidget_Previews: PreviewProvider {
    static var previews: some View {
        SleepCountdownWidgetEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
