// ContentView.swift
// CountDownSwiftUI
//
// Created by Sharik Mohamed on 10/03/2025.
//

import SwiftUI
import WidgetKit
import PhotosUI
import DesignSystemKit

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
    @AppStorage("bedtime", store: UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")) 
    private var bedtime = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    @AppStorage("wakeupTime", store: UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")) 
    private var wakeupTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @AppStorage("accentColor", store: UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")) 
    private var accentColorString = "blue"
    
    // Nouveaux paramètres pour la personnalisation des textes et icônes
    @AppStorage("bedtimeIcon", store: UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")) 
    private var bedtimeIcon = "bed.double.fill"
    @AppStorage("wakeupIcon", store: UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")) 
    private var wakeupIcon = "alarm.fill"
    @AppStorage("alertIcon", store: UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")) 
    private var alertIcon = "exclamationmark.triangle.fill"
    
    @AppStorage("bedtimeText", store: UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")) 
    private var bedtimeText = "Time until bedtime"
    @AppStorage("wakeupText", store: UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")) 
    private var wakeupText = "Time until wake-up"
    @AppStorage("alertText", store: UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")) 
    private var alertText = "Sleep time running out!"
    
    // Ajout du gestionnaire d'activité en direct
    @StateObject private var activityManager = SleepActivityManager()
    
    // État pour gérer l'affichage des sections de personnalisation
    @State private var showingBedtimeSettings = false
    @State private var showingWakeupSettings = false
    @State private var showingAlertSettings = false
    
    // Temporisateur pour les mises à jour
    @State private var updateTimer: Timer?
    
    // Accès au thème de design
    @Environment(\.dsTheme) private var dsTheme

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
        TabView {
            // Tab 1: Sleep Schedule
            ScheduleView(
                bedtime: $bedtime,
                wakeupTime: $wakeupTime,
                updateWidget: updateWidgetAutomatically
            )
            .tabItem {
                Label("Schedule", systemImage: "clock.fill")
            }
            
            // Tab 2: Widget Preview
            PreviewView(
                bedtime: bedtime, 
                wakeupTime: wakeupTime, 
                accentColor: accentColor,
                bedtimeIcon: bedtimeIcon,
                wakeupIcon: wakeupIcon,
                alertIcon: alertIcon,
                bedtimeText: bedtimeText,
                wakeupText: wakeupText,
                alertText: alertText
            )
            .tabItem {
                Label("Preview", systemImage: "eye.fill")
            }
            
            // Tab 3: Appearance
            AppearanceView(
                accentColorString: $accentColorString,
                updateWidget: updateWidgetAutomatically
            )
            .tabItem {
                Label("Appearance", systemImage: "paintbrush.fill")
            }
            
            // Tab 4: Personalization
            PersonalizationView(
                bedtimeIcon: $bedtimeIcon,
                wakeupIcon: $wakeupIcon,
                alertIcon: $alertIcon,
                bedtimeText: $bedtimeText,
                wakeupText: $wakeupText,
                alertText: $alertText,
                showingBedtimeSettings: $showingBedtimeSettings,
                showingWakeupSettings: $showingWakeupSettings,
                showingAlertSettings: $showingAlertSettings,
                accentColor: accentColor,
                updateWidget: updateWidgetAutomatically
            )
            .tabItem {
                Label("Customize", systemImage: "gearshape.fill")
            }
            
            // Tab 5: About
            AboutView()
            .tabItem {
                Label("About", systemImage: "info.circle.fill")
            }
        }
        .accentColor(accentColor)
        .preferredColorScheme(.dark) // Forcer le mode sombre
        .onDisappear {
            // Annuler le timer lorsque la vue disparaît
            cancelUpdateTimer()
        }
    }
    
    // Fonction d'enregistrement automatique
    private func updateWidgetAutomatically() {
        debounceUpdateWidget()
    }
    
    private func updateWidget() {
        // Forcer la synchronisation des UserDefaults
        UserDefaults(suiteName: "group.com.yourcompany.CountDownSwiftUI")?.synchronize()
        
        // Recharger le widget
        WidgetCenter.shared.reloadAllTimelines()
        
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

// MARK: - View Structures for Tabs

struct ScheduleView: View {
    @Binding var bedtime: Date
    @Binding var wakeupTime: Date
    var updateWidget: () -> Void
    
    // Accès au thème de design
    @Environment(\.dsTheme) private var dsTheme
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                
                VStack(spacing: 10) {
                    DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
                        .font(dsTheme.typography.body)
                        .padding(.horizontal)
                        .onChange(of: bedtime) { _ in
                            updateWidget()
                        }
                    
                    DatePicker("Wake-up Time", selection: $wakeupTime, displayedComponents: .hourAndMinute)
                        .font(dsTheme.typography.body)
                        .padding(.horizontal)
                        .onChange(of: wakeupTime) { _ in
                            updateWidget()
                        }
                }
                .padding(.vertical, 10)
                .background(dsTheme.colors.background)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Sleep Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(red: 30/255, green: 32/255, blue: 44/255))
        }
    }
}

struct PreviewView: View {
    let bedtime: Date
    let wakeupTime: Date
    let accentColor: Color
    let bedtimeIcon: String
    let wakeupIcon: String
    let alertIcon: String
    let bedtimeText: String
    let wakeupText: String
    let alertText: String
    
    // Accès au thème de design
    @Environment(\.dsTheme) private var dsTheme
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                
                CountdownPreview(
                    bedtime: bedtime, 
                    wakeupTime: wakeupTime, 
                    accentColor: accentColor,
                    bedtimeIcon: bedtimeIcon,
                    wakeupIcon: wakeupIcon,
                    alertIcon: alertIcon,
                    bedtimeText: bedtimeText,
                    wakeupText: wakeupText,
                    alertText: alertText
                )
                .frame(height: 150)
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Widget Preview")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(red: 30/255, green: 32/255, blue: 44/255))
        }
    }
}

struct AppearanceView: View {
    @Binding var accentColorString: String
    var updateWidget: () -> Void
    
    // Accès au thème de design
    @Environment(\.dsTheme) private var dsTheme
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Widget Appearance")
                    .font(dsTheme.typography.caption)
                    .foregroundColor(dsTheme.colors.secondary)
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 5)
                
                // Widget Color
                VStack(alignment: .leading, spacing: 12) {
                    Text("Widget Color")
                        .font(dsTheme.typography.body)
                        .foregroundColor(dsTheme.colors.text)
                        .padding(.horizontal)
                        .padding(.top, 12)
                    
                    // Une simple HStack avec des boutons de couleur
                    HStack(spacing: 20) {
                        Spacer()
                        colorButton("blue", color: .blue)
                        colorButton("red", color: .red)
                        colorButton("green", color: .green)
                        colorButton("purple", color: .purple)
                        Spacer()
                    }
                    .padding(.bottom, 12)
                }
                .background(dsTheme.colors.background)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(red: 30/255, green: 32/255, blue: 44/255))
        }
    }
    
    private func colorButton(_ tag: String, color: Color) -> some View {
        Button(action: {
            accentColorString = tag
            updateWidget()
        }) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                
                if accentColorString == tag {
                    // Utiliser un cercle avec une bordure plus fine et transparente
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 40, height: 40)
                }
            }
            // Ajouter du padding pour éviter que les cercles se touchent
            .padding(3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PersonalizationView: View {
    @Binding var bedtimeIcon: String
    @Binding var wakeupIcon: String
    @Binding var alertIcon: String
    @Binding var bedtimeText: String
    @Binding var wakeupText: String
    @Binding var alertText: String
    @Binding var showingBedtimeSettings: Bool
    @Binding var showingWakeupSettings: Bool
    @Binding var showingAlertSettings: Bool
    let accentColor: Color
    var updateWidget: () -> Void
    
    // Accès au thème de design
    @Environment(\.dsTheme) private var dsTheme
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Widget Personalization")
                    .font(dsTheme.typography.caption)
                    .foregroundColor(dsTheme.colors.secondary)
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 5)
                
                VStack {
                    disclosureSection(
                        isExpanded: $showingBedtimeSettings,
                        icon: bedtimeIcon,
                        title: "Bedtime Display",
                        iconColor: accentColor,
                        content: {
                            VStack(alignment: .leading) {
                                TextField("Bedtime text", text: $bedtimeText)
                                    .font(dsTheme.typography.body)
                                    .padding(.vertical, 4)
                                    .foregroundColor(dsTheme.colors.text)
                                    .onChange(of: bedtimeText) { _ in
                                        updateWidget()
                                    }
                                
                                IconPicker(title: "Bedtime icon", selection: $bedtimeIcon)
                                    .environment(\.dsTheme, dsTheme)
                            }
                            .padding(.horizontal)
                        }
                    )
                    
                    disclosureSection(
                        isExpanded: $showingWakeupSettings,
                        icon: wakeupIcon,
                        title: "Wake-up Display",
                        iconColor: accentColor,
                        content: {
                            VStack(alignment: .leading) {
                                TextField("Wake-up text", text: $wakeupText)
                                    .font(dsTheme.typography.body)
                                    .padding(.vertical, 4)
                                    .foregroundColor(dsTheme.colors.text)
                                    .onChange(of: wakeupText) { _ in
                                        updateWidget()
                                    }
                                
                                IconPicker(title: "Wake-up icon", selection: $wakeupIcon)
                                    .environment(\.dsTheme, dsTheme)
                            }
                            .padding(.horizontal)
                        }
                    )
                    
                    disclosureSection(
                        isExpanded: $showingAlertSettings,
                        icon: alertIcon,
                        title: "Alert Display",
                        iconColor: .red,
                        content: {
                            VStack(alignment: .leading) {
                                TextField("Alert text", text: $alertText)
                                    .font(dsTheme.typography.body)
                                    .padding(.vertical, 4)
                                    .foregroundColor(dsTheme.colors.text)
                                    .onChange(of: alertText) { _ in
                                        updateWidget()
                                    }
                                
                                IconPicker(title: "Alert icon", selection: $alertIcon)
                                    .environment(\.dsTheme, dsTheme)
                            }
                            .padding(.horizontal)
                        }
                    )
                }
                .background(dsTheme.colors.background)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Personalization")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(red: 30/255, green: 32/255, blue: 44/255))
        }
    }
    
    // Fonction pour créer une section dépliable personnalisée
    private func disclosureSection<Content: View>(
        isExpanded: Binding<Bool>,
        icon: String,
        title: String,
        iconColor: Color,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation {
                    isExpanded.wrappedValue.toggle()
                }
            }) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                    Text(title)
                        .font(dsTheme.typography.body)
                    Spacer()
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .foregroundColor(dsTheme.colors.secondary)
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded.wrappedValue {
                Divider()
                content()
                    .padding(.vertical)
            }
        }
    }
}

