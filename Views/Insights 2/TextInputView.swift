//
//  TextInputView.swift
//  Louie
//
//  Created by Carson on 4/14/25.
//

import SwiftUI

struct TextInputView: View {
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Use TextEditor for multi-line potential
            TextEditor(text: $text)
                .scrollContentBackground(.hidden) // Use this to style background in ZStack
                .padding(10)
                .frame(minHeight: 80, maxHeight: 150) // Set a reasonable height range
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.1))
                )
                .overlay(
                     RoundedRectangle(cornerRadius: 15)
                        .stroke(isFocused ? Color.purple : Color.white.opacity(0.2), lineWidth: 1.5)
                )
                .foregroundColor(.white)
                .font(.body)
                .focused($isFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isFocused = false
                        }
                    }
                 }

            // Placeholder text overlay
            if text.isEmpty && !isFocused {
                Text(placeholder)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 15)
                    .padding(.vertical, 18) // Adjust alignment with TextEditor padding
                    .allowsHitTesting(false) // Let taps pass through to TextEditor
            }
        }
        .padding(.vertical, 10)
        .onTapGesture { // Allow tapping outside text to focus
             isFocused = true
        }
    }
}

// MARK: - Preview
struct TextInputView_Previews: PreviewProvider {
    @State static var previewTextEmpty: String = ""
    @State static var previewTextFilled: String = "Feeling pretty good today, just a bit tired from the workout."
    
    static var previews: some View {
        ZStack {
            Color(hexCode: "1a1a2e").edgesIgnoringSafeArea(.all)
            VStack(spacing: 30) {
                TextInputView(text: $previewTextEmpty, placeholder: "Share your thoughts...")
                TextInputView(text: $previewTextFilled, placeholder: "Share your thoughts...")
            }
            .padding()
        }
    }
}

