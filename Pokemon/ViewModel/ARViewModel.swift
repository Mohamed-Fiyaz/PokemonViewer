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
    @Published var isPlacementReady = false
    
    private let modelService = Pokemon3DModelService()
    private var cancellables = Set<AnyCancellable>()
    
    func loadModel(for pokemon: Pokemon) {
        isLoading = true
        error = nil
        isPlacementReady = false
        
        // Check if the model exists using the Pokemon ID
        print("Checking model for: \(pokemon.name) (ID: \(pokemon.id))")
        
        // Use a timeout for the availability check
        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self = self, self.isLoading else { return }
            
            // Timeout occurred, proceed with download anyway
            print("Availability check timed out for: \(pokemon.name), attempting download anyway")
            self.proceedWithModelDownload(pokemon: pokemon)
        }
        
        modelService.checkModelAvailability(pokemonId: pokemon.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] available in
                guard let self = self else { return }
                
                // Cancel the timeout timer
                timeoutTimer.invalidate()
                
                if !available {
                    // Even if the model is not officially available, we'll try downloading it anyway
                    // but we'll log the information
                    print("Model reported as unavailable for: \(pokemon.name) (ID: \(pokemon.id)), attempting anyway")
                }
                
                self.proceedWithModelDownload(pokemon: pokemon)
            }
            .store(in: &cancellables)
    }
    
    private func proceedWithModelDownload(pokemon: Pokemon) {
        print("Attempting to download model for: \(pokemon.name) (ID: \(pokemon.id))")
        
        if let modelURL = self.modelService.getModelURL(pokemonId: pokemon.id) {
            self.downloadAndProcessGLBModel(url: modelURL, pokemonName: pokemon.name)
        } else {
            self.handleModelError(message: "Failed to create model URL for \(pokemon.name)")
        }
    }
    
    private func downloadAndProcessGLBModel(url: URL, pokemonName: String) {
        print("Starting GLB download from: \(url.absoluteString)")
        
        // Set a timeout for the entire download process
        let downloadTimeout = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { [weak self] _ in
            guard let self = self, self.isLoading else { return }
            
            // Timeout occurred
            self.handleModelError(message: "Download timed out for \(pokemonName)")
        }
        
        modelService.loadGLBModel(from: url) { [weak self] result in
            guard let self = self else { return }
            
            // Cancel the timeout timer
            downloadTimeout.invalidate()
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let modelEntity):
                    print("Successfully loaded model for: \(pokemonName)")
                    self.modelEntity = modelEntity
                    self.isPlacementReady = true
                    self.error = nil
                    
                case .failure(let error):
                    self.handleModelError(message: "Failed to load model: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleModelError(message: String) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.error = message
            print(message)
        }
    }
}
