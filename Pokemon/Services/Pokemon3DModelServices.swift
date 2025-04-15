//
//  Pokemon3DModelService.swift
//  PokemonViewer
//
//  Created by Mohamed Fiyaz on 13/04/25.
//

import Foundation
import Combine
import RealityKit

class Pokemon3DModelService {
    
    // Structure matching the API response from Pokémon 3D API
    struct Pokemon3DResponse: Codable {
        let id: Int
        let forms: [PokemonForm]
        
        struct PokemonForm: Codable {
            let name: String
            let model: String
            let formName: String
        }
    }
    
    // Cache for already checked model availability and downloaded models
    private var modelAvailabilityCache: [Int: Bool] = [:]
    private var modelCache: [Int: ModelEntity] = [:]
    
    // The base URL for the API
    private let apiEndpoint = "https://pokemon-3d-api.onrender.com/v1/pokemon"
    
    // Fallback model URLs
    private let fallbackModelBaseURL = "https://raw.githubusercontent.com/Sudhanshu-Ambastha/Pokemon-3D/main/models/glb/regular"
    private let alternateModelBaseURL = "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Box/glTF-Binary/Box.glb"
    
    // Function to check if a model is available for a specific pokemon
    func checkModelAvailability(pokemonId: Int) -> AnyPublisher<Bool, Never> {
        // If we have cached the result, return it immediately
        if let isAvailable = modelAvailabilityCache[pokemonId] {
            return Just(isAvailable).eraseToAnyPublisher()
        }
        
        // Always return true to avoid API calls that might fail
        // Instead, we'll handle any actual availability issues during download
        let subject = PassthroughSubject<Bool, Never>()
        subject.send(true)
        subject.send(completion: .finished)
        
        // Cache the result
        modelAvailabilityCache[pokemonId] = true
        
        return subject.eraseToAnyPublisher()
    }
    
    // Simplified version that always returns true to avoid crashes
    func checkModelAvailability(pokemonName: String) -> AnyPublisher<Bool, Never> {
        let subject = PassthroughSubject<Bool, Never>()
        subject.send(true)
        subject.send(completion: .finished)
        return subject.eraseToAnyPublisher()
    }
    
    // Function to get the model URL for a given Pokémon ID
    func getModelURL(pokemonId: Int) -> URL? {
        // First try the primary URL format
        if let primaryURL = URL(string: "\(fallbackModelBaseURL)/\(pokemonId).glb") {
            return primaryURL
        }
        
        // Fallback to a generic box model that's guaranteed to work
        return URL(string: alternateModelBaseURL)
    }
    
    // Overload to maintain compatibility with existing code
    func getModelURL(pokemonName: String) -> URL? {
        if let id = Int(pokemonName) {
            return getModelURL(pokemonId: id)
        }
        
        // Fallback to a generic box model
        return URL(string: alternateModelBaseURL)
    }
    
    // Function to load a GLB model from a URL with better error handling
    func loadGLBModel(from url: URL, completion: @escaping (Result<ModelEntity, Error>) -> Void) {
        // Check if we have the model in cache
        if let id = extractPokemonId(from: url), let cachedModel = modelCache[id] {
            completion(.success(cachedModel.clone(recursive: true)))
            return
        }
        
        print("Attempting to download model from: \(url.absoluteString)")
        
        // Create a download task with a timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 15 // 15 seconds timeout
        let session = URLSession(configuration: config)
        
        let task = session.downloadTask(with: url) { [weak self] localURL, response, error in
            guard let self = self else { return }
            
            // Check for network errors
            if let error = error {
                print("Download error: \(error.localizedDescription)")
                self.handleModelLoadingError(completion: completion)
                return
            }
            
            guard let localURL = localURL,
                  let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Invalid response or missing file")
                self.handleModelLoadingError(completion: completion)
                return
            }
            
            // Check file size to ensure it's a valid model
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: localURL.path)
                let fileSize = fileAttributes[.size] as? NSNumber ?? 0
                
                // If file is too small (less than 1KB), it's probably not a valid model
                if fileSize.intValue < 1024 {
                    print("File too small, likely not a valid model: \(fileSize) bytes")
                    self.handleModelLoadingError(completion: completion)
                    return
                }
                
                // Try to load the model
                self.loadModel(from: localURL, sourceURL: url, completion: completion)
            } catch {
                print("File attribute error: \(error.localizedDescription)")
                self.handleModelLoadingError(completion: completion)
            }
        }
        
        // Start the download
        task.resume()
    }
    
    // Helper to actually load the model with error handling
    private func loadModel(from localURL: URL, sourceURL: URL, completion: @escaping (Result<ModelEntity, Error>) -> Void) {
        do {
            // Try to load the model entity from the downloaded file
            let modelEntity = try ModelEntity.loadModel(contentsOf: localURL)
            
            // Scale the model appropriately for AR
            modelEntity.scale = SIMD3<Float>(0.1, 0.1, 0.1)
            
            // Cache the model if possible
            if let id = extractPokemonId(from: sourceURL) {
                modelCache[id] = modelEntity.clone(recursive: true)
            }
            
            // Complete with success
            DispatchQueue.main.async {
                completion(.success(modelEntity))
            }
        } catch {
            print("Model loading error: \(error.localizedDescription)")
            handleModelLoadingError(completion: completion)
        }
    }
    
    // Helper to extract Pokemon ID from URL
    private func extractPokemonId(from url: URL) -> Int? {
        // Try to extract ID from the URL path
        let filename = url.lastPathComponent
        let idString = filename.components(separatedBy: ".").first ?? ""
        return Int(idString)
    }
    
    // Fallback handler for when model loading fails
    private func handleModelLoadingError(completion: @escaping (Result<ModelEntity, Error>) -> Void) {
        // Create a simple fallback model (a colored box)
        DispatchQueue.main.async {
            let boxSize: Float = 0.1
            let box = ModelEntity(mesh: .generateBox(size: boxSize))
            
            // Add some color to make it obvious it's a fallback
            var material = SimpleMaterial()
            material.baseColor = .color(.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.8))
            box.model?.materials = [material]
            
            // Add a text label to indicate it's a fallback
            let textMesh = MeshResource.generateText("Model\nUnavailable",
                                                    extrusionDepth: 0.01,
                                                    font: .systemFont(ofSize: 0.05),
                                                    containerFrame: .zero,
                                                    alignment: .center)
            
            let textEntity = ModelEntity(mesh: textMesh)
            textEntity.scale = SIMD3<Float>(0.5, 0.5, 0.5)
            textEntity.position = SIMD3<Float>(0, boxSize/2 + 0.05, 0)
            
            var textMaterial = SimpleMaterial()
            textMaterial.baseColor = .color(.white)
            textEntity.model?.materials = [textMaterial]
            
            box.addChild(textEntity)
            
            completion(.success(box))
        }
    }
}
