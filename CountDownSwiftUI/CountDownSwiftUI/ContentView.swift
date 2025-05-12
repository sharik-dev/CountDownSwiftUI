// ContentView.swift
// CountDownSwiftUI
//
// Created by Sharik Mohamed on 10/03/2025.
//

import SwiftUI
import WidgetKit
import PhotosUI

// Classe d'aide pour la gestion des images d'arrière-plan
class BackgroundManager {
    static let shared = BackgroundManager()
    private let fileManager = FileManager.default
    
    // Chemin vers le dossier partagé des images
    private var sharedImagesDirectory: URL? {
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.tempest.CountDownSwiftUI") else {
            return nil
        }
        let imagesURL = containerURL.appendingPathComponent("backgroundImages", isDirectory: true)
        
        // Créer le dossier s'il n'existe pas
        if !fileManager.fileExists(atPath: imagesURL.path) {
            do {
                try fileManager.createDirectory(at: imagesURL, withIntermediateDirectories: true)
            } catch {
                print("Erreur lors de la création du dossier d'images: \(error)")
                return nil
            }
        }
        
        return imagesURL
    }
    
    // Fonction pour redimensionner une image
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Prendre le ratio le plus petit pour s'assurer que l'image entre dans la taille cible
        let scaleFactor = min(widthRatio, heightRatio)
        
        let scaledWidth  = size.width * scaleFactor
        let scaledHeight = size.height * scaleFactor
        let targetRect = CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
        
        UIGraphicsBeginImageContextWithOptions(targetRect.size, false, 1.0)
        image.draw(in: targetRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    // Remplacer la fonction saveImage existante
    func saveImage(_ image: UIImage, withName name: String) -> String? {
        guard let imagesDirectory = sharedImagesDirectory else {
            return nil
        }
        
        // Créer le dossier s'il n'existe pas
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            do {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            } catch {
                print("Erreur lors de la création du dossier d'images: \(error)")
                return nil
            }
        }
        
        // Redimensionner l'image pour le widget (limite maximale de 800x600 pixels)
        let resizedImage = resizeImage(image, targetSize: CGSize(width: 800, height: 600))
        
        // Générer un nom de fichier unique basé sur le nom fourni et la date
        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueName = "\(name)_\(timestamp)"
        let fileURL = imagesDirectory.appendingPathComponent("\(uniqueName).jpg")
        
        // Convertir l'image redimensionnée en données JPEG avec compression
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            return nil
        }
        
        // Enregistrer les données dans le fichier
        do {
            try imageData.write(to: fileURL)
            
            // Mettre à jour UserDefaults avec le nom du fichier
            UserDefaults(suiteName: "group.com.tempest.CountDownSwiftUI")?.setValue(uniqueName, forKey: "backgroundImageName")
            UserDefaults(suiteName: "group.com.tempest.CountDownSwiftUI")?.setValue(true, forKey: "useCustomBackground")
            
            return uniqueName
        } catch {
            print("Erreur lors de l'enregistrement de l'image: \(error)")
            return nil
        }
    }
    
    // Récupérer une image depuis le dossier partagé
    func loadImage(named name: String) -> UIImage? {
        guard !name.isEmpty, let imagesDirectory = sharedImagesDirectory else {
            return nil
        }
        
        let fileURL = imagesDirectory.appendingPathComponent("\(name).jpg")
        
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                let imageData = try Data(contentsOf: fileURL)
                return UIImage(data: imageData)
            } catch {
                print("Erreur lors du chargement de l'image: \(error)")
                return nil
            }
        }
        
        return nil
    }
    
    // Supprimer une image du dossier partagé
    func deleteImage(named name: String) -> Bool {
        guard !name.isEmpty, let imagesDirectory = sharedImagesDirectory else {
            return false
        }
        
        let fileURL = imagesDirectory.appendingPathComponent("\(name).jpg")
        
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
                return true
            } catch {
                print("Erreur lors de la suppression de l'image: \(error)")
                return false
            }
        }
        
        return false
    }
    
    // Récupérer une Image SwiftUI depuis le dossier partagé
    func loadSwiftUIImage(named name: String) -> Image? {
        if let uiImage = loadImage(named: name) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    // Test d'accès aux fichiers partagés
    func testFileAccess() -> Bool {
        // Vérifier si le groupe d'applications est accessible
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.tempest.CountDownSwiftUI") {
            let imagesURL = containerURL.appendingPathComponent("backgroundImages", isDirectory: true)
            
            // Créer le dossier s'il n'existe pas
            if !FileManager.default.fileExists(atPath: imagesURL.path) {
                do {
                    try FileManager.default.createDirectory(at: imagesURL, withIntermediateDirectories: true)
                    print("✅ Test: Created images directory")
                    return true
                } catch {
                    print("❌ Test: Error creating directory: \(error)")
                    return false
                }
            }
            
            // Créer un fichier test
            let testFileURL = imagesURL.appendingPathComponent("test_\(Int(Date().timeIntervalSince1970)).txt")
            let testData = "This is a test file".data(using: .utf8)!
            
            do {
                try testData.write(to: testFileURL)
                print("✅ Test: Created test file at \(testFileURL.path)")
                
                // Lister les fichiers dans le dossier
                let files = try FileManager.default.contentsOfDirectory(atPath: imagesURL.path)
                print("📁 Test: Directory contents: \(files)")
                
                // Message de succès
                return true
            } catch {
                print("❌ Test: Error working with file: \(error)")
                return false
            }
        } else {
            print("❌ Test: Could not access app group container")
            return false
        }
    }
    
    // Fonction pour nettoyer le cache d'images
    func clearCache() {
        // Implémentation de la fonction pour nettoyer le cache d'images
        // Cette implémentation est basée sur la suppression de tous les fichiers dans le dossier partagé
        if let imagesDirectory = sharedImagesDirectory {
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: imagesDirectory.path)
                for file in files {
                    let fileURL = imagesDirectory.appendingPathComponent(file)
                    try FileManager.default.removeItem(at: fileURL)
                }
            } catch {
                print("Erreur lors de la suppression du cache d'images: \(error)")
            }
        }
    }
}

