//
//  PokemonListView.swift
//  Pokemon
//
//  Created by Mohamed Fiyaz on 13/04/25.
//

import SwiftUI

struct PokemonListView: View {
    @StateObject private var viewModel = PokemonListViewModel()
    @State private var searchText = ""
    @State private var enteredPage: String = ""
    @FocusState private var isSearchFieldFocused: Bool
    @FocusState private var isPageFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header with Pokédex title and search
                    HStack {
                        Image("pokeball")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                        
                        Text("Pokédex")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Kanto Region")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color(UIColor(red: 25/255.0, green: 118/255.0, blue: 210/255.0, alpha: 1.0)))
                    
                    // Search bar
                    HStack {
                        HStack {
                            TextField("Search Pokémon", text: $searchText)
                                .padding(10)
                                .focused($isSearchFieldFocused)
                                .onChange(of: searchText) { oldValue, newValue in
                                    viewModel.searchText = newValue
                                    viewModel.searchPokemon(query: newValue)
                                }
                            
                            // Clear button
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    viewModel.clearSearch()
                                    isSearchFieldFocused = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                                .padding(.trailing, 8)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(8)
                        
                        Button(action: {
                            // Search button action
                            viewModel.searchPokemon(query: searchText)
                            isSearchFieldFocused = false // Dismiss keyboard
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
                    .background(Color(UIColor(red: 25/255.0, green: 118/255.0, blue: 210/255.0, alpha: 1.0)))
                    
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
                        
                        // Pagination controls (only show if not searching)
                        HStack(spacing: 20) {
                            Button(action: viewModel.loadPreviousPage) {
                                Text("Previous")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(viewModel.currentPage > 1 ? Color.red : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .disabled(viewModel.currentPage <= 1 || !searchText.isEmpty)
                            
                            HStack {
                                TextField("Page", text: $enteredPage)
                                    .frame(width: 50)
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.numberPad)
                                    .focused($isPageFieldFocused)
                                    .onChange(of: enteredPage) { oldValue, newValue in
                                        // Accept only digits
                                        enteredPage = enteredPage.filter { $0.isNumber }
                                    }
                                    .onAppear {
                                        // Initialize with current page
                                        enteredPage = "\(viewModel.currentPage)"
                                    }
                                    .onChange(of: viewModel.currentPage) { oldPage, newPage in
                                        // Update text field when page changes
                                        enteredPage = "\(newPage)"
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                                
                                Text("of \(viewModel.totalPages)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Button(action: {
                                if let page = Int(enteredPage), page >= 1, page <= viewModel.totalPages {
                                    viewModel.goToPage(page)
                                } else {
                                    // Reset to current page if invalid
                                    enteredPage = "\(viewModel.currentPage)"
                                }
                                isPageFieldFocused = false // Dismiss keyboard
                            }) {
                                Text("Go")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .disabled(!searchText.isEmpty)
                            
                            Button(action: viewModel.loadNextPage) {
                                Text("Next")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(viewModel.currentPage < viewModel.totalPages ? Color.red : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .disabled(viewModel.currentPage >= viewModel.totalPages || !searchText.isEmpty)
                        }
                        .padding()
                        .opacity(searchText.isEmpty ? 1 : 0.5) // Fade out pagination during search
                        
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
            // Add gesture recognizer to dismiss keyboard when tapping elsewhere
            .contentShape(Rectangle())
            .onTapGesture {
                isSearchFieldFocused = false
                isPageFieldFocused = false
            }
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
            
            VStack(alignment: .leading) {
                Text(pokemon.name)
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text("#\(pokemon.id)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.leading, 5)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .padding(.trailing, 10)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
