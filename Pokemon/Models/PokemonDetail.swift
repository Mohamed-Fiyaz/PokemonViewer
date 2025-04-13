//
//  PokemonDetail.swift
//  PokemonViewer
//
//  Created by Mohamed Fiyaz on 13/04/25.
//

import Foundation

struct PokemonDetail: Codable {
    let id: Int
    let name: String
    let height: Int
    let weight: Int
    let types: [TypeElement]
    let stats: [StatElement]
    
    struct TypeElement: Codable {
        let slot: Int
        let type: TypeInfo
        
        struct TypeInfo: Codable {
            let name: String
            let url: String
        }
    }
    
    struct StatElement: Codable {
        let baseStat: Int
        let effort: Int
        let stat: StatInfo
        
        struct StatInfo: Codable {
            let name: String
            let url: String
        }
        
        enum CodingKeys: String, CodingKey {
            case baseStat = "base_stat"
            case effort
            case stat
        }
    }
}
