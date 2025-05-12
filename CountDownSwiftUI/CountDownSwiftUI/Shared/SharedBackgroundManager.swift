// SharedBackgroundManager.swift
// CountDownSwiftUI
//
// Created by Sharik Mohamed on 24/03/2025.
//

import Foundation
import SwiftUI
import UIKit

// Définir un framework commun accessible à la fois par l'application et l'extension de widget
public class SharedBackgroundManager {
    public static let shared = SharedBackgroundManager()
    private let fileManager = FileManager.default
    
    public init() {}
    
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
    
    // Enregistrer une image dans le dossier partagé
    public func saveImage(_ image: UIImage, withName name: String) -> String? {
        guard let imagesDirectory = sharedImagesDirectory else {
            return nil
        }
        
        // Générer un nom de fichier unique basé sur le nom fourni et la date
        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueName = "\(name)_\(timestamp)"
        let fileURL = imagesDirectory.appendingPathComponent("\(uniqueName).jpg")
        
        // Convertir l'image en données JPEG
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
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
    public func loadImage(named name: String) -> UIImage? {
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
    public func deleteImage(named name: String) -> Bool {
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
    public func loadSwiftUIImage(named name: String) -> Image? {
        if let uiImage = loadImage(named: name) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
} 