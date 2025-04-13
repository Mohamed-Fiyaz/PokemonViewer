//
//  ARViewModel.swift
//  PokemonViewer
//
//  Created by Mohamed Fiyaz on 13/04/25.
//

import Foundation
import Combine
import ARKit
import RealityKit

class ARViewModel: ObservableObject {
    @Published var modelEntity: ModelEntity?
    @Published var isLoading = false
    @Published var error: String?
    
    private let modelService = Pokemon3DModelService()
    private var cancellables = Set<AnyCancellable>()
    
    func loadModel(for pokemon: Pokemon) {
        isLoading = true
        error = nil
        
        // Check if the model exists using the Pokemon ID
        print("Checking model for: \(pokemon.name) (ID: \(pokemon.id))")
        modelService.checkModelAvailability(pokemonId: pokemon.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] available in
                guard let self = self else { return }
                
                if !available {
                    self.isLoading = false
                    self.error = "3D model for \(pokemon.name) is not available"
                    print("Model not available for: \(pokemon.name) (ID: \(pokemon.id))")
                } else {
                    print("Model is available for: \(pokemon.name) (ID: \(pokemon.id)), downloading...")
                    if let modelURL = self.modelService.getModelURL(pokemonId: pokemon.id) {
                        self.downloadAndProcessGLBModel(url: modelURL, pokemonName: pokemon.name)
                    } else {
                        self.isLoading = false
                        self.error = "Failed to create model URL for \(pokemon.name)"
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func downloadAndProcessGLBModel(url: URL, pokemonName: String) {
        print("Starting GLB download from: \(url.absoluteString)")
        
        modelService.loadGLBModel(from: url) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let modelEntity):
                print("Successfully loaded model for: \(pokemonName)")
                self.modelEntity = modelEntity
                
            case .failure(let error):
                print("Failed to load model: \(error.localizedDescription)")
                self.error = "Failed to load model: \(error.localizedDescription)"
            }
        }
    }
}
