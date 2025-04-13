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
    
    // Cache for already checked model availability
    private var modelAvailabilityCache: [Int: Bool] = [:]
    
    // The base URL for the API
    private let apiEndpoint = "https://pokemon-3d-api.onrender.com/v1/pokemon"
    
    // Function to check if a model is available for a specific pokemon
    func checkModelAvailability(pokemonId: Int) -> AnyPublisher<Bool, Never> {
        // If we have cached the result, return it immediately
        if let isAvailable = modelAvailabilityCache[pokemonId] {
            return Just(isAvailable).eraseToAnyPublisher()
        }
        
        // Create a subject to publish the result
        let subject = PassthroughSubject<Bool, Never>()
        
        // Fetch the data from the API
        fetchPokemon3DData { [weak self] result in
            switch result {
            case .success(let pokemonData):
                // Look for a matching Pokémon ID
                let isAvailable = pokemonData.contains { pokemon in
                    pokemon.id == pokemonId
                }
                
                // Cache the result
                self?.modelAvailabilityCache[pokemonId] = isAvailable
                subject.send(isAvailable)
                subject.send(completion: .finished)
                
            case .failure(_):
                // On failure, assume the model is not available
                subject.send(false)
                subject.send(completion: .finished)
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    // Overload for checking by name (which actually just converts to ID)
    func checkModelAvailability(pokemonName: String) -> AnyPublisher<Bool, Never> {
        // For this implementation, we'll assume pokemonName is not numeric
        // and we won't handle the case where it is a valid Pokemon ID
        // This is just a fallback to maintain compatibility with existing code
        
        // Create a subject to publish the result
        let subject = PassthroughSubject<Bool, Never>()
        
        // Without a proper ID, we can't reliably check, so we'll just assume false
        // In a real implementation, you would want to map the name to an ID
        subject.send(false)
        subject.send(completion: .finished)
        
        return subject.eraseToAnyPublisher()
    }
    
    // Function to get the model URL for a given Pokémon ID
    func getModelURL(pokemonId: Int) -> URL? {
        // Format using the documented structure with ID numbers
        return URL(string: "https://raw.githubusercontent.com/Sudhanshu-Ambastha/Pokemon-3D/main/models/glb/regular/\(pokemonId).glb")
    }
    
    // Overload to maintain compatibility with existing code
    func getModelURL(pokemonName: String) -> URL? {
        if let id = Int(pokemonName) {
            return getModelURL(pokemonId: id)
        }
        
        // Without an ID, we can't generate a URL
        return nil
    }
    
    // Fetches all 3D Pokémon data
    private func fetchPokemon3DData(completion: @escaping (Result<[Pokemon3DResponse], Error>) -> Void) {
        guard let url = URL(string: apiEndpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
                return
            }
            
            do {
                let pokemonData = try JSONDecoder().decode([Pokemon3DResponse].self, from: data)
                completion(.success(pokemonData))
            } catch {
                print("JSON decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Function to load a GLB model from a URL
    func loadGLBModel(from url: URL, completion: @escaping (Result<ModelEntity, Error>) -> Void) {
        // Create a download task
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            // Check for errors
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let localURL = localURL else {
                completion(.failure(NSError(domain: "No local URL", code: 0, userInfo: nil)))
                return
            }
            
            // Load the model entity from the downloaded file
            do {
                let modelEntity = try ModelEntity.loadModel(contentsOf: localURL)
                
                // Scale the model appropriately for AR
                modelEntity.scale = SIMD3<Float>(0.1, 0.1, 0.1)
                
                // Complete with success
                completion(.success(modelEntity))
            } catch {
                completion(.failure(error))
            }
        }
        
        // Start the download
        task.resume()
    }
}
