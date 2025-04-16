//
//  PokemonAPIService.swift
//  Pokemon
//
//  Created by Mohamed Fiyaz on 13/04/25.
//

import Foundation
import Combine

class PokemonAPIService {
    private let baseURL = Constants.pokeApiBaseURL
    
    func fetchPokemons(offset: Int, limit: Int) -> AnyPublisher<[Pokemon], Error> {
        guard let url = URL(string: "\(baseURL)/pokemon?offset=\(offset)&limit=\(limit)") else {
            return Fail(error: NSError(domain: "Invalid URL", code: 0, userInfo: nil)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: PokemonResponse.self, decoder: JSONDecoder())
            .map { response -> [Pokemon] in
                return response.results.enumerated().map { index, result in
                    let id = offset + index + 1
                    return Pokemon(id: id, name: result.name.capitalized, url: result.url)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func fetchAllKantoPokemons() -> AnyPublisher<[Pokemon], Error> {
        // Fetch all 151 Kanto Pokémon at once
        return fetchPokemons(offset: 0, limit: 151)
    }
    
    func fetchPokemonDetail(id: Int) -> AnyPublisher<PokemonDetail, Error> {
        guard let url = URL(string: "\(baseURL)/pokemon/\(id)") else {
            return Fail(error: NSError(domain: "Invalid URL", code: 0, userInfo: nil)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: PokemonDetail.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
