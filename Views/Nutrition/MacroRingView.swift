//
//  MacroRingView.swift
//  Louie
//
//  Created by Carson on 3/30/25.
//

import SwiftUI

struct MacroRingView: View {
    let value: Double
    let maxValue: Double
    let ringWidth: CGFloat
    let title: String
    let color: Color
    let unitText: String
    
    @State private var progress: CGFloat = 0
    
    init(
        value: Double,
        maxValue: Double = 100,
        ringWidth: CGFloat = 12,
        title: String,
        color: Color,
        unitText: String = "g"
    ) {
        self.value = value
        self.maxValue = maxValue
        self.ringWidth = ringWidth
        self.title = title
        self.color = color
        self.unitText = unitText
    }
    
    var body: some View {
        ZStack {
            // Background track ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: ringWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color, 
                    style: StrokeStyle(
                        lineWidth: ringWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 0)
            
            // Content
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text("\(Int(value))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(unitText)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                progress = CGFloat(min(value / maxValue, 1.0))
            }
        }
    }
}

struct MacroRingGroup: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    let calories: Int
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 20) {
                MacroRingView(
                    value: protein,
                    maxValue: 75, // Adjusted for typical daily value
                    title: "Protein",
                    color: Color.blue
                )
                .frame(width: 80, height: 80)
                
                MacroRingView(
                    value: carbs,
                    maxValue: 125, // Adjusted for typical daily value
                    title: "Carbs",
                    color: Color.green
                )
                .frame(width: 80, height: 80)
                
                MacroRingView(
                    value: fat,
                    maxValue: 50, // Adjusted for typical daily value
                    title: "Fat",
                    color: Color(hexCode: "FF9500") // Orange
                )
                .frame(width: 80, height: 80)
            }
            
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(Color.red.opacity(0.8))
                
                Text("\(calories) kcal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.black.opacity(0.3))
            .cornerRadius(20)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hexCode: "1a1a2e").opacity(0.7),
                            Color(hexCode: "2a6041").opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

struct MacroRingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(hexCode: "1a1a2e").edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                MacroRingView(
                    value: 45,
                    maxValue: 75,
                    title: "Protein",
                    color: .blue
                )
                .frame(width: 100, height: 100)
                
                MacroRingGroup(
                    protein: 45,
                    carbs: 65,
                    fat: 20,
                    calories: 620
                )
                .padding()
            }
        }
    }
}

