//
//  PokemonListViewModel.swift
//  Pokemon
//
//  Created by Mohamed Fiyaz on 13/04/25.
//

import Foundation
import Combine

class PokemonListViewModel: ObservableObject {
    @Published var pokemons: [Pokemon] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentPage = 1
    @Published var totalPages = 1
    @Published var searchText = ""
    
    private let pageSize = 20
    private let totalPokemon = 151 // Only Kanto Pokémon (1-151)
    private let apiService = PokemonAPIService()
    private var cancellables = Set<AnyCancellable>()
    private var allPokemons: [Pokemon] = [] // Store all Pokémon for search functionality
    
    init() {
        // Calculate total pages based on 151 Pokémon
        totalPages = (totalPokemon + pageSize - 1) / pageSize // Ceiling division
    }
    
    func loadFirstPage() {
        loadPokemons(offset: 0)
    }
    
    func loadNextPage() {
        if currentPage < totalPages && !isLoading {
            loadPokemons(offset: (currentPage) * pageSize)
        }
    }
    
    func loadPreviousPage() {
        if currentPage > 1 && !isLoading {
            loadPokemons(offset: (currentPage - 2) * pageSize)
        }
    }
    
    func goToPage(_ page: Int) {
        if page >= 1 && page <= totalPages && !isLoading {
            // Force load the requested page
            let offset = (page - 1) * pageSize
            loadPokemons(offset: offset)
        }
    }
    
    func clearSearch() {
        searchText = ""
        // Return to current page view without search filtering
        let offset = (currentPage - 1) * pageSize
        let endIndex = min(offset + pageSize, allPokemons.count)
        if offset < allPokemons.count {
            pokemons = Array(allPokemons[offset..<endIndex])
        }
    }
    
    func searchPokemon(query: String) {
        if query.isEmpty {
            // If search is empty, show current page
            let offset = (currentPage - 1) * pageSize
            let endIndex = min(offset + pageSize, allPokemons.count)
            if offset < allPokemons.count {
                pokemons = Array(allPokemons[offset..<endIndex])
            }
        } else {
            // Filter Pokémon by name
            let filteredPokemon = allPokemons.filter {
                $0.name.lowercased().contains(query.lowercased())
            }
            pokemons = filteredPokemon
        }
    }
    
    private func loadPokemons(offset: Int) {
        isLoading = true
        error = nil
        
        // Ensure we only fetch up to 151 Pokémon
        let adjustedLimit = min(pageSize, totalPokemon - offset)
        
        // Don't fetch if offset is beyond our total
        if offset >= totalPokemon {
            isLoading = false
            return
        }
        
        apiService.fetchPokemons(offset: offset, limit: adjustedLimit)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            }, receiveValue: { [weak self] pokemons in
                guard let self = self else { return }
                
                // Filter only Pokémon with ID <= 151
                let kantoPokemons = pokemons.filter { $0.id <= self.totalPokemon }
                self.pokemons = kantoPokemons
                self.currentPage = (offset / self.pageSize) + 1
                
                // Store all Pokémon for search if we don't have them yet
                if self.allPokemons.isEmpty || self.allPokemons.count < self.totalPokemon {
                    // Load all Pokémon for search functionality (only do this once)
                    self.loadAllPokemon()
                } else if !self.searchText.isEmpty {
                    // If we have a search text, apply the filter
                    self.searchPokemon(query: self.searchText)
                }
            })
            .store(in: &cancellables)
    }
    
    private func loadAllPokemon() {
        apiService.fetchAllKantoPokemons()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] pokemons in
                guard let self = self else { return }
                self.allPokemons = pokemons
                
                // If there's a search query, apply it
                if !self.searchText.isEmpty {
                    self.searchPokemon(query: self.searchText)
                }
            })
            .store(in: &cancellables)
    }
}