struct ContentView: View {
    @AppStorage("bedtime", store: UserDefaults(suiteName: "group.com.tempest.CountDownSwiftUI")) 
    private var bedtime = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    @AppStorage("wakeupTime", store: UserDefaults(suiteName: "group.com.tempest.CountDownSwiftUI")) 
    private var wakeupTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @AppStorage("isDarkMode", store: UserDefaults(suiteName: "group.com.tempest.CountDownSwiftUI")) 
    private var isDarkMode = false
    @AppStorage("accentColor", store: UserDefaults(suiteName: "group.com.tempest.CountDownSwiftUI")) 
    private var accentColorString = "blue"
    
    // Nouveaux paramètres pour la personnalisation des textes et icônes
    @AppStorage("bedtimeIcon", store: UserDefaults(suiteName: "group.com.tempest.CountDownSwiftUI")) 
    private var bedtimeIcon = "bed.double.fill"
    @AppStorage("wakeupIcon", store: UserDefaults(suiteName: "group.com.tempest.CountDownSwiftUI")) 
    private var wakeupIcon = "alarm.fill"
    @AppStorage("alertIcon", store: UserDefaults(suiteName: "group.com.tempest.CountDownSwiftUI")) 
    private var alertIcon = "exclamationmark.triangle.fill"
    
    @AppStorage("bedtimeText", store: UserDefaults(suiteName: "group.com.tempest.CountDownSwiftUI")) 
    private var bedtimeText = "Time until bedtime"
    @AppStorage("wakeupText", store: UserDefaults(suiteName: "group.com.tempest.CountDownSwiftUI")) 
    private var wakeupText = "Time until wake-up"
    @AppStorage("alertText", store: UserDefaults(suiteName: "group.com.tempest.CountDownSwiftUI")) 
    private var alertText = "Sleep time running out!"
    
