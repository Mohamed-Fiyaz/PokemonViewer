//
//  PokemonDetailView.swift
//  Pokemon
//
//  Created by Mohamed Fiyaz on 13/04/25.
//

import SwiftUI

struct PokemonDetailView: View {
    let pokemon: Pokemon
    private let apiService = PokemonAPIService()
    @State private var pokemonDetail: PokemonDetail?
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        VStack {
            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(message: error) {
                    fetchPokemonDetails()
                }
            } else if let detail = pokemonDetail {
                ScrollView {
                    VStack(alignment: .center, spacing: 20) {
                        // Pokemon image
                        AsyncImage(url: URL(string: pokemon.imageUrl)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 200)
                            } else if phase.error != nil {
                                Image(systemName: "questionmark")
                                    .frame(height: 200)
                            } else {
                                ProgressView()
                                    .frame(height: 200)
                            }
                        }
                        
                        // Pokemon info
                        VStack(alignment: .leading, spacing: 10) {
                            // Types
                            HStack {
                                Text("Types:")
                                    .fontWeight(.bold)
                                ForEach(detail.types, id: \.slot) { typeElement in
                                    Text(typeElement.type.name.capitalized)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(typeColor(for: typeElement.type.name))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                            
                            // Height and Weight
                            HStack {
                                DetailItemView(title: "Height", value: "\(Double(detail.height) / 10) m")
                                DetailItemView(title: "Weight", value: "\(Double(detail.weight) / 10) kg")
                            }
                            
                            // Stats
                            Text("Base Stats:")
                                .font(.headline)
                                .padding(.top, 10)
                            
                            ForEach(detail.stats, id: \.stat.name) { stat in
                                StatView(statName: stat.stat.name, baseStat: stat.baseStat)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                        
                        // AR View Button
                        NavigationLink(destination: ARPokemonView(pokemon: pokemon)) {
                            Text("View in AR")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                                .shadow(radius: 2)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            } else {
                Text("Loading Pokémon details...")
                    .onAppear {
                        fetchPokemonDetails()
                    }
            }
        }
        .navigationTitle(pokemon.name)
    }
    
    private func fetchPokemonDetails() {
        isLoading = true
        error = nil
        
        URLSession.shared.dataTask(with: URL(string: "https://pokeapi.co/api/v2/pokemon/\(pokemon.id)")!) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self.error = "No data received"
                    return
                }
                
                do {
                    self.pokemonDetail = try JSONDecoder().decode(PokemonDetail.self, from: data)
                } catch {
                    self.error = "Failed to decode: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func typeColor(for typeName: String) -> Color {
        switch typeName.lowercased() {
        case "normal": return Color(red: 0.6, green: 0.6, blue: 0.5)
        case "fire": return Color(red: 0.9, green: 0.5, blue: 0.2)
        case "water": return Color(red: 0.4, green: 0.6, blue: 0.9)
        case "electric": return Color(red: 0.9, green: 0.8, blue: 0.2)
        case "grass": return Color(red: 0.5, green: 0.8, blue: 0.3)
        case "ice": return Color(red: 0.6, green: 0.8, blue: 0.8)
        case "fighting": return Color(red: 0.7, green: 0.3, blue: 0.3)
        case "poison": return Color(red: 0.6, green: 0.3, blue: 0.6)
        case "ground": return Color(red: 0.8, green: 0.7, blue: 0.4)
        case "flying": return Color(red: 0.7, green: 0.6, blue: 0.9)
        case "psychic": return Color(red: 0.9, green: 0.4, blue: 0.6)
        case "bug": return Color(red: 0.7, green: 0.8, blue: 0.2)
        case "rock": return Color(red: 0.7, green: 0.6, blue: 0.4)
        case "ghost": return Color(red: 0.5, green: 0.4, blue: 0.7)
        case "dragon": return Color(red: 0.6, green: 0.4, blue: 0.8)
        case "dark": return Color(red: 0.5, green: 0.4, blue: 0.4)
        case "steel": return Color(red: 0.7, green: 0.7, blue: 0.8)
        case "fairy": return Color(red: 0.9, green: 0.6, blue: 0.7)
        default: return Color.gray
        }
    }
}

struct DetailItemView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .center) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

struct StatView: View {
    let statName: String
    let baseStat: Int
    
    var formattedStatName: String {
        switch statName {
        case "hp": return "HP"
        case "attack": return "Attack"
        case "defense": return "Defense"
        case "special-attack": return "Sp. Atk"
        case "special-defense": return "Sp. Def"
        case "speed": return "Speed"
        default: return statName.capitalized
        }
    }
    
    var statColor: Color {
        let percentage = Double(baseStat) / 255.0
        if percentage < 0.3 {
            return .red
        } else if percentage < 0.6 {
            return .yellow
        } else {
            return .green
        }
    }
    
    var body: some View {
        HStack {
            Text(formattedStatName)
                .frame(width: 80, alignment: .leading)
            
            Text("\(baseStat)")
                .frame(width: 40)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 20)
                        .opacity(0.3)
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(width: min(CGFloat(baseStat) / 255.0 * geometry.size.width, geometry.size.width), height: 20)
                        .foregroundColor(statColor)
                }
                .cornerRadius(5)
            }
            .frame(height: 20)
        }
    }
}