struct AboutView: View {
    // Accès au thème de design
    @Environment(\.dsTheme) private var dsTheme
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("About")
                    .font(dsTheme.typography.caption)
                    .foregroundColor(dsTheme.colors.secondary)
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 5)
                
                Text("This app shows a countdown to your bedtime or wake-up time in a widget.")
                    .font(dsTheme.typography.caption)
                    .foregroundColor(dsTheme.colors.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(dsTheme.colors.background)
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(red: 30/255, green: 32/255, blue: 44/255))
        }
    }
}

struct CountdownPreview: View {
    let bedtime: Date
    let wakeupTime: Date
    let accentColor: Color
    @State private var currentTime = Date()
    @State private var opacity: Double = 1.0
    @State private var alertIconOpacity: Double = 1.0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Nouvelles propriétés personnalisables
    let bedtimeIcon: String
    let wakeupIcon: String
    let alertIcon: String
    let bedtimeText: String
    let wakeupText: String
    let alertText: String
    
    // Accès au thème de design
    @Environment(\.dsTheme) private var dsTheme
    
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
                        
                        // Interface principale
                        smallWidget
                    }
                )
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .id(currentTime) // Forcer la mise à jour de la vue
    }
    
    // Version du widget
    var smallWidget: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                
                Text(titleText)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(.white)
            }
            .padding(.top, 2)
            
            // Utilisation de GeometryReader pour adapter la taille du texte
            GeometryReader { geometry in
                Text(timeRemainingFormatted)
                    .font(dsTheme.typography.title)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            }
            .frame(height: 30)
            
            Text(subtitleText)
                .font(.system(size: 16, weight: .medium))
                .lineLimit(1)
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 2)
        }
        .padding(8)
    }
    
    // Fonction pour les éléments décoratifs
    func decorations(geometry: GeometryProxy) -> some View {
        Group {
            if showBedtimeCountdown {
                // Aucune décoration pour le thème de sommeil
                EmptyView()
            } else if !showBedtimeCountdown && !timeIsRunningOut() {
                // Aucune décoration (suppression de l'icône soleil)
                EmptyView()
            } else if timeIsRunningOut() {
                // Icône d'alerte pour manque de sommeil
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
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
            return .red
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
            return ""
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
    
    // Vérifie si l'heure du coucher est dépassée de 30 minutes
    private func timeIsRunningOut() -> Bool {
        if showBedtimeCountdown {
            return false // Pas d'alerte avant l'heure du coucher
        }
        
        let calendar = Calendar.current
        
        // Obtenir l'heure de coucher pour aujourd'hui
        var bedtimeComponents = calendar.dateComponents([.year, .month, .day], from: currentTime)
        let bedtimeTimeComponents = calendar.dateComponents([.hour, .minute], from: bedtime)
        bedtimeComponents.hour = bedtimeTimeComponents.hour
        bedtimeComponents.minute = bedtimeTimeComponents.minute
        let bedtimeToday = calendar.date(from: bedtimeComponents)!
        
        // Ajouter 30 minutes à l'heure du coucher
        let bedtimePlusThirtyMin = calendar.date(byAdding: .minute, value: 30, to: bedtimeToday)!
        
        // Vérifier si l'heure actuelle est après l'heure du coucher + 30 min
        // mais avant l'heure du réveil
        let isAfterBedtimePlusThirty = currentTime > bedtimePlusThirtyMin
        
        // Vérifier si le coucher était hier (si on est dans une nouvelle journée)
        let isNewDay = bedtimeToday > currentTime
        
        // Si c'est une nouvelle journée, vérifier si on est dans les 30 minutes après minuit
        let isWithinThirtyMinAfterMidnight = isNewDay && (calendar.dateComponents([.hour, .minute], from: currentTime).hour! * 60 + calendar.dateComponents([.hour, .minute], from: currentTime).minute! < 30)
        
        // L'alerte s'affiche seulement si on est après l'heure du coucher + 30 min
        // ou si c'est une nouvelle journée et on est dans les 30 minutes après minuit
        return isAfterBedtimePlusThirty || isWithinThirtyMinAfterMidnight
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
        
        // Format pour le texte d'alerte
        return String(format: "%d hours and %d minutes", hours, minutes)
    }
    
    // Fonction qui calcule le temps restant (utilisée pour le décompte)
    private func calculateTimeRemaining(to targetTime: Date) -> TimeInterval {
        let calendar = Calendar.current
        
        // Créer une date cible pour aujourd'hui avec les heures et minutes de la cible
        var targetComponents = calendar.dateComponents([.year, .month, .day], from: currentTime)
        let targetTimeComponents = calendar.dateComponents([.hour, .minute], from: targetTime)
        targetComponents.hour = targetTimeComponents.hour
        targetComponents.minute = targetTimeComponents.minute
        targetComponents.second = 0 // Réinitialiser les secondes à zéro
        
        var targetDate = calendar.date(from: targetComponents)!
        
        // Si la cible est déjà passée aujourd'hui, ajouter un jour
        if targetDate < currentTime {
            targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate)!
        }
        
        return targetDate.timeIntervalSince(currentTime)
    }
    
    // Format du temps restant affiché dans le widget (sans secondes)
    private var timeRemainingFormatted: String {
        let timeRemaining = showBedtimeCountdown ? 
            calculateTimeRemaining(to: bedtime) : 
            calculateTimeRemaining(to: wakeupTime)
        
        // Formater avec les heures et minutes uniquement
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        
        return String(format: "%dh %02dm", hours, minutes)
    }
    
    // Format de l'heure cible affichée en sous-titre
    private var targetTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: showBedtimeCountdown ? bedtime : wakeupTime)
    }
}