    // Ajout du gestionnaire d'activité en direct
    @StateObject private var activityManager = SleepActivityManager()
    
    // État pour gérer l'affichage de l'alerte de confirmation
    @State private var showingSaveConfirmation = false
    
    // État pour basculer entre les vues petite et moyenne
    @State private var showSmallPreview = false
    
    // État pour gérer l'affichage des sections de personnalisation
    @State private var showingBedtimeSettings = false
    @State private var showingWakeupSettings = false
    @State private var showingAlertSettings = false
    
    // Temporisateur pour les mises à jour
    @State private var updateTimer: Timer?
    
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
                            // Ne pas mettre à jour le widget immédiatement
                            // updateWidget() 
                            // Mettre à jour l'activité en direct si elle est active
                            if activityManager.isActivityActive {
                                activityManager.endActivityFromView()
                                activityManager.startActivityFromView(bedtime: bedtime, wakeupTime: wakeupTime)
                            }
                        }
                    
                    DatePicker("Wake-up Time", selection: $wakeupTime, displayedComponents: .hourAndMinute)
                        .onChange(of: wakeupTime) { _ in
                            // Ne pas mettre à jour le widget immédiatement
                            // updateWidget()
                            // Mettre à jour l'activité en direct si elle est active
                            if activityManager.isActivityActive {
                                activityManager.endActivityFromView()
                                activityManager.startActivityFromView(bedtime: bedtime, wakeupTime: wakeupTime)
                            }
                        }
                    
                    Button("Enregistrer") {
                        updateWidget()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Section(header: Text("Widget Preview")) {
                    // Ajout d'un bouton pour basculer entre les vues
                    HStack {
                        Button(action: {
                            showSmallPreview.toggle()
                        }) {
                            HStack {
                                Image(systemName: showSmallPreview ? "rectangle" : "square")
                                Text(showSmallPreview ? "Show Medium" : "Show Small")
                            }
                        }
                        .padding(8)
                        .background(accentColor.opacity(0.2))
                        .cornerRadius(8)
                        
                        Spacer()
                    }
                    .padding(.vertical, 5)
                    
                    CountdownPreview(
                        bedtime: bedtime, 
                        wakeupTime: wakeupTime, 
                        isDarkMode: isDarkMode, 
                        accentColor: accentColor,
                        isSmall: showSmallPreview,
                        bedtimeIcon: bedtimeIcon,
                        wakeupIcon: wakeupIcon,
                        alertIcon: alertIcon,
                        bedtimeText: bedtimeText,
                        wakeupText: wakeupText,
                        alertText: alertText
                    )
                    .frame(height: 150)
                    .cornerRadius(15)
                }
                
                Section(header: Text("Widget Appearance")) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                    
                    Picker("Widget Color", selection: $accentColorString) {
                        Text("Blue").tag("blue")
                        Text("Red").tag("red")
                        Text("Green").tag("green")
                        Text("Purple").tag("purple")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Section pour personnaliser le texte et les icônes du widget
                Section(header: Text("Widget Personalization")) {
                    DisclosureGroup(
                        isExpanded: $showingBedtimeSettings,
                        content: {
                            TextField("Bedtime text", text: $bedtimeText)
                                .padding(.vertical, 4)
                            
                            // Sélecteur d'icône pour l'heure du coucher
                            IconPicker(title: "Bedtime icon", selection: $bedtimeIcon)
                        },
                        label: {
                            HStack {
                                Image(systemName: bedtimeIcon)
                                    .foregroundColor(accentColor)
                                Text("Bedtime Display")
                            }
                        }
                    )
                    
                    DisclosureGroup(
                        isExpanded: $showingWakeupSettings,
                        content: {
                            TextField("Wake-up text", text: $wakeupText)
                                .padding(.vertical, 4)
                            
                            // Sélecteur d'icône pour l'heure du réveil
                            IconPicker(title: "Wake-up icon", selection: $wakeupIcon)
                        },
                        label: {
                            HStack {
                                Image(systemName: wakeupIcon)
                                    .foregroundColor(accentColor)
                                Text("Wake-up Display")
                            }
                        }
                    )
                    
                    DisclosureGroup(
                        isExpanded: $showingAlertSettings,
                        content: {
                            TextField("Alert text", text: $alertText)
                                .padding(.vertical, 4)
                            
                            // Sélecteur d'icône pour l'alerte
                            IconPicker(title: "Alert icon", selection: $alertIcon)
                        },
                        label: {
                            HStack {
                                Image(systemName: alertIcon)
                                    .foregroundColor(.red)
                                Text("Alert Display")
                            }
                        }
                    )
                }
                
                Section(header: Text("About")) {
                    Text("This app shows a countdown to your bedtime or wake-up time in a widget.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Sleep Countdown")
            .overlay(
                // Afficher un message de confirmation lorsque les préférences sont enregistrées
                ZStack {
                    if showingSaveConfirmation {
                        VStack {
                            Text("Préférences enregistrées")
                                .font(.headline)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut, value: showingSaveConfirmation)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            )
            .onDisappear {
                // Annuler le timer lorsque la vue disparaît
                cancelUpdateTimer()
            }
        }
    }
    
    private func updateWidget() {
        // Forcer la synchronisation des UserDefaults
        UserDefaults(suiteName: "group.com.tempest.CountDownSwiftUI")?.synchronize()
        
        // Recharger le widget
        WidgetCenter.shared.reloadAllTimelines()
        
        // Afficher une confirmation
        showingSaveConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showingSaveConfirmation = false
        }
        
        // Mettre à jour l'activité en direct si elle est active
        if activityManager.isActivityActive {
            activityManager.endActivityFromView()
            activityManager.startActivityFromView(bedtime: bedtime, wakeupTime: wakeupTime)
        }
    }
    
    private func cancelUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func debounceUpdateWidget() {
        // Annuler tout timer existant
        updateTimer?.invalidate()
        
        // Créer un nouveau timer avec un délai
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            self.updateWidget()
        }
    }
}

