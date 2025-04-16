//
//  pokemon.swift
//  Pokemon
//
//  Created by Mohamed Fiyaz on 13/04/25.
//

import Foundation

struct Pokemon: Identifiable, Codable {
    let id: Int
    let name: String
    let url: String
    var imageUrl: String {
        return "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png"
    }
    
    // For local 3D model access
    var localModelName: String {
        return "\(id)"  // Assuming models are named by ID, like "1.usdz", "2.usdz", etc.
    }
}
