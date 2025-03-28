//
//  CameraView.swift
//  Louie
//
//  Created by Carson on 3/28/25.
//

import SwiftUI
import AVFoundation
import UIKit

struct CameraView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var cameraManager = CameraManager.shared
    @ObservedObject var viewModel: NutritionViewModel
    
    @State private var isCaptured = false
    @State private var isAnalyzing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            if isCaptured, let image = cameraManager.image {
                // Show captured image for review
                VStack {
                    Text("Review Photo")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    
                    HStack(spacing: 50) {
                        Button(action: {
                            isCaptured = false
                            cameraManager.image = nil
                            cameraManager.startSession()
                        }) {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("Retake")
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            analyzeImage(image)
                        }) {
                            HStack {
                                Text("Analyze")
                                Image(systemName: "arrow.right")
                            }
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color(hexCode: "1a1a2e"), Color(hexCode: "2a6041")]), startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                        }
                    }
                    .padding(.bottom, 40)
                }
            } else {
                // Show camera preview
                CameraPreviewView(session: cameraManager.setupCaptureSession())
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            HStack {
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.title)
                                        .foregroundColor(.white)
                                        .padding()
                                }
                                
                                Spacer()
                            }
                            
                            Spacer()
                            
                            // Capture button
                            Button(action: {
                                takePicture()
                            }) {
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .frame(width: 70, height: 70)
                                    .overlay(
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 60, height: 60)
                                    )
                            }
                            .padding(.bottom, 40)
                        }
                    )
            }
            
            // Loading overlay when analyzing
            if isAnalyzing {
                Rectangle()
                    .fill(Color.black.opacity(0.7))
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            Text("Analyzing your meal...")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                                .padding()
                        }
                    )
            }
        }
        .onAppear {
            checkPermission()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Camera Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func checkPermission() {
        cameraManager.checkCameraPermission { granted in
            if granted {
                DispatchQueue.main.async {
                    cameraManager.startSession()
                }
            } else {
                alertMessage = CameraError.permissionDenied.description
                showAlert = true
            }
        }
    }
    
    private func takePicture() {
        cameraManager.capturePhoto { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    cameraManager.stopSession()
                    isCaptured = true
                    playHapticFeedback()
                
                case .failure(let error):
                    alertMessage = error.description
                    showAlert = true
                }
            }
        }
    }
    
    private func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        
        // Convert the image to Data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            isAnalyzing = false
            alertMessage = "Failed to process image"
            showAlert = true
            return
        }
        
        // In a real implementation, we would send this image to an API
        // For now, we'll simulate an API call with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Create mock data for testing
            let mockFoodItems = [
                FoodItem(
                    id: UUID(),
                    name: "Grilled Chicken Breast",
                    amount: "4 oz",
                    calories: 180,
                    macros: MacroData(protein: 35, carbs: 0, fat: 4, fiber: 0, sugar: 0),
                    micros: MicroData(niacin: 13.5, vitaminB6: 0.5, phosphorus: 220, selenium: 27)
                ),
                FoodItem(
                    id: UUID(),
                    name: "Brown Rice",
                    amount: "1 cup",
                    calories: 220,
                    macros: MacroData(protein: 5, carbs: 45, fat: 2, fiber: 3.5, sugar: 0),
                    micros: MicroData(magnesium: 86, phosphorus: 162, manganese: 2.1, selenium: 19.1)
                ),
                FoodItem(
                    id: UUID(),
                    name: "Broccoli",
                    amount: "1 cup",
                    calories: 55,
                    macros: MacroData(protein: 3.7, carbs: 11.2, fat: 0.6, fiber: 5.1, sugar: 2.6),
                    micros: MicroData(vitaminC: 135.2, vitaminK: 116, folate: 57.3, manganese: 0.4)
                )
            ]
            
            // Calculate combined macros for all foods
            let totalMacros = mockFoodItems.reduce(
                MacroData(protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0)
            ) { result, item in
                MacroData(
                    protein: result.protein + item.macros.protein,
                    carbs: result.carbs + item.macros.carbs,
                    fat: result.fat + item.macros.fat,
                    fiber: result.fiber + item.macros.fiber,
                    sugar: result.sugar + item.macros.sugar
                )
            }
            
            // Create a new micronutrient struct with all the foods' micros combined
            var totalMicros = MicroData()
            
            // Calculate nutrition score
            let nutritionScore = viewModel.calculateNutritionScore(foods: mockFoodItems)
            
            // Create meal entry
            let mealEntry = MealEntry(
                id: UUID(),
                timestamp: Date(),
                imageData: imageData,
                imageURL: nil,
                foods: mockFoodItems,
                nutritionScore: nutritionScore,
                macronutrients: totalMacros,
                micronutrients: totalMicros,
                userNotes: nil,
                isManuallyAdjusted: false
            )
            
            // Save meal to CloudKit
            viewModel.saveMeal(mealEntry)
            
            isAnalyzing = false
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func playHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Camera Preview UIViewRepresentable
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        guard let session = session else { return view }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// Note: Removed duplicate Color extension here. Using the one from Utilities/Color+Hex.swift 