struct CountdownPreview: View {
    let bedtime: Date
    let wakeupTime: Date
    let isDarkMode: Bool
    let accentColor: Color
    @State private var currentTime = Date()
    @State private var opacity: Double = 1.0
    @State private var alertIconOpacity: Double = 1.0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var isSmall: Bool = false // Par défaut, on montre la version medium
    
    // Nouvelles propriétés personnalisables
    let bedtimeIcon: String
    let wakeupIcon: String
    let alertIcon: String
    let bedtimeText: String
    let wakeupText: String
    let alertText: String
    
    // 🖌️ UI DE LA PREVIEW - DÉBUT
    var body: some View {
        // Utiliser un conteneur transparent pour que la couleur s'étende aux bords
        GeometryReader { geometry in
            Color.clear
                .overlay(
                    ZStack {
                        // Fond coloré qui occupe tout l'espace
                        backgroundColor
                            .opacity(timeIsRunningOut() && !showBedtimeCountdown ? opacity : 1.0)
                            .onAppear {
                                if timeIsRunningOut() && !showBedtimeCountdown {
                                    withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                        opacity = 0.6
                                    }
                                }
                            }
                            .ignoresSafeArea(.all)
                        
                        // Couche de superposition pour améliorer la lisibilité
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    backgroundColor.opacity(0.7),
                                    backgroundColor.opacity(0.5)
                                ]
                            ),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .opacity(0)
                        .ignoresSafeArea(.all)
                        
                        // Éléments décoratifs
                        decorations(geometry: geometry)
                        
                        // Interface principale qui diffère selon la taille choisie
                        if isSmall {
                            smallWidget
                        } else {
                            mediumWidget
                        }
                    }
                )
                .onReceive(timer) { _ in
                    currentTime = Date()
                }
                .id(currentTime) // Forcer la mise à jour de la vue
        }
        .ignoresSafeArea(.all) // Assurer que tout s'étend aux bords
    }
    
    // Version simplifiée pour petit widget
    var smallWidget: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                
                Text(titleText)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundColor(.white)
            }
            .padding(.top, 2)
            
            // Utilisation de GeometryReader pour adapter la taille du texte
            GeometryReader { geometry in
                Text(timeRemainingFormatted)
                    .font(.system(size: min(geometry.size.width / 6, 28), weight: .bold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            }
            .frame(height: 30)
            
            Text(subtitleText)
                .font(.caption2)
                .lineLimit(1)
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 2)
        }
        .padding(8)
    }
    
    // Version complète pour widget medium
    var mediumWidget: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 22))
                
                Text(titleText)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.top, 4)
            
            // Utilisation de GeometryReader pour adapter la taille du texte
            GeometryReader { geometry in
                Text(timeRemainingFormatted)
                    .font(.system(size: min(geometry.size.width / 8, 42), weight: .bold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            }
            .frame(height: 50)
            
            Text(subtitleText)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(12)
    }
    
    // Fonction pour les éléments décoratifs
    func decorations(geometry: GeometryProxy) -> some View {
        Group {
            if showBedtimeCountdown {
                // Aucune décoration pour le thème de sommeil
                EmptyView()
            } else if !showBedtimeCountdown && !timeIsRunningOut() {
                // Soleil pour le thème de réveil
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.yellow.opacity(0.7))
                    .font(.system(size: 32))
                    .position(x: geometry.size.width - 40, y: 25)
            } else if timeIsRunningOut() {
                // Icône d'alerte pour manque de sommeil
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 32))
                    .position(x: geometry.size.width - 40, y: 25)
                    .opacity(alertIconOpacity)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            alertIconOpacity = 0.6
                        }
                    }
            }
        }
    }
    // 🖌️ UI DE LA PREVIEW - FIN
    
    // Propriétés calculées pour le texte et les couleurs
    var backgroundColor: Color {
        if timeIsRunningOut() && !showBedtimeCountdown {
            return Color.red
        } else if isDarkMode {
            return Color.black
        } else {
            return accentColor
        }
    }
    
    var iconName: String {
        if showBedtimeCountdown {
            return bedtimeIcon
        } else if timeIsRunningOut() {
            return alertIcon
        } else {
            return wakeupIcon
        }
    }
    
    var titleText: String {
        if showBedtimeCountdown {
            return bedtimeText
        } else if timeIsRunningOut() {
            return alertText
        } else {
            return wakeupText
        }
    }
    
    var subtitleText: String {
        if timeIsRunningOut() && !showBedtimeCountdown {
            return "Only \(hoursSleepRemaining()) hours of sleep!"
        } else {
            return targetTimeFormatted
        }
    }
    
    // Détermine quel compte à rebours afficher en fonction du temps le plus court
    private var showBedtimeCountdown: Bool {
        let timeToBedtime = calculateTimeRemaining(to: bedtime)
        let timeToWakeup = calculateTimeRemaining(to: wakeupTime)
        
        // Afficher le temps le plus court
        return timeToBedtime < timeToWakeup
    }
    
    // Vérifie si le temps de sommeil restant est insuffisant (moins de 7 heures)
    private func timeIsRunningOut() -> Bool {
        if showBedtimeCountdown {
            return false // Pas d'alerte avant l'heure du coucher
        }
        
        let calendar = Calendar.current
        
        // Heure du réveil
        let wakeComponents = calendar.dateComponents([.hour, .minute], from: wakeupTime)
        let currentComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
        
        // Heure actuelle convertie en minutes depuis minuit
        let currentMinutes = currentComponents.hour! * 60 + currentComponents.minute!
        // Heure du réveil convertie en minutes depuis minuit
        let wakeMinutes = wakeComponents.hour! * 60 + wakeComponents.minute!
        
        // Si l'heure du réveil est plus tôt que l'heure actuelle, elle est le lendemain
        let minutesToWakeup = wakeMinutes < currentMinutes ? 
            (wakeMinutes + 24 * 60) - currentMinutes : 
            wakeMinutes - currentMinutes
        
        // Alerte si moins de 7 heures de sommeil restantes
        return minutesToWakeup < 7 * 60
    }
    
    // Calcule le nombre d'heures de sommeil restantes
    private func hoursSleepRemaining() -> String {
        let calendar = Calendar.current
        
        // Calcul similaire à timeIsRunningOut mais retourne les heures restantes
        let wakeComponents = calendar.dateComponents([.hour, .minute], from: wakeupTime)
        let currentComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
        
        let currentMinutes = currentComponents.hour! * 60 + currentComponents.minute!
        let wakeMinutes = wakeComponents.hour! * 60 + wakeComponents.minute!
        
        let minutesToWakeup = wakeMinutes < currentMinutes ? 
            (wakeMinutes + 24 * 60) - currentMinutes : 
            wakeMinutes - currentMinutes
        
        let hours = minutesToWakeup / 60
        let minutes = minutesToWakeup % 60
        
        return String(format: "%d:%02d", hours, minutes)
    }
    
    private func calculateTimeRemaining(to targetTime: Date) -> TimeInterval {
        let calendar = Calendar.current
        
        // Créer une date cible pour aujourd'hui avec les heures et minutes de la cible
        var targetComponents = calendar.dateComponents([.year, .month, .day], from: currentTime)
        let targetTimeComponents = calendar.dateComponents([.hour, .minute], from: targetTime)
        targetComponents.hour = targetTimeComponents.hour
        targetComponents.minute = targetTimeComponents.minute
        targetComponents.second = 0
        
        var targetDate = calendar.date(from: targetComponents)!
        
        // Si la cible est déjà passée aujourd'hui, ajouter un jour
        if targetDate < currentTime {
            targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate)!
        }
        
        return targetDate.timeIntervalSince(currentTime)
    }
    
    private var timeRemainingFormatted: String {
        let timeRemaining = showBedtimeCountdown ? 
            calculateTimeRemaining(to: bedtime) : 
            calculateTimeRemaining(to: wakeupTime)
        
        // Formater avec les heures, minutes et secondes
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = (Int(timeRemaining) % 60) / 10 * 10 // Arrondir aux dizaines
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private var targetTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: showBedtimeCountdown ? bedtime : wakeupTime)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// 🖌️ PREVIEWS POUR LE DÉVELOPPEMENT DE LA PREVIEW
struct CountdownPreview_Previews: PreviewProvider {
    static var previews: some View {
        // Preview - Mode coucher
        CountdownPreview(
            bedtime: Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date(),
            wakeupTime: Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date(),
            isDarkMode: false,
            accentColor: .blue,
            isSmall: false,
            bedtimeIcon: "bed.double.fill",
            wakeupIcon: "alarm.fill",
            alertIcon: "exclamationmark.triangle.fill",
            bedtimeText: "Time until bedtime",
            wakeupText: "Time until wake-up",
            alertText: "Sleep time running out!"
        )
        .frame(height: 150)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Preview - Bedtime Mode")
        
        // Preview - Mode réveil
        CountdownPreview(
            bedtime: Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date(),
            wakeupTime: Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date(),
            isDarkMode: true,
            accentColor: .purple,
            isSmall: true,
            bedtimeIcon: "bed.double.fill",
            wakeupIcon: "alarm.fill",
            alertIcon: "exclamationmark.triangle.fill",
            bedtimeText: "Time until bedtime",
            wakeupText: "Time until wake-up",
            alertText: "Sleep time running out!"
        )
        .frame(height: 150)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Preview - Wakeup Mode")
        
        // Preview - Mode alerte
        CountdownPreview(
            bedtime: Calendar.current.date(from: DateComponents(hour: 2, minute: 0)) ?? Date(),
            wakeupTime: Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date(),
            isDarkMode: false,
            accentColor: .red,
            isSmall: false,
            bedtimeIcon: "bed.double.fill",
            wakeupIcon: "alarm.fill",
            alertIcon: "exclamationmark.triangle.fill",
            bedtimeText: "Time until bedtime",
            wakeupText: "Time until wake-up",
            alertText: "Sleep time running out!"
        )
        .frame(height: 150)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Preview - Alert Mode")
    }
}

