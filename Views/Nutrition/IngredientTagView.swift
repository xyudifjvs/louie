//
//  IngredientTagView.swift
//  Louie
//
//  Created by Carson on 3/30/25.
//

import SwiftUI

struct IngredientTagView: View {
    let label: String
    let confidence: Float
    let position: CGPoint
    let delay: Double
    
    var body: some View {
        Text(label.capitalized)
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            )
            .foregroundColor(Color(hexCode: "1a1a2e"))
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
            .position(position)
            .transition(
                .asymmetric(
                    insertion: .scale(scale: 0.5)
                        .combined(with: .opacity)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(delay)),
                    removal: .scale(scale: 0.8)
                        .combined(with: .opacity)
                        .animation(.easeOut(duration: 0.2))
                )
            )
    }
}

// Extension to add connecting line between tag and food item
extension IngredientTagView {
    func withConnector(to targetPoint: CGPoint) -> some View {
        ZStack {
            // Connector line
            Path { path in
                path.move(to: position)
                let controlPoint = CGPoint(
                    x: (position.x + targetPoint.x) / 2,
                    y: (position.y + targetPoint.y) / 2 - 20
                )
                path.addQuadCurve(to: targetPoint, control: controlPoint)
            }
            .stroke(Color.white.opacity(0.5), lineWidth: 1)
            
            // The tag itself
            self
        }
    }
}

struct IngredientTagView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(hexCode: "1a1a2e").edgesIgnoringSafeArea(.all)
            
            IngredientTagView(
                label: "Chicken Breast",
                confidence: 0.92,
                position: CGPoint(x: 200, y: 200),
                delay: 0.2
            )
        }
    }
}

