//
//  FoodDetectionResultView.swift
//  Louie
//
//  Created by Carson on 3/29/25.
//

import SwiftUI

// MARK: - Dummy Decoder for MacroData initialization
struct DummyDecoder: Decoder {
    var codingPath: [CodingKey] { return [] }
    var userInfo: [CodingUserInfoKey: Any] { return [:] }
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        let container = DummyKeyedDecodingContainer<Key>()
        return KeyedDecodingContainer(container)
    }
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return DummyUnkeyedDecodingContainer()
    }
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return DummySingleValueDecodingContainer()
    }
}
 
struct DummyKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    var allKeys: [K] = []
    var codingPath: [CodingKey] = []
    func contains(_ key: K) -> Bool { return false }
    func decodeNil(forKey key: K) throws -> Bool { return true }
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool { return false }
    func decode(_ type: String.Type, forKey key: K) throws -> String { return "" }
    func decode(_ type: Double.Type, forKey key: K) throws -> Double { return 0.0 }
    func decode(_ type: Float.Type, forKey key: K) throws -> Float { return 0.0 }
    func decode(_ type: Int.Type, forKey key: K) throws -> Int { return 0 }
    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 { return 0 }
    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 { return 0 }
    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 { return 0 }
    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 { return 0 }
    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt { return 0 }
    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 { return 0 }
    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 { return 0 }
    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 { return 0 }
    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 { return 0 }
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        return try T(from: DummyDecoder())
    }
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> {
        let container = DummyKeyedDecodingContainer<NestedKey>()
        return KeyedDecodingContainer(container)
    }
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        return DummyUnkeyedDecodingContainer()
    }
    func superDecoder() throws -> Decoder { return DummyDecoder() }
    func superDecoder(forKey key: K) throws -> Decoder { return DummyDecoder() }
}
 
struct DummyUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    var currentIndex: Int = 0
    var count: Int? = 0
    var isAtEnd: Bool { return true }
    var codingPath: [CodingKey] = []
    mutating func decodeNil() throws -> Bool { return true }
    mutating func decode(_ type: Bool.Type) throws -> Bool { return false }
    mutating func decode(_ type: String.Type) throws -> String { return "" }
    mutating func decode(_ type: Double.Type) throws -> Double { return 0.0 }
    mutating func decode(_ type: Float.Type) throws -> Float { return 0.0 }
    mutating func decode(_ type: Int.Type) throws -> Int { return 0 }
    mutating func decode(_ type: Int8.Type) throws -> Int8 { return 0 }
    mutating func decode(_ type: Int16.Type) throws -> Int16 { return 0 }
    mutating func decode(_ type: Int32.Type) throws -> Int32 { return 0 }
    mutating func decode(_ type: Int64.Type) throws -> Int64 { return 0 }
    mutating func decode(_ type: UInt.Type) throws -> UInt { return 0 }
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 { return 0 }
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 { return 0 }
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 { return 0 }
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 { return 0 }
    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        return try T(from: DummyDecoder())
    }
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        let container = DummyKeyedDecodingContainer<NestedKey>()
        return KeyedDecodingContainer(container)
    }
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        return DummyUnkeyedDecodingContainer()
    }
    mutating func superDecoder() throws -> Decoder { return DummyDecoder() }
}
 
struct DummySingleValueDecodingContainer: SingleValueDecodingContainer {
    var codingPath: [CodingKey] = []
    func decodeNil() -> Bool { return true }
    func decode(_ type: Bool.Type) throws -> Bool { return false }
    func decode(_ type: String.Type) throws -> String { return "" }
    func decode(_ type: Double.Type) throws -> Double { return 0.0 }
    func decode(_ type: Float.Type) throws -> Float { return 0.0 }
    func decode(_ type: Int.Type) throws -> Int { return 0 }
    func decode(_ type: Int8.Type) throws -> Int8 { return 0 }
    func decode(_ type: Int16.Type) throws -> Int16 { return 0 }
    func decode(_ type: Int32.Type) throws -> Int32 { return 0 }
    func decode(_ type: Int64.Type) throws -> Int64 { return 0 }
    func decode(_ type: UInt.Type) throws -> UInt { return 0 }
    func decode(_ type: UInt8.Type) throws -> UInt8 { return 0 }
    func decode(_ type: UInt16.Type) throws -> UInt16 { return 0 }
    func decode(_ type: UInt32.Type) throws -> UInt32 { return 0 }
    func decode(_ type: UInt64.Type) throws -> UInt64 { return 0 }
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        return try T(from: DummyDecoder())
    }
}