/* 
 * GUIDE RAPIDE DE PERSONNALISATION:
 * 
 * 1. COULEURS ET APPARENCE:
 *    - backgroundColor: définit la couleur de fond
 *    - Ajoute des dégradés avec LinearGradient:
 *      LinearGradient(gradient: Gradient(colors: [.blue, .purple]), 
 *                    startPoint: .topLeading, endPoint: .bottomTrailing)
 *    - Effet de verre: .background(.ultraThinMaterial) ou .regularMaterial
 *
 * 2. ÉLÉMENTS DÉCORATIFS:
 *    - Modifie les éléments dans decorations()
 *    - Ajoute des formes: Circle(), Rectangle(), RoundedRectangle()
 *    - Applique des effets: .blur(), .shadow(), .overlay()
 *
 * 3. ANIMATIONS:
 *    - Types: .easeInOut, .spring(), .linear
 *    - Animation complexes: 
 *      withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { ... }
 *
 * 4. ASTUCES SWIFTUI:
 *    - Pour des éléments chevauchants, utilise ZStack
 *    - Pour des alignements précis, utilise .position() ou .offset()
 *    - Pour des animations personnalisées, exploite .animation(value:) et .transition()
 */

// Composant pour sélectionner une icône
struct IconPicker: View {
    let title: String
    @Binding var selection: String
    @State private var showingIconSheet = false
    
