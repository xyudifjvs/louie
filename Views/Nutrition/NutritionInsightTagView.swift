//
//  NutritionInsightTagView.swift
//  Louie
//
//  Created by Carson on 3/30/25.
//

import SwiftUI

// Use the InsightType enum from NutritionInsight but with UI extensions specific to this view
// Instead of extending the type directly, create a UI helper
struct InsightTypeUI {
    let type: NutritionInsight.InsightType
    
    init(_ type: NutritionInsight.InsightType) {
        self.type = type
    }
    
    var color: Color {
        switch type {
        case .positive:
            return Color.green
        case .negative:
            return Color.red
        case .neutral:
            return Color.blue
        case .suggestion:
            return Color(hexCode: "FF9500") // Orange
        }
    }
    
    var icon: String {
        switch type {
        case .positive:
            return "checkmark.circle.fill"
        case .neutral:
            return "info.circle.fill"
        case .negative:
            return "exclamationmark.triangle.fill"
        case .suggestion:
            return "lightbulb.fill"
        }
    }
}

struct NutritionInsightTagView: View {
    // Original properties
    let title: String
    let description: String
    let icon: String
    let type: NutritionInsight.InsightType
    let position: CGPoint?
    let delay: Double
    
    @Namespace private var animation
    
    // Convenience initializer that takes a NutritionInsight
    init(insight: NutritionInsight, position: CGPoint? = nil, delay: Double = 0.0) {
        self.title = insight.title
        self.description = insight.description
        self.icon = insight.icon
        self.type = insight.type
        self.position = position
        self.delay = delay
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(InsightTypeUI(type).color.opacity(0.15))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
        .foregroundColor(InsightTypeUI(type).color)
        .overlay(
            Capsule()
                .strokeBorder(InsightTypeUI(type).color.opacity(0.3), lineWidth: 1)
        )
        .modifier(PositionModifier(position: position))
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.7)
                    .combined(with: .opacity)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(delay)),
                removal: .opacity
                    .animation(.easeOut(duration: 0.2))
            )
        )
    }
    
    // Optional detailed view with expanded information
    func withDetailedView() -> some View {
        VStack(spacing: 4) {
            self
            
            if !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(6)
                    .offset(y: -5)
                    .opacity(0.9)
            }
        }
    }
}

// Position modifier that handles optional positions
struct PositionModifier: ViewModifier {
    let position: CGPoint?
    
    func body(content: Content) -> some View {
        if let position = position {
            content.position(position)
        } else {
            content
        }
    }
}

struct NutritionInsightTagView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(hexCode: "1a1a2e").edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                NutritionInsightTagView(
                    insight: NutritionInsight(
                        title: "Lean protein",
                        description: "Good source of protein",
                        icon: "checkmark.circle.fill",
                        type: .positive
                    ),
                    position: CGPoint(x: 200, y: 100),
                    delay: 0.2
                )
                
                NutritionInsightTagView(
                    insight: NutritionInsight(
                        title: "Good source of fiber",
                        description: "Promotes digestive health",
                        icon: "info.circle.fill",
                        type: .neutral
                    ),
                    position: CGPoint(x: 200, y: 150),
                    delay: 0.4
                )
                
                NutritionInsightTagView(
                    insight: NutritionInsight(
                        title: "Simple carbs",
                        description: "Choose whole grain options",
                        icon: "exclamationmark.triangle.fill",
                        type: .negative
                    ),
                    position: CGPoint(x: 200, y: 200),
                    delay: 0.6
                ).withDetailedView()
            }
        }
    }
}

