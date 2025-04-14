//
//  MonthlyGoalRingView.swift
//  Louie
//
//  Created by Carson on 4/4/25.
//

import SwiftUI

struct MonthlyGoalRingView: View {
    let completionStatus: [Bool] // Expects exactly 4 bools
    let icon: String
    
    // Define colors
    let baseColor = Color.gray.opacity(0.3)
    let completedColor = Color.green // Or use app theme color
    let lineWidth: CGFloat = 8
    
    var body: some View {
        ZStack {
            // Draw the background base ring
            Circle()
                .stroke(baseColor, lineWidth: lineWidth)
            
            // Draw the 4 segments
            ForEach(0..<4) { index in
                if index < completionStatus.count { // Ensure we don't go out of bounds
                    SegmentShape(segmentIndex: index)
                        .stroke(completionStatus[index] ? completedColor : baseColor, 
                                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                }
            }
            .rotationEffect(.degrees(-90)) // Start drawing from the top
            
            // Overlay the icon
            Text(icon)
                .font(.system(size: 24)) // Adjust size as needed
        }
        // Apply animation if the status changes
        .animation(.easeOut, value: completionStatus)
    }
}

// Helper Shape to draw one 90-degree segment
struct SegmentShape: Shape {
    let segmentIndex: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let startAngle = Angle(degrees: Double(segmentIndex) * 90.0)
        let endAngle = Angle(degrees: Double(segmentIndex + 1) * 90.0)
        
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        
        return path
    }
}

// Preview Provider
struct MonthlyGoalRingView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            MonthlyGoalRingView(completionStatus: [true, false, false, false], icon: "🔥")
                .frame(width: 60, height: 60)
            MonthlyGoalRingView(completionStatus: [true, true, false, false], icon: "💪")
                .frame(width: 60, height: 60)
            MonthlyGoalRingView(completionStatus: [true, true, true, false], icon: "🍞")
                .frame(width: 60, height: 60)
            MonthlyGoalRingView(completionStatus: [true, true, true, true], icon: "🥑")
                .frame(width: 60, height: 60)
            MonthlyGoalRingView(completionStatus: [false, false, false, false], icon: "❓")
                .frame(width: 60, height: 60)
        }
        .padding()
        .background(Color.black)
    }
}