    // Liste d'icônes disponibles
    let commonIcons = [
        "bed.double.fill", "moon.stars.fill", "powersleep", "nightstand.fill",
        "alarm.fill", "sun.max.fill", "clock.fill", "bell.fill", 
        "exclamationmark.triangle.fill", "exclamationmark.circle.fill", "timer", "hourglass",
        "heart.fill", "star.fill", "sparkles", "cloud.moon.fill",
        "person.fill", "house.fill", "bolt.fill", "lightbulb.fill"
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: {
                showingIconSheet = true
            }) {
                HStack {
                    Image(systemName: selection)
                        .font(.title2)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("Change")
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 6)
            }
            .sheet(isPresented: $showingIconSheet) {
                NavigationView {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
                            ForEach(commonIcons, id: \.self) { icon in
                                Button(action: {
                                    selection = icon
                                    showingIconSheet = false
                                }) {
                                    VStack {
                                        Image(systemName: icon)
                                            .font(.system(size: 32))
                                            .frame(width: 60, height: 60)
                                            .background(icon == selection ? Color.blue.opacity(0.2) : Color.clear)
                                            .cornerRadius(10)
                                        Text(iconName(for: icon))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                    .navigationTitle("Select Icon")
                    .navigationBarItems(trailing: Button("Cancel") {
                        showingIconSheet = false
                    })
                }
            }
        }
    }
    
    // Fonction pour afficher un nom convivial pour l'icône
    private func iconName(for systemName: String) -> String {
        let components = systemName.split(separator: ".")
        let base = components.first ?? ""
        return base.replacingOccurrences(of: "-", with: " ").capitalized
    }
}
