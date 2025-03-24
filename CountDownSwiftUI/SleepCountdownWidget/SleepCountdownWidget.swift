//
//  SleepCountdownWidget.swift
//  SleepCountdownWidget
//
//  Created by Sharik Mohamed on 24/03/2025.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SleepEntry {
        SleepEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SleepEntry) -> ()) {
        let entry = SleepEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepEntry>) -> ()) {
        var entries: [SleepEntry] = []

        // Generate a timeline with entries every 15 minutes
        let currentDate = Date()
        for minuteOffset in stride(from: 0, to: 24 * 60, by: 15) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = SleepEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SleepEntry: TimelineEntry {
    let date: Date
}

struct SleepCountdownWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry
    
    // Get data from UserDefaults
    var bedtime: Date {
        UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")?.object(forKey: "bedtime") as? Date ?? 
            Calendar.current.date(from: DateComponents(hour: 22, minute: 0))!
    }
    
    var wakeupTime: Date {
        UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")?.object(forKey: "wakeupTime") as? Date ?? 
            Calendar.current.date(from: DateComponents(hour: 7, minute: 0))!
    }
    
    var isDarkMode: Bool {
        UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")?.bool(forKey: "isDarkMode") ?? false
    }
    
    var accentColor: Color {
        let colorString = UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")?.string(forKey: "accentColor") ?? "blue"
        switch colorString {
        case "red": return .red
        case "green": return .green
        case "purple": return .purple
        default: return .blue
        }
    }
    
    var isBeforeBedtime: Bool {
        let calendar = Calendar.current
        let bedComponents = calendar.dateComponents([.hour, .minute], from: bedtime)
        let wakeComponents = calendar.dateComponents([.hour, .minute], from: wakeupTime)
        let currentComponents = calendar.dateComponents([.hour, .minute], from: entry.date)
        
        let bedMinutes = bedComponents.hour! * 60 + bedComponents.minute!
        let wakeMinutes = wakeComponents.hour! * 60 + wakeComponents.minute!
        let currentMinutes = currentComponents.hour! * 60 + currentComponents.minute!
        
        if wakeMinutes < bedMinutes {
            // Wake time is on the next day
            return currentMinutes < wakeMinutes || currentMinutes >= bedMinutes
        } else {
            // Wake time is on the same day
            return currentMinutes >= wakeMinutes && currentMinutes < bedMinutes
        }
    }
    
    var timeRemainingFormatted: String {
        let calendar = Calendar.current
        let targetTime = isBeforeBedtime ? bedtime : wakeupTime
        
        let targetComponents = calendar.dateComponents([.hour, .minute], from: targetTime)
        let currentComponents = calendar.dateComponents([.hour, .minute], from: entry.date)
        
        var targetMinutes = targetComponents.hour! * 60 + targetComponents.minute!
        let currentMinutes = currentComponents.hour! * 60 + currentComponents.minute!
        
        if !isBeforeBedtime && targetMinutes < currentMinutes {
            // Target is tomorrow
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
    
    var targetTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: isBeforeBedtime ? bedtime : wakeupTime)
    }

    var body: some View {
        ZStack {
            Color(isDarkMode ? .black : .white)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: isBeforeBedtime ? "bed.double.fill" : "alarm.fill")
                        .foregroundColor(accentColor)
                    
                    Text(isBeforeBedtime ? "Bedtime in" : "Wake up in")
                        .font(.system(size: widgetFamily == .systemSmall ? 12 : 14, weight: .medium))
                        .foregroundColor(isDarkMode ? .white : .black)
                }
                
                Text(timeRemainingFormatted)
                    .font(.system(size: widgetFamily == .systemSmall ? 28 : 34, weight: .bold))
                    .foregroundColor(accentColor)
                
                Text(targetTimeFormatted)
                    .font(.system(size: widgetFamily == .systemSmall ? 10 : 12))
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
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
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
