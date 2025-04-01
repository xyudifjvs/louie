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
    @ObservedObject var viewModel = NutritionViewModel2()
    
    @State private var isCaptured = false
    @State private var isAnalyzing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showResultsView = false
    @State private var detectedLabels: [LabelAnnotation] = []
    @State private var analyzedImage: UIImage?
    @State private var useAnimatedFlow = true
    
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
                            // Reset and retake
                            isCaptured = false
                            cameraManager.image = nil
                            cameraManager.setupAndStartSession()
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
                ZStack {
                    CameraPreviewView(session: cameraManager.captureSession)
                        .id(cameraManager.captureSession)
                        .edgesIgnoringSafeArea(.all)
                    
                    // Controls overlay
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
                        .padding(.top, 44) // Add explicit top padding
                        
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
                        .padding(.bottom, 80) // Add more bottom padding
                    }
                    .padding(.horizontal)
                }
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
        .fullScreenCover(isPresented: $showResultsView, onDismiss: {
            // Dismiss back to the main view when the meal flow is completed
            presentationMode.wrappedValue.dismiss()
        }) {
            if useAnimatedFlow {
                // Use the new animated UI flow
                NutritionAnimatedFlowView(
                    foodImage: analyzedImage ?? UIImage(),
                    detectedLabels: detectedLabels.map { FoodLabelAnnotation(description: $0.description, confidence: Double($0.score)) }
                )
            } else {
                // Use the standard UI flow
                FoodDetectionResultView(
                    viewModel: viewModel,
                    detectedLabels: detectedLabels,
                    foodImage: analyzedImage ?? UIImage()
                )
            }
        }
    }
    
    private func checkPermission() {
        cameraManager.checkCameraPermission { granted in
            if granted {
                DispatchQueue.main.async {
                    cameraManager.setupAndStartSession()
                }
            } else {
                alertMessage = "Camera permission was denied. Please enable it in Settings."
                showAlert = true
            }
        }
    }
    
    private func takePicture() {
        // Add haptic feedback for button press
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.impactOccurred()
        
        cameraManager.capturePhoto { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    cameraManager.stopSession()
                    isCaptured = true
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                
                case .failure(let error):
                    alertMessage = error.description
                    showAlert = true
                }
            }
        }
    }
    
    private func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        
        // Use the VisionService directly to analyze the image
        VisionService.shared.analyzeFood(image: image) { result in
            DispatchQueue.main.async {
                self.isAnalyzing = false
                
                switch result {
                case .success(let foodLabels):
                    // Store the results and show the detection view
                    self.detectedLabels = foodLabels
                    self.analyzedImage = image
                    self.showResultsView = true
                    
                case .failure(let error):
                    self.alertMessage = "Food detection failed: \(error.description)"
                    self.showAlert = true
                }
            }
        }
    }
}

// MARK: - Camera Preview UIViewRepresentable
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        guard let session = session else {
            return view
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.session = session
        }
    }
}

// Note: Removed duplicate Color extension here. Using the one from Utilities/Color+Hex.swift


