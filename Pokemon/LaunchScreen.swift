//
//  LaunchScreen.swift
//  Pokemon
//
//  Created by Mohamed Fiyaz on 17/04/25.
//

import SwiftUI

struct LaunchScreen: View {
    @State private var isAnimating = false
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(UIColor(red: 25/255.0, green: 118/255.0, blue: 210/255.0, alpha: 1.0)),
                    Color(UIColor(red: 30/255.0, green: 136/255.0, blue: 229/255.0, alpha: 1.0))
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // Pokeball image
                Image("pokeball")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            self.rotation = 360
                            self.scale = 1.0
                        }
                    }
                
                // App title
                Text("Pokédex")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(Animation.easeIn(duration: 1.5)) {
                            self.opacity = 1.0
                        }
                    }
                
                Spacer()
                
                // Footer positioned at the bottom
                VStack {
                    Text("Kanto Region")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("© Mohamed Fiyaz 2025")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                }
                .opacity(opacity)
                .padding(.bottom, 30)
            }
            .padding()
        }
    }
}

#Preview {
    LaunchScreen()
}
