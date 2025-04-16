//
//  PokemonApp.swift
//  Pokemon
//
//  Created by Mohamed Fiyaz on 12/04/25.
//

import SwiftUI

@main
struct PokemonApp: App {
    @State private var showLaunchScreen = true
    
    var body: some Scene {
        WindowGroup {
            if showLaunchScreen {
                LaunchScreen()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showLaunchScreen = false
                        }
                    }
            } else {
                PokemonListView()
            }
        }
    }
}
