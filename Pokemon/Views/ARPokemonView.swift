//
//  ARPokemonView.swift
//  Pokemon
//
//  Created by Mohamed Fiyaz on 13/04/25.
//

import SwiftUI
import ARKit
import RealityKit

struct ARPokemonView: View {
    let pokemon: Pokemon
    @StateObject private var viewModel = ARViewModel()
    @State private var placementMode = true
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(pokemon: pokemon,
                            modelEntity: viewModel.modelEntity,
                            placementMode: $placementMode,
                            isPlacementReady: viewModel.isPlacementReady)
            .edgesIgnoringSafeArea(.all)
            
            if viewModel.isLoading {
                LoadingOverlay()
            } else if let error = viewModel.error {
                ErrorOverlay(message: error) {
                    viewModel.loadModel(for: pokemon)
                }
            } else if placementMode && viewModel.isPlacementReady {
                PlacementInstructionView()
            } else if !placementMode {
                ARControlsView(placementMode: $placementMode)
            }
        }
        .navigationTitle("\(pokemon.name) in AR")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Delay loading to ensure AR view is properly initialized
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                viewModel.loadModel(for: pokemon)
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    let pokemon: Pokemon
    let modelEntity: ModelEntity?
    @Binding var placementMode: Bool
    let isPlacementReady: Bool
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        // Apply safer configuration
        let options: ARSession.RunOptions = [.removeExistingAnchors, .resetTracking]
        arView.session.run(configuration, options: options)
        
        // Add coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(coachingOverlay)
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        // Add pinch gesture for scaling
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        // Add rotation gesture
        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:)))
        arView.addGestureRecognizer(rotationGesture)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.arView = uiView
        context.coordinator.modelEntity = modelEntity
        context.coordinator.placementMode = placementMode
        context.coordinator.isPlacementReady = isPlacementReady
        
        // If we're entering placement mode and we have a model,
        // we need to remove any existing anchors
        if placementMode && modelEntity != nil && isPlacementReady {
            context.coordinator.resetScene()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: ARViewContainer
        var arView: ARView?
        var modelEntity: ModelEntity?
        var placementMode: Bool = true
        var isPlacementReady: Bool = false
        var anchorEntity: AnchorEntity?
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        func resetScene() {
            guard let arView = arView else { return }
            
            // Remove all anchors from the scene
            arView.scene.anchors.removeAll()
            self.anchorEntity = nil
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView,
                  placementMode,
                  isPlacementReady,
                  let modelEntity = modelEntity?.clone(recursive: true) else { return }
            
            // Get tap location
            let tapLocation = gesture.location(in: arView)
            
            // Raycast to find a surface
            let raycastResults = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
            
            if let result = raycastResults.first {
                // Create anchor at hit location
                let anchorEntity = AnchorEntity(world: result.worldTransform)
                
                // Add model to anchor
                anchorEntity.addChild(modelEntity)
                
                // Add to scene
                arView.scene.addAnchor(anchorEntity)
                self.anchorEntity = anchorEntity
                
                // Exit placement mode
                DispatchQueue.main.async {
                    self.placementMode = false
                    self.parent.placementMode = false
                }
                
            } else {
                // If no surface found, place in front of the camera as fallback
                placeFallbackModel(modelEntity)
            }
        }
        
        func placeFallbackModel(_ modelEntity: ModelEntity) {
            guard let arView = arView else { return }
            
            // Place the model 1 meter in front of the camera
            let cameraTransform = arView.cameraTransform
            var position = cameraTransform.translation
            let forward = cameraTransform.matrix.columns.2
            position += SIMD3<Float>(-forward.x, -forward.y, -forward.z) * 1.0
            
            // Create anchor at the calculated position
            let anchorEntity = AnchorEntity(world: position)
            
            // Add model to anchor
            anchorEntity.addChild(modelEntity)
            
            // Add to scene
            arView.scene.addAnchor(anchorEntity)
            self.anchorEntity = anchorEntity
            
            // Exit placement mode
            DispatchQueue.main.async {
                self.placementMode = false
                self.parent.placementMode = false
            }
            
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let anchorEntity = self.anchorEntity, !placementMode else { return }
            
            switch gesture.state {
            case .changed:
                let scale = Float(gesture.scale)
                // Adjust scale with limits
                if let modelEntity = anchorEntity.children.first {
                    let currentScale = modelEntity.scale
                    let maxScale: Float = 3.0
                    let minScale: Float = 0.1
                    
                    let newScale = SIMD3<Float>(
                        min(max(currentScale.x * scale, minScale), maxScale),
                        min(max(currentScale.y * scale, minScale), maxScale),
                        min(max(currentScale.z * scale, minScale), maxScale)
                    )
                    
                    modelEntity.scale = newScale
                }
                
                // Reset gesture scale
                gesture.scale = 1.0
            default:
                break
            }
        }
        
        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let anchorEntity = self.anchorEntity, !placementMode else { return }
            
            switch gesture.state {
            case .changed:
                let rotation = Float(gesture.rotation)
                
                // Get current transform
                if let modelEntity = anchorEntity.children.first {
                    // Create rotation transform around Y axis (up)
                    var transform = modelEntity.transform
                    transform.rotation = simd_quatf(angle: rotation, axis: SIMD3<Float>(0, 1, 0)) * transform.rotation
                    
                    // Apply new transform
                    modelEntity.transform = transform
                }
                
                // Reset gesture rotation
                gesture.rotation = 0
            default:
                break
            }
        }
    }
}

struct LoadingOverlay: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Loading Pokémon model...")
                .font(.headline)
        }
        .frame(width: 250, height: 100)
        .background(Color.white.opacity(0.8))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct ErrorOverlay: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Error")
                .font(.headline)
            
            Text(message)
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: retryAction) {
                Text("Retry")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(width: 250)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct PlacementInstructionView: View {
    var body: some View {
        Text("Tap on a surface to place the Pokémon")
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(10)
            .padding(.bottom, 20)
    }
}

struct ARControlsView: View {
    @Binding var placementMode: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: {
                placementMode = true
            }) {
                VStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 22))
                    Text("Reset")
                        .font(.caption)
                }
                .frame(width: 60, height: 60)
                .background(Color.white)
                .foregroundColor(.blue)
                .cornerRadius(30)
                .shadow(radius: 3)
            }
            
            Text("Pinch to scale • Rotate with two fingers")
                .font(.caption)
                .padding(8)
                .background(Color.white.opacity(0.8))
                .cornerRadius(8)
        }
        .padding(.bottom, 20)
    }
}
