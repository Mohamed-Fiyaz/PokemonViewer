//
//  PokemonListViews.swift
//  PokemonViewer
//
//  Created by Mohamed Fiyaz on 13/04/25.
//

import SwiftUI

struct PokemonListView: View {
    @StateObject private var viewModel = PokemonListViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with Pokédex title and search
                HStack {
                    Image("pokeball")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                    
                    Text("Pokédex")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
                .background(Color.blue)
                
                // Search bar
                HStack {
                    TextField("Search Pokémon", text: $searchText)
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(8)
                    
                    Button(action: {
                        // Implement search functionality
                    }) {
                        Text("Search")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                .background(Color.blue)
                
                if viewModel.isLoading && viewModel.pokemons.isEmpty {
                    LoadingView()
                } else if let error = viewModel.error {
                    ErrorView(message: error) {
                        viewModel.loadFirstPage()
                    }
                } else {
                    // Pokemon list
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.pokemons) { pokemon in
                                NavigationLink(destination: PokemonDetailView(pokemon: pokemon)) {
                                    PokemonCell(pokemon: pokemon)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Pagination controls
                    HStack(spacing: 20) {
                        Button(action: viewModel.loadPreviousPage) {
                            Text("Previous")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(viewModel.currentPage > 1 ? Color.red : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(viewModel.currentPage <= 1)
                        
                        TextField("Page", value: $viewModel.currentPage, formatter: NumberFormatter())
                            .frame(width: 50)
                            .multilineTextAlignment(.center)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .keyboardType(.numberPad)
                        
                        Button(action: {
                            if let page = Int(String(viewModel.currentPage)), page != viewModel.currentPage {
                                viewModel.goToPage(page)
                            }
                        }) {
                            Text("Go")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Button(action: viewModel.loadNextPage) {
                            Text("Next")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(viewModel.currentPage < viewModel.totalPages ? Color.red : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(viewModel.currentPage >= viewModel.totalPages)
                    }
                    .padding()
                    
                    // Footer
                    Text("© Mohamed Fiyaz 2025")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.bottom, 5)
                }
            }
            .onAppear {
                if viewModel.pokemons.isEmpty {
                    viewModel.loadFirstPage()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct PokemonCell: View {
    let pokemon: Pokemon
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: pokemon.imageUrl)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                } else if phase.error != nil {
                    Image(systemName: "questionmark")
                        .frame(width: 60, height: 60)
                } else {
                    ProgressView()
                        .frame(width: 60, height: 60)
                }
            }
            
            Text(pokemon.name)
                .font(.title2)
                .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
