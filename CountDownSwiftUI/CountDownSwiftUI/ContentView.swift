//
//  ContentView.swift
//  CountDownSwiftUI
//
//  Created by Sharik Mohamed on 10/03/2025.
//

import SwiftUI
import WidgetKit 

struct ContentView: View {
    @AppStorage("bedtime") private var bedtime = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    @AppStorage("wakeupTime") private var wakeupTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("accentColor") private var accentColorString = "blue"
    
    private var accentColor: Color {
        switch accentColorString {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "purple": return .purple
        default: return .blue
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sleep Schedule")) {
                    DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
                        .onChange(of: bedtime) { _ in
                            updateWidget()
                        }
                    
                    DatePicker("Wake-up Time", selection: $wakeupTime, displayedComponents: .hourAndMinute)
                        .onChange(of: wakeupTime) { _ in
                            updateWidget()
                        }
                }
                
                Section(header: Text("Widget Preview")) {
                    CountdownPreview(bedtime: bedtime, wakeupTime: wakeupTime, isDarkMode: isDarkMode, accentColor: accentColor)
                        .frame(height: 150)
                        .cornerRadius(15)
                }
                
                Section(header: Text("Widget Appearance")) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .onChange(of: isDarkMode) { _ in
                            updateWidget()
                        }
                    
                    Picker("Accent Color", selection: $accentColorString) {
                        Text("Blue").tag("blue")
                        Text("Red").tag("red")
                        Text("Green").tag("green")
                        Text("Purple").tag("purple")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: accentColorString) { _ in
                        updateWidget()
                    }
                }
                
                Section(header: Text("About")) {
                    Text("This app shows a countdown to your bedtime or wake-up time in a widget.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Sleep Countdown")
        }
    }
    
    private func updateWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct CountdownPreview: View {
    let bedtime: Date
    let wakeupTime: Date
    let isDarkMode: Bool
    let accentColor: Color
    
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(isDarkMode ? Color.black : Color.white)
            
            VStack(spacing: 10) {
                Text(isBeforeBedtime ? "Time until bedtime" : "Time until wake-up")
                    .font(.headline)
                    .foregroundColor(isDarkMode ? .white : .black)
                
                Text(timeRemainingFormatted)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(accentColor)
                
                Text(targetTimeFormatted)
                    .font(.caption)
                    .foregroundColor(isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
            }
            .padding()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private var isBeforeBedtime: Bool {
        let calendar = Calendar.current
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
    
    private var timeRemainingFormatted: String {
        let calendar = Calendar.current
        let targetTime = isBeforeBedtime ? bedtime : wakeupTime
        
        let targetComponents = calendar.dateComponents([.hour, .minute], from: targetTime)
        let currentComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
        
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
    
    private var targetTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: isBeforeBedtime ? bedtime : wakeupTime)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
