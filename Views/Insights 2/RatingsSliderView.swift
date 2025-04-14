//
//  RatingsSliderView.swift
//  Louie
//
//  Created by Carson on 4/14/25.
//

import SwiftUI

struct RatingsSliderView: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    var showValue: Bool = true

    // Formatter for displaying the value
    private var valueFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        // Show decimal only if step is not a whole number
        formatter.maximumFractionDigits = (step.truncatingRemainder(dividingBy: 1) == 0) ? 0 : 1
        formatter.minimumFractionDigits = (step.truncatingRemainder(dividingBy: 1) == 0) ? 0 : 1
        return formatter
    }

    var body: some View {
        HStack(spacing: 15) {
            Slider(
                value: $value,
                in: range,
                step: step
            ) {
                // Accessibility label (optional)
                // Text("Rating")
            }
            .tint(.purple) // Match button tint for consistency

            if showValue {
                Text(valueFormatter.string(from: NSNumber(value: value)) ?? "")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(minWidth: 30, alignment: .trailing) // Ensure consistent width
            }
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Preview
struct RatingsSliderView_Previews: PreviewProvider {
    @State static var previewValue: Double = 7.0
    
    static var previews: some View {
        ZStack {
            Color(hexCode: "1a1a2e").edgesIgnoringSafeArea(.all)
            VStack {
                 RatingsSliderView(
                    value: $previewValue,
                    range: 1...10,
                    step: 1
                 )
                 .padding()

                 RatingsSliderView(
                    value: $previewValue,
                    range: 0...16,
                    step: 0.5
                 )
                 .padding()
            }
        }
    }
}

