//
//  PokemonListViewModel.swift
//  PokemonViewer
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
    
    private let pageSize = 20
    private let apiService = PokemonAPIService()
    private var cancellables = Set<AnyCancellable>()
    
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
        if page >= 1 && page <= totalPages && page != currentPage && !isLoading {
            loadPokemons(offset: (page - 1) * pageSize)
        }
    }
    
    private func loadPokemons(offset: Int) {
        isLoading = true
        error = nil
        
        apiService.fetchPokemons(offset: offset, limit: pageSize)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            }, receiveValue: { [weak self] pokemons in
                guard let self = self else { return }
                self.pokemons = pokemons
                self.currentPage = (offset / self.pageSize) + 1
                self.totalPages = 45 // Approx. 898 Pokémon / 20 per page
            })
            .store(in: &cancellables)
    }
}
