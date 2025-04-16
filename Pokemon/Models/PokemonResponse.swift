//
//  PokemonResponse.swift
//  Pokemon
//
//  Created by Mohamed Fiyaz on 13/04/25.
//

import Foundation

struct PokemonResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [PokemonResult]
}

struct PokemonResult: Codable {
    let name: String
    let url: String
}
