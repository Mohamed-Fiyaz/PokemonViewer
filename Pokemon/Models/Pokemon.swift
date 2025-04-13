//
//  pokemon.swift
//  PokemonViewer
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
    
    // For 3D model access - corrected URL format based on repository documentation
    var modelUrl: URL? {
        // Use the ID number for the file name, not the Pokémon name
        return URL(string: "https://raw.githubusercontent.com/Sudhanshu-Ambastha/Pokemon-3D/main/models/glb/regular/\(id).glb")
    }
}
