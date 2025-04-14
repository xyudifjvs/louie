//
//  EmojiGridView.swift
//  Louie
//
//  Created by Carson on 4/14/25.
//

import SwiftUI

struct EmojiGridView: View {
    let options: [EmojiOption]
    @Binding var selectedOption: EmojiOption?

    // Define grid layout: Flexible columns adapting to available space
    private let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) { // Using LazyVGrid for better spacing control if wrapping occurs
            ForEach(options) { option in
                VStack(spacing: 4) {
                    Text(option.emoji)
                        .font(.system(size: 36)) // Emoji size
                        .padding(10)
                        .background(
                            Circle()
                                .fill(selectedOption == option ? Color.purple.opacity(0.4) : Color.white.opacity(0.1))
                        )
                        .scaleEffect(selectedOption == option ? 1.1 : 1.0) // Scale up selected
                        .overlay(
                             Circle()
                                .stroke(selectedOption == option ? Color.purple : Color.clear, lineWidth: 2) // Add border to selected
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                if selectedOption == option {
                                    selectedOption = nil // Allow deselecting
                                } else {
                                    selectedOption = option
                                }
                            }
                        }
                    
                    // Optional label below emoji
                    Text(option.label)
                        .font(.caption)
                        .foregroundColor(selectedOption == option ? .white : .white.opacity(0.7))
                }
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Preview
struct EmojiGridView_Previews: PreviewProvider {
    @State static var previewSelectedOption: EmojiOption? = EmojiOption(emoji: "😊", label: "Happy", value: "happy")
    static let previewOptions = [
        EmojiOption(emoji: "😊", label: "Happy", value: "happy"),
        EmojiOption(emoji: "😐", label: "Neutral", value: "neutral"),
        EmojiOption(emoji: "😢", label: "Sad", value: "sad"),
        EmojiOption(emoji: "😠", label: "Angry", value: "angry"),
        EmojiOption(emoji: "😟", label: "Anxious", value: "anxious"),
    ]
    
    static var previews: some View {
        ZStack {
            Color(hexCode: "1a1a2e").edgesIgnoringSafeArea(.all)
            EmojiGridView(options: previewOptions, selectedOption: $previewSelectedOption)
                .padding()
        }
    }
}

