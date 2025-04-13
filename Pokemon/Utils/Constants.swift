//
//  Constants.swift
//  PokemonViewer
//
//  Created by Mohamed Fiyaz on 13/04/25.
//

import Foundation
import SwiftUI

struct Constants {
    // API URLs
    static let pokeApiBaseURL = "https://pokeapi.co/api/v2"
    static let pokemon3DApiBaseURL = "https://raw.githubusercontent.com/Sudhanshu-Ambastha/Pokemon-3D-api/main/Models"
    
    // App Styling
    struct Colors {
        static let primary = Color.blue
        static let secondary = Color.red
        static let background = Color(UIColor.systemBackground)
        static let card = Color.white
        static let text = Color.primary
        static let subtitle = Color.secondary
    }
    
    // Page Size
    static let pageSize = 20
    
    // Animation Durations
    static let standardAnimationDuration = 0.3
}
