// BackgroundImageManager.swift
// CountDownSwiftUI
//
// Created by Sharik Mohamed on 24/03/2025.
//

import Foundation
import SwiftUI
import UIKit

public class BackgroundImageManager {
    public static let shared = BackgroundImageManager()
    private let fileManager = FileManager.default
    
    private init() {}
    
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
        guard let imagesDirectory = createImagesDirectoryIfNeeded() else {
            print("❌ Failed to create or access images directory")
            return nil
        }
        
        // Générer un nom de fichier unique basé sur le nom fourni et la date
        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueName = "\(name)_\(timestamp)"
        let fileURL = imagesDirectory.appendingPathComponent("\(uniqueName).jpg")
        
        print("📝 Saving image to \(fileURL.path)")
        
        // Convertir l'image en données JPEG
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to JPEG data")
            return nil
        }
        
        // Enregistrer les données dans le fichier
        do {
            try imageData.write(to: fileURL)
            print("✅ Successfully saved image to \(fileURL.path)")
            
            // Mettre à jour UserDefaults avec le nom du fichier
            UserDefaults(suiteName: "group.com.tempest.CountDownSwiftUI")?.setValue(uniqueName, forKey: "backgroundImageName")
            UserDefaults(suiteName: "group.com.tempest.CountDownSwiftUI")?.setValue(true, forKey: "useCustomBackground")
            
            return uniqueName
        } catch {
            print("❌ Error saving image: \(error)")
            return nil
        }
    }
    
    // Méthode utilitaire pour créer le dossier d'images s'il n'existe pas
    private func createImagesDirectoryIfNeeded() -> URL? {
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.tempest.CountDownSwiftUI") else {
            print("❌ Could not access app group container")
            return nil
        }
        
        let imagesURL = containerURL.appendingPathComponent("backgroundImages", isDirectory: true)
        print("📁 Images directory path: \(imagesURL.path)")
        
        // Créer le dossier s'il n'existe pas
        if !fileManager.fileExists(atPath: imagesURL.path) {
            print("📁 Creating images directory")
            do {
                try fileManager.createDirectory(at: imagesURL, withIntermediateDirectories: true, attributes: nil)
                print("✅ Successfully created images directory")
            } catch {
                print("❌ Error creating images directory: \(error)")
                return nil
            }
        } else {
            print("✅ Images directory already exists")
        }
        
        return imagesURL
    }
    
    // Récupérer une image depuis le dossier partagé
    public func loadImage(named name: String) -> UIImage? {
        guard !name.isEmpty else {
            print("❌ Empty image name provided")
            return nil
        }
        
        guard let imagesDirectory = createImagesDirectoryIfNeeded() else {
            print("❌ Could not access images directory")
            return nil
        }
        
        let fileURL = imagesDirectory.appendingPathComponent("\(name).jpg")
        print("🔍 Loading image from \(fileURL.path)")
        
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                let imageData = try Data(contentsOf: fileURL)
                if let image = UIImage(data: imageData) {
                    print("✅ Successfully loaded image")
                    return image
                } else {
                    print("❌ Failed to create UIImage from data")
                }
            } catch {
                print("❌ Error loading image: \(error)")
            }
        } else {
            print("❌ Image file doesn't exist at path: \(fileURL.path)")
            do {
                let files = try fileManager.contentsOfDirectory(atPath: imagesDirectory.path)
                print("📁 Directory contents: \(files)")
            } catch {
                print("❌ Error listing directory: \(error)")
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