// BackgroundImageManager.swift
// CountDownSwiftUI
//
// Created by Sharik Mohamed on 24/03/2025.
//

import Foundation
import SwiftUI
import UIKit

class BackgroundImageManager {
    static let shared = BackgroundImageManager()
    private let fileManager = FileManager.default
    private var imageCache: [String: UIImage] = [:]
    private let cacheLock = NSLock()
    
    // Limites de taille pour les widgets
    private let maxWidgetImageSize = CGSize(width: 800, height: 600)
    
    private init() {
        // Vérifier et créer le dossier d'images au démarrage
        ensureImageDirectoryExists()
    }
    
    // Chemin vers le dossier partagé des images
    private var sharedImagesDirectory: URL? {
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.tempest.CountDownSwiftUI") else {
            return nil
        }
        let imagesURL = containerURL.appendingPathComponent("backgroundImages", isDirectory: true)
        return imagesURL
    }
    
    // Assurer que le dossier d'images existe
    private func ensureImageDirectoryExists() {
        guard let imagesDirectory = sharedImagesDirectory else {
            return
        }
        
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            do {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            } catch {
                // Silencieux en production
            }
        }
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
    
    // Vérifie si l'image est dans les limites acceptables pour un widget
    private func isImageSizeAcceptable(_ image: UIImage) -> Bool {
        let imageArea = image.size.width * image.size.height
        let maxArea = maxWidgetImageSize.width * maxWidgetImageSize.height
        return imageArea <= maxArea
    }
    
    // Enregistrer une image dans le dossier partagé
    func saveImage(_ image: UIImage, withName name: String) -> String? {
        guard let imagesDirectory = sharedImagesDirectory else {
            return nil
        }
        
        // Créer le dossier s'il n'existe pas
        ensureImageDirectoryExists()
        
        // Vérifier si l'image est trop grande
        var imageToSave = image
        if !isImageSizeAcceptable(image) {
            // Redimensionner l'image pour le widget
            imageToSave = resizeImage(image, targetSize: maxWidgetImageSize)
        }
        
        // Générer un nom de fichier unique basé sur le nom fourni et la date
        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueName = "\(name)_\(timestamp)"
        let fileURL = imagesDirectory.appendingPathComponent("\(uniqueName).jpg")
        
        // Convertir l'image en données JPEG avec une compression plus forte
        guard let imageData = imageToSave.jpegData(compressionQuality: 0.6) else {
            return nil
        }
        
        // Enregistrer les données dans le fichier
        do {
            try imageData.write(to: fileURL)
            
            // Stocker dans le cache
            cacheLock.lock()
            imageCache[uniqueName] = imageToSave
            cacheLock.unlock()
            
            return uniqueName
        } catch {
            return nil
        }
    }
    
    // Récupérer une image depuis le dossier partagé
    func loadImage(named name: String) -> UIImage? {
        guard !name.isEmpty else {
            return nil
        }
        
        // Vérifier le cache d'abord
        cacheLock.lock()
        if let cachedImage = imageCache[name] {
            cacheLock.unlock()
            return cachedImage
        }
        cacheLock.unlock()
        
        guard let imagesDirectory = sharedImagesDirectory else {
            return nil
        }
        
        // Essayer les différentes extensions possibles
        let possibleExtensions = ["jpg", "jpeg", "png"]
        
        for ext in possibleExtensions {
            let fileURL = imagesDirectory.appendingPathComponent("\(name).\(ext)")
            
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    let imageData = try Data(contentsOf: fileURL)
                    if var image = UIImage(data: imageData) {
                        
                        // Vérifier si l'image est trop grande pour le widget
                        if !isImageSizeAcceptable(image) {
                            image = resizeImage(image, targetSize: maxWidgetImageSize)
                        }
                        
                        // Ajouter au cache
                        cacheLock.lock()
                        imageCache[name] = image
                        cacheLock.unlock()
                        
                        return image
                    }
                } catch {
                    // Erreur silencieuse
                }
            }
        }
        
        return nil
    }
    
    // Supprimer une image du dossier partagé
    func deleteImage(named name: String) -> Bool {
        guard !name.isEmpty, let imagesDirectory = sharedImagesDirectory else {
            return false
        }
        
        // Supprimer du cache
        cacheLock.lock()
        imageCache.removeValue(forKey: name)
        cacheLock.unlock()
        
        // Essayer de supprimer avec toutes les extensions possibles
        let possibleExtensions = ["jpg", "jpeg", "png"]
        var success = false
        
        for ext in possibleExtensions {
            let fileURL = imagesDirectory.appendingPathComponent("\(name).\(ext)")
            
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    try fileManager.removeItem(at: fileURL)
                    success = true
                } catch {
                    // Erreur silencieuse
                }
            }
        }
        
        return success
    }
    
    // Récupérer une Image SwiftUI depuis le dossier partagé
    func loadSwiftUIImage(named name: String) -> Image? {
        if let uiImage = loadImage(named: name) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    // Nettoyer le cache d'images
    func clearCache() {
        cacheLock.lock()
        imageCache.removeAll()
        cacheLock.unlock()
    }
    
    // Vérifier l'espace disponible dans le stockage partagé
    func checkAvailableSpace() -> Int64 {
        guard let imagesDirectory = sharedImagesDirectory else {
            return 0
        }
        
        do {
            let resourceValues = try imagesDirectory.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            if let capacity = resourceValues.volumeAvailableCapacity {
                return Int64(capacity)
            }
        } catch {
            // Erreur silencieuse
        }
        
        return 0
    }
} 

