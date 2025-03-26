import SwiftUI

// Preference key for reordering
struct ReorderPreferenceKey: PreferenceKey {
    static var defaultValue: [ReorderInfo] = []
    
    static func reduce(value: inout [ReorderInfo], nextValue: () -> [ReorderInfo]) {
        value.append(contentsOf: nextValue())
    }
}

struct ReorderInfo: Identifiable, Equatable {
    let id: UUID
    let rect: CGRect
    
    static func == (lhs: ReorderInfo, rhs: ReorderInfo) -> Bool {
        lhs.id == rhs.id && lhs.rect == rhs.rect
    }
} 