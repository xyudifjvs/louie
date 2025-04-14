//
//  TagGridView.swift
//  Louie
//
//  Created by Carson on 4/14/25.
//

import SwiftUI

// Custom Flow Layout (Optional but good for tags)
// If you don't have this, LazyVGrid with adaptive columns is an alternative.
struct FlowLayout: Layout {
    var alignment: Alignment = .center
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var height: CGFloat = 0
        var rows = [Row]()
        var currentRow = Row(spacing: spacing)

        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            if currentRow.width + viewSize.width + spacing > maxWidth {
                height += currentRow.height + spacing
                rows.append(currentRow)
                currentRow = Row(spacing: spacing)
            }
            currentRow.append(viewSize)
        }
        height += currentRow.height // Add last row height
        rows.append(currentRow)
        return CGSize(width: maxWidth, height: max(height, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var viewX = bounds.minX
        var viewY = bounds.minY
        var currentRow = Row(spacing: spacing)

        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            if viewX + viewSize.width > maxWidth {
                viewY += currentRow.height + spacing
                viewX = bounds.minX
                currentRow = Row(spacing: spacing)
            }
            
            let proposal = ProposedViewSize(width: viewSize.width, height: viewSize.height)
            let position = CGPoint(x: viewX + viewSize.width / 2, y: viewY + viewSize.height / 2)
            view.place(at: position, anchor: .center, proposal: proposal)
            
            viewX += viewSize.width + spacing
            currentRow.append(viewSize)
        }
    }

    struct Row {
        var width: CGFloat = 0
        var height: CGFloat = 0
        let spacing: CGFloat

        mutating func append(_ size: CGSize) {
            if width != 0 {
                width += spacing
            }
            width += size.width
            height = max(height, size.height)
        }
    }
}


struct TagGridView: View {
    let options: [TagOption]
    @Binding var selectedIDs: Set<TagOption.ID>
    let allowsMultiple: Bool
    
    // Special handling for "None" tag if present
    private var noneOptionID: TagOption.ID? {
        options.first { $0.value == "none" }?.id
    }

    var body: some View {
        FlowLayout(spacing: 10) { // Using FlowLayout for better tag wrapping
            ForEach(options) { option in
                TagView(option: option, isSelected: selectedIDs.contains(option.id))
                    .onTapGesture {
                        handleSelection(option)
                    }
            }
        }
        .padding(.vertical, 10)
    }

    private func handleSelection(_ option: TagOption) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            let optionID = option.id
            let isNone = optionID == noneOptionID

            if allowsMultiple {
                if isNone {
                    // If "None" is tapped, select only it or deselect if already selected
                    if selectedIDs.contains(optionID) {
                        selectedIDs.remove(optionID)
                    } else {
                        selectedIDs = [optionID]
                    }
                } else {
                    // If another tag is tapped
                    if selectedIDs.contains(optionID) {
                        selectedIDs.remove(optionID)
                    } else {
                        selectedIDs.insert(optionID)
                        // If "None" was selected, deselect it
                        if let noneID = noneOptionID {
                            selectedIDs.remove(noneID)
                        }
                    }
                }
            } else {
                // Single selection logic
                if selectedIDs.contains(optionID) {
                    selectedIDs.remove(optionID) // Allow deselecting
                } else {
                    selectedIDs = [optionID]
                }
            }
        }
    }
}

// Subview for individual tag appearance
struct TagView: View {
    let option: TagOption
    let isSelected: Bool

    var body: some View {
        Text(option.text)
            .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? .white : .white.opacity(0.8))
            .background(
                Capsule()
                    .fill(isSelected ? Color.purple.opacity(0.6) : Color.white.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.purple : Color.white.opacity(0.2), lineWidth: 1.5)
            )
    }
}

// MARK: - Preview
struct TagGridView_Previews: PreviewProvider {
    @State static var previewMultiSelectedIDs: Set<TagOption.ID> = []
    static let previewOptions: [TagOption] = [
        TagOption(text: "Headache", value: "headache"),
        TagOption(text: "Fatigue", value: "fatigue"),
        TagOption(text: "Bloating", value: "bloating"),
        TagOption(text: "Muscle Soreness", value: "muscle_soreness"),
        TagOption(text: "Stomach Ache", value: "stomach_ache"),
        TagOption(text: "Joint Pain", value: "joint_pain"),
        TagOption(text: "Brain Fog", value: "brain_fog"),
        TagOption(text: "None today", value: "none"),
    ]

    @State static var previewSingleSelectedIDs: Set<TagOption.ID> = []
    static let previewSingleOptions: [TagOption] = [
        TagOption(text: "Option A", value: "a"),
        TagOption(text: "Option B", value: "b"),
        TagOption(text: "Option C", value: "c"),
    ]

    static var previews: some View {
        ZStack {
            Color(hexCode: "1a1a2e").edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading, spacing: 30) {
                Text("Multi-Select Example").foregroundColor(.white)
                TagGridView(
                    options: previewOptions,
                    selectedIDs: $previewMultiSelectedIDs,
                    allowsMultiple: true
                )
                
                Divider()
                
                Text("Single-Select Example").foregroundColor(.white)
                 TagGridView(
                    options: previewSingleOptions,
                    selectedIDs: $previewSingleSelectedIDs,
                    allowsMultiple: false
                )
            }
            .padding()
        }
    }
}