struct FoodDetectionResultView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel = NutritionViewModel2()
    
    let detectedLabels: [LabelAnnotation]
    let foodImage: UIImage
    
    @State private var selectedLabels: [LabelAnnotation]
    @State private var isAnalyzing = false
    @State private var showingEditView = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var mealEntryToConfirm: MealEntry?
    @State private var showConfirmationView = false
    
    // Initialize with detected labels and preselect all of them
    init(viewModel: NutritionViewModel2, detectedLabels: [LabelAnnotation], foodImage: UIImage) {
        self.viewModel = viewModel
        self.detectedLabels = detectedLabels
        self.foodImage = foodImage
        _selectedLabels = State(initialValue: detectedLabels)
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color(hexCode: "1a1a2e"), Color(hexCode: "2a6041")]),
                          startPoint: .top,
                          endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                Text("Detected Food Items")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Text("Select the items that were detected correctly")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 10)
                
                // Food image
                Image(uiImage: foodImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 15)
                
                // Detected items list
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(detectedLabels, id: \.description) { label in
                            foodItemRow(label)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Button row
                HStack(spacing: 15) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showingEditView = true
                    }) {
                        Text("Edit Items")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color(hexCode: "3a7d5a"))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        proceedToConfirmation()
                    }) {
                        Text("Confirm")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color(hexCode: "2a6041"))
                            .cornerRadius(10)
                    }
                    .disabled(selectedLabels.isEmpty)
                    .opacity(selectedLabels.isEmpty ? 0.5 : 1.0)
                }
                .padding(.vertical, 20)
                .padding(.horizontal)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.white)
            Text("Back")
                .foregroundColor(.white)
        })
        .sheet(isPresented: $showingEditView) {
            // Create placeholder FoodItems from selected labels for editing
            let itemsToEdit = selectedLabels.map { label in
                // Directly initialize using try! as DummyDecoder won't throw
                let macroData = try! MacroData(from: DummyDecoder())
                let microData = try! MicroData(from: DummyDecoder())
                return FoodItem(
                    name: label.description, 
                    amount: "1 serving", 
                    servingAmount: 100,
                    calories: 0, 
                    category: .others,
                    macros: macroData, 
                    micros: microData
                )
            }
            // Use correct labels: items: and from:
            FoodItemEditView(viewModel: viewModel, foodItems: itemsToEdit, meal: nil, image: foodImage)
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .fullScreenCover(isPresented: $showConfirmationView, onDismiss: {
            if !showingError {
                presentationMode.wrappedValue.dismiss()
            }
        }) {
            if let mealEntry = mealEntryToConfirm {
                FoodLogConfirmationView(
                    viewModel: viewModel,
                    mealEntry: mealEntry
                )
            }
        }
    }
    
    // Individual food item row
    private func foodItemRow(_ label: LabelAnnotation) -> some View {
        let isSelected = selectedLabels.contains { $0.description == label.description }
        
        return HStack {
            Text(label.description.capitalized)
                .foregroundColor(.white)
                .padding(.vertical, 8)
            
            Spacer()
            
            Text("\(Int(label.score * 100))%")
                .foregroundColor(.white.opacity(0.7))
                .font(.caption)
                .padding(.trailing, 10)
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? Color(hexCode: "4CD964") : .white.opacity(0.6))
                .font(.system(size: 22))
                .onTapGesture {
                    toggleSelection(label)
                }
        }
        .padding(.horizontal, 15)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }
    
    // Toggle selection of a food item
    private func toggleSelection(_ label: LabelAnnotation) {
        if let index = selectedLabels.firstIndex(where: { $0.description == label.description }) {
            selectedLabels.remove(at: index)
        } else {
            selectedLabels.append(label)
        }
    }
    
    // Proceed to the confirmation step with selected items
    private func proceedToConfirmation() {
        // Remove any loading state and directly get nutrition data
        NutritionService.shared.getNutritionInfo(for: selectedLabels) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let foodItems):
                    // Use AIFoodAnalysisService to create a meal entry with the food items
                    let mealEntry = AIFoodAnalysisService.shared.createMealEntry(
                        from: foodItems,
                        image: self.foodImage,
                        isManuallyAdjusted: true
                    )
                    
                    // Present the confirmation view immediately
                    self.showFoodLogConfirmation(mealEntry: mealEntry)
                    
                case .failure(let error):
                    self.errorMessage = "Failed to get nutrition data: \(error.description)"
                    self.showingError = true
                }
            }
        }
    }
    
    // Navigate to the confirmation view
    private func showFoodLogConfirmation(mealEntry: MealEntry) {
        self.mealEntryToConfirm = mealEntry
        self.showConfirmationView = true
    }
}

// Preview provider
struct FoodDetectionResultView_Previews: PreviewProvider {
    static var previews: some View {
        let mockLabels = [
            LabelAnnotation(description: "Cheeseburger", score: 0.95, topicality: 0.95),
            LabelAnnotation(description: "French fries", score: 0.90, topicality: 0.90),
            LabelAnnotation(description: "Soft drink", score: 0.85, topicality: 0.85)
        ]
        
        return FoodDetectionResultView(
            viewModel: NutritionViewModel2(),
            detectedLabels: mockLabels,
            foodImage: UIImage(systemName: "photo")!
        )
        .preferredColorScheme(.dark)
    }
}
