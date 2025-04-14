//
//  YesNoButtonsView.swift
//  Louie
//
//  Created by Carson on 4/14/25.
//

import SwiftUI

struct YesNoButtonsView: View {
    @Binding var selection: Bool? // true for Yes, false for No, nil for none

    var body: some View {
        HStack(spacing: 20) {
            // Yes Button
            Button {
                withAnimation(.spring()) {
                    selection = true
                }
            } label: {
                Text("Yes")
                    .font(.headline)
                    .fontWeight(selection == true ? .bold : .regular)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity) // Make buttons take equal width
            }
            .foregroundColor(selection == true ? .white : .white.opacity(0.8))
            .background(
                Capsule()
                    .fill(selection == true ? Color.green.opacity(0.6) : Color.white.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(selection == true ? Color.green : Color.white.opacity(0.2), lineWidth: 1.5)
            )

            // No Button
            Button {
                withAnimation(.spring()) {
                    selection = false
                }
            } label: {
                Text("No")
                    .font(.headline)
                    .fontWeight(selection == false ? .bold : .regular)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
            }
             .foregroundColor(selection == false ? .white : .white.opacity(0.8))
            .background(
                Capsule()
                    .fill(selection == false ? Color.red.opacity(0.6) : Color.white.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(selection == false ? Color.red : Color.white.opacity(0.2), lineWidth: 1.5)
            )
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Preview
struct YesNoButtonsView_Previews: PreviewProvider {
    @State static var previewSelectionYes: Bool? = true
    @State static var previewSelectionNo: Bool? = false
    @State static var previewSelectionNone: Bool? = nil

    static var previews: some View {
        ZStack {
            Color(hexCode: "1a1a2e").edgesIgnoringSafeArea(.all)
            VStack(spacing: 30) {
                YesNoButtonsView(selection: $previewSelectionYes)
                YesNoButtonsView(selection: $previewSelectionNo)
                YesNoButtonsView(selection: $previewSelectionNone)
            }
            .padding()
        }
    }
}