// Composant pour sélectionner une icône
struct IconPicker: View {
    let title: String
    @Binding var selection: String
    @Environment(\.dsTheme) private var dsTheme
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
                .font(dsTheme.typography.caption)
                .foregroundColor(dsTheme.colors.secondary)
            
            Button(action: {
                showingIconSheet = true
            }) {
                HStack {
                    Image(systemName: selection)
                        .font(.title2)
                        .foregroundColor(dsTheme.colors.text)
                    Spacer()
                    Text("Change")
                        .foregroundColor(dsTheme.colors.primary)
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
                                            .background(icon == selection ? dsTheme.colors.primary.opacity(0.2) : Color.clear)
                                            .cornerRadius(10)
                                        Text(iconName(for: icon))
                                            .font(dsTheme.typography.caption)
                                            .foregroundColor(dsTheme.colors.secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                    .scrollIndicators(.visible)
                    .navigationTitle("Select Icon")
                    .foregroundColor(dsTheme.colors.text)
                    .background(dsTheme.colors.background)
                    .navigationBarItems(trailing: Button("Cancel") {
                        showingIconSheet = false
                    })
                    .accentColor(dsTheme.colors.primary)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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

// Extension pour améliorer le comportement de ScrollView
// Cette extension résout le problème de décalage qui peut se produire
// lorsque les ScrollViews sont présentées dans des feuilles modales
extension UIScrollView {
    open override func didMoveToWindow() {
        super.didMoveToWindow()
        
        // Réinitialiser le décalage de contenu lors de l'apparition dans une nouvelle fenêtre
        // Cela corrige les problèmes de défilement qui peuvent survenir quand une sheet est présentée
        if window != nil {
            flashScrollIndicators()
        }
    }
}
