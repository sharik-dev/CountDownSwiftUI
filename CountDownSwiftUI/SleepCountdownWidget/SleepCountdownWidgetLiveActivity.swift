//
//  SleepCountdownWidgetLiveActivity.swift
//  SleepCountdownWidget
//
//  Created by Sharik Mohamed on 24/03/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI


struct SleepCountdownWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timeRemaining: TimeInterval
        var isBeforeBedtime: Bool
        var isSleepingPeriod: Bool
        var progress: Double
        
        // Ajout des textes et icônes personnalisables
        var bedtimeIcon: String
        var wakeupIcon: String
        var alertIcon: String
        var bedtimeText: String
        var wakeupText: String
        var alertText: String
    }

    var name: String
    var bedtime: Date
    var wakeupTime: Date
    var startTime: Date
    var endTime: Date
}

struct SleepCountdownWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SleepCountdownWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                HStack {
                    Image(systemName: context.state.isSleepingPeriod ? context.state.wakeupIcon : context.state.bedtimeIcon)
                        .foregroundStyle(.white)
                    
                    Text(context.state.isSleepingPeriod ? context.state.wakeupText : context.state.bedtimeText)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Utilisation du texte responsif
                    responsiveTimeText(formatTimeInterval(context.state.timeRemaining))
                        .frame(width: 130, height: 30)
                }
                
                ProgressView(value: context.state.progress)
                    .progressViewStyle(.linear)
                    .tint(.white)
            }
            .padding()
            .activityBackgroundTint(context.state.isSleepingPeriod ? Color.blue : Color.indigo)
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Image(systemName: context.state.isSleepingPeriod ? context.state.wakeupIcon : context.state.bedtimeIcon)
                            .foregroundStyle(context.state.isSleepingPeriod ? .blue : .indigo)
                        Text(context.state.isSleepingPeriod ? "Réveil" : "Coucher")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(formatTimeInterval(context.state.timeRemaining))
                            .font(.system(.body, design: .monospaced, weight: .bold))
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .foregroundStyle(context.state.isSleepingPeriod ? .blue : .indigo)
                        
                        Text(formatTargetTime(context))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        ProgressView(value: context.state.progress)
                            .progressViewStyle(.linear)
                            .tint(context.state.isSleepingPeriod ? .blue : .indigo)
                        
                        HStack {
                            Text("Started: \(formatTime(context.attributes.startTime))")
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                            Spacer()
                            Text("Ends: \(formatTime(context.attributes.endTime))")
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.isSleepingPeriod ? context.state.wakeupIcon : context.state.bedtimeIcon)
                    .foregroundStyle(context.state.isSleepingPeriod ? .blue : .indigo)
            } compactTrailing: {
                Text(formatTimeInterval(context.state.timeRemaining))
                    .font(.system(.body, design: .monospaced, weight: .bold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(context.state.isSleepingPeriod ? .blue : .indigo)
            } minimal: {
                Image(systemName: context.state.isSleepingPeriod ? context.state.wakeupIcon : context.state.bedtimeIcon)
                    .foregroundStyle(context.state.isSleepingPeriod ? .blue : .indigo)
            }
            .widgetURL(URL(string: "sleepCountdown://openApp"))
            .keylineTint(context.state.isSleepingPeriod ? Color.blue : Color.indigo)
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        // Toujours afficher les heures, minutes et secondes
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func formatTargetTime(_ context: ActivityViewContext<SleepCountdownWidgetAttributes>) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: context.state.isSleepingPeriod ? context.attributes.wakeupTime : context.attributes.bedtime)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    // Nouveau modifieur pour rendre le texte responsif
    private func responsiveTimeText(_ text: String) -> some View {
        GeometryReader { geometry in
            Text(text)
                .font(.system(.title2, design: .monospaced, weight: .bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundStyle(.white)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .trailing)
        }
    }
}

extension SleepCountdownWidgetAttributes {
    fileprivate static var preview: SleepCountdownWidgetAttributes {
        let calendar = Calendar.current
        let now = Date()
        let bedtime = calendar.date(from: DateComponents(hour: 22, minute: 0))!
        let wakeupTime = calendar.date(from: DateComponents(hour: 7, minute: 0))!
        
        return SleepCountdownWidgetAttributes(
            name: "Sleep Timer",
            bedtime: bedtime,
            wakeupTime: wakeupTime,
            startTime: now,
            endTime: now.addingTimeInterval(8 * 3600) // 8 hours later
        )
    }
}

extension SleepCountdownWidgetAttributes.ContentState {
    fileprivate static var bedtimeSoon: SleepCountdownWidgetAttributes.ContentState {
        SleepCountdownWidgetAttributes.ContentState(
            timeRemaining: 30 * 60, // 30 minutes
            isBeforeBedtime: true,
            isSleepingPeriod: false,
            progress: 0.8,
            bedtimeIcon: "bed.double.fill",
            wakeupIcon: "alarm.fill",
            alertIcon: "exclamationmark.triangle.fill",
            bedtimeText: "Coucher",
            wakeupText: "Réveil",
            alertText: "Attention"
        )
    }
     
    fileprivate static var wakeupSoon: SleepCountdownWidgetAttributes.ContentState {
        SleepCountdownWidgetAttributes.ContentState(
            timeRemaining: 15 * 60, // 15 minutes
            isBeforeBedtime: false,
            isSleepingPeriod: true,
            progress: 0.9,
            bedtimeIcon: "alarm.fill",
            wakeupIcon: "bed.double.fill",
            alertIcon: "exclamationmark.triangle.fill",
            bedtimeText: "Réveil",
            wakeupText: "Coucher",
            alertText: "Attention"
        )
    }
}

#Preview("Bedtime Soon", as: .content, using: SleepCountdownWidgetAttributes.preview) {
   SleepCountdownWidgetLiveActivity()
} contentStates: {
    SleepCountdownWidgetAttributes.ContentState.bedtimeSoon
}

#Preview("Wake-up Soon", as: .content, using: SleepCountdownWidgetAttributes.preview) {
   SleepCountdownWidgetLiveActivity()
} contentStates: {
    SleepCountdownWidgetAttributes.ContentState.wakeupSoon
}

#Preview("Dynamic Island (Compact)", as: .dynamicIsland(.compact), using: SleepCountdownWidgetAttributes.preview) {
    SleepCountdownWidgetLiveActivity()
} contentStates: {
    SleepCountdownWidgetAttributes.ContentState.bedtimeSoon
}

#Preview("Dynamic Island (Minimal)", as: .dynamicIsland(.minimal), using: SleepCountdownWidgetAttributes.preview) {
    SleepCountdownWidgetLiveActivity()
} contentStates: {
    SleepCountdownWidgetAttributes.ContentState.bedtimeSoon
}

#Preview("Dynamic Island (Expanded)", as: .dynamicIsland(.expanded), using: SleepCountdownWidgetAttributes.preview) {
    SleepCountdownWidgetLiveActivity()
} contentStates: {
    SleepCountdownWidgetAttributes.ContentState.bedtimeSoon
}
