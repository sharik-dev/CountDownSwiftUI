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
        // Dynamic stateful properties about your activity go here!
        var timeRemaining: TimeInterval
        var isBeforeBedtime: Bool
        var progress: Double
    }

    // Fixed non-changing properties about your activity go here!
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
                    Image(systemName: context.state.isBeforeBedtime ? "bed.double.fill" : "alarm.fill")
                        .foregroundStyle(.white)
                    
                    Text(context.state.isBeforeBedtime ? "Time until bedtime" : "Time until wake-up")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text(formatTimeInterval(context.state.timeRemaining))
                        .font(.system(.title2, design: .monospaced, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                ProgressView(value: context.state.progress)
                    .progressViewStyle(.linear)
                    .tint(.white)
            }
            .padding()
            .activityBackgroundTint(context.state.isBeforeBedtime ? Color.indigo : Color.blue)
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Image(systemName: context.state.isBeforeBedtime ? "bed.double.fill" : "alarm.fill")
                            .foregroundStyle(context.state.isBeforeBedtime ? .indigo : .blue)
                        Text(context.state.isBeforeBedtime ? "Bedtime" : "Wake up")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(formatTimeInterval(context.state.timeRemaining))
                            .font(.system(.body, design: .monospaced, weight: .bold))
                            .foregroundStyle(context.state.isBeforeBedtime ? .indigo : .blue)
                        
                        Text(formatTargetTime(context))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        ProgressView(value: context.state.progress)
                            .progressViewStyle(.linear)
                            .tint(context.state.isBeforeBedtime ? .indigo : .blue)
                        
                        HStack {
                            Text("Started: \(formatTime(context.attributes.startTime))")
                            Spacer()
                            Text("Ends: \(formatTime(context.attributes.endTime))")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.isBeforeBedtime ? "bed.double.fill" : "alarm.fill")
                    .foregroundStyle(context.state.isBeforeBedtime ? .indigo : .blue)
            } compactTrailing: {
                Text(formatTimeInterval(context.state.timeRemaining))
                    .font(.system(.body, design: .monospaced, weight: .bold))
                    .foregroundStyle(context.state.isBeforeBedtime ? .indigo : .blue)
            } minimal: {
                Image(systemName: context.state.isBeforeBedtime ? "bed.double.fill" : "alarm.fill")
                    .foregroundStyle(context.state.isBeforeBedtime ? .indigo : .blue)
            }
            .widgetURL(URL(string: "sleepCountdown://openApp"))
            .keylineTint(context.state.isBeforeBedtime ? Color.indigo : Color.blue)
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func formatTargetTime(_ context: ActivityViewContext<SleepCountdownWidgetAttributes>) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: context.state.isBeforeBedtime ? context.attributes.bedtime : context.attributes.wakeupTime)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
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
            progress: 0.8
        )
    }
     
    fileprivate static var wakeupSoon: SleepCountdownWidgetAttributes.ContentState {
        SleepCountdownWidgetAttributes.ContentState(
            timeRemaining: 15 * 60, // 15 minutes
            isBeforeBedtime: false,
            progress: 0.9
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
