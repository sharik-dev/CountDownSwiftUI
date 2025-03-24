//
//  SleepModel.swift
//  CountDownSwiftUI
//
//  Created by Sharik Mohamed on 10/03/2025.
//

import Foundation
import SwiftUI

struct SleepModel {
    static func getBedtime() -> Date {
        let storedBedtime = UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")?.object(forKey: "bedtime") as? Date
        return storedBedtime ?? Calendar.current.date(from: DateComponents(hour: 22, minute: 0))!
    }
    
    static func getWakeupTime() -> Date {
        let storedWakeupTime = UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")?.object(forKey: "wakeupTime") as? Date
        return storedWakeupTime ?? Calendar.current.date(from: DateComponents(hour: 7, minute: 0))!
    }
    
    static func isDarkMode() -> Bool {
        return UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")?.bool(forKey: "isDarkMode") ?? false
    }
    
    static func getAccentColor() -> Color {
        let colorString = UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")?.string(forKey: "accentColor") ?? "blue"
        switch colorString {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "purple": return .purple
        default: return .blue
        }
    }
    
    static func isBeforeBedtime(currentTime: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let bedtime = getBedtime()
        let wakeupTime = getWakeupTime()
        
        let bedComponents = calendar.dateComponents([.hour, .minute], from: bedtime)
        let wakeComponents = calendar.dateComponents([.hour, .minute], from: wakeupTime)
        let currentComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
        
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
    
    static func getTimeRemaining(currentTime: Date = Date()) -> String {
        let calendar = Calendar.current
        let isBeforeBed = isBeforeBedtime(currentTime: currentTime)
        let targetTime = isBeforeBed ? getBedtime() : getWakeupTime()
        
        let targetComponents = calendar.dateComponents([.hour, .minute], from: targetTime)
        let currentComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
        
        var targetMinutes = targetComponents.hour! * 60 + targetComponents.minute!
        let currentMinutes = currentComponents.hour! * 60 + currentComponents.minute!
        
        if !isBeforeBed && targetMinutes < currentMinutes {
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
    
    static func getTargetTimeFormatted() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: isBeforeBedtime() ? getBedtime() : getWakeupTime())
    }
}
