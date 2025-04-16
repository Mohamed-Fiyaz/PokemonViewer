//
//  ARViewModel.swift
//  Pokemon
//
//  Created by Mohamed Fiyaz on 13/04/25.
//

import Foundation
import Combine
import RealityKit
import ARKit


class ARViewModel: ObservableObject {
    @Published var modelEntity: ModelEntity?
    @Published var isLoading = false
    @Published var error: String?
    @Published var isPlacementReady = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadModel(for pokemon: Pokemon) {
        isLoading = true
        error = nil
        isPlacementReady = false
        
        print("Loading 3D model for: \(pokemon.name) (ID: \(pokemon.id))")
        
        let modelName = pokemon.name
        
        // Make sure this runs on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "usdz") else {
                self.handleModelError(message: "Model not found: \(modelName).usdz")
                return
            }
            
            print("Found model at: \(modelURL.path)")
            
            Entity.loadAsync(contentsOf: modelURL)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        self.handleModelError(message: "Failed to load model: \(error.localizedDescription)")
                    }
                }, receiveValue: { entity in
                    let containerEntity = ModelEntity()
                    containerEntity.addChild(entity)
                    containerEntity.scale = SIMD3<Float>(0.1, 0.1, 0.1)
                    containerEntity.generateCollisionShapes(recursive: true)
                    
                    self.modelEntity = containerEntity
                    self.isPlacementReady = true
                    self.isLoading = false
                    self.error = nil
                    
                    print("Successfully loaded model: \(modelName).usdz")
                })
                .store(in: &self.cancellables)
        }
    }
    
    private func handleModelError(message: String) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.error = message
            print("AR Model Error: \(message)")
        }
    }
}
