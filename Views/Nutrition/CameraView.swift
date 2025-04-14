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
    @ObservedObject var viewModel: NutritionViewModel2
    @Binding var showCameraView: Bool
    
    @State private var isCaptured = false
    @State private var isAnalyzing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showResultsView = false
    @State private var detectedLabels: [LabelAnnotation] = []
    @State private var analyzedImage: UIImage?
    @State private var useAnimatedFlow = true
    @State private var isHorizontalScanActive = false
    @State private var isVerticalScanActive = false
    @State private var horizontalScanProgress: CGFloat = 0.0
    @State private var verticalScanProgress: CGFloat = 0.0
    @State private var animationStartTime: TimeInterval = 0
    
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
            
            // Scanning effect overlay when analyzing
            if isAnalyzing, let image = cameraManager.image {
                GeometryReader { geometry in
                    ZStack {
                        // Transparent overlay to position scan bars
                        Rectangle()
                            .fill(Color.clear)
                            .overlay(
                                ZStack {
                                    // Horizontal scan bar (top to bottom)
                                    if isHorizontalScanActive {
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color(hexCode: "4CD964").opacity(0.3), Color(hexCode: "4CD964"), Color(hexCode: "4CD964").opacity(0.3)]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(height: 15)
                                            .position(x: geometry.size.width / 2, y: geometry.size.height * horizontalScanProgress)
                                            .shadow(color: Color(hexCode: "4CD964").opacity(0.9), radius: 15, x: 0, y: 0)
                                            .overlay(
                                                Rectangle()
                                                    .fill(Color.clear)
                                                    .frame(height: 15)
                                                    .shadow(color: Color(hexCode: "4CD964").opacity(0.6), radius: 10, x: 0, y: 0)
                                            )
                                    }
                                    
                                    // Vertical scan bar (left to right)
                                    if isVerticalScanActive {
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color(hexCode: "4CD964").opacity(0.3), Color(hexCode: "4CD964"), Color(hexCode: "4CD964").opacity(0.3)]),
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .frame(width: 15)
                                            .position(x: geometry.size.width * verticalScanProgress, y: geometry.size.height / 2)
                                            .shadow(color: Color(hexCode: "4CD964").opacity(0.9), radius: 15, x: 0, y: 0)
                                            .overlay(
                                                Rectangle()
                                                    .fill(Color.clear)
                                                    .frame(width: 15)
                                                    .shadow(color: Color(hexCode: "4CD964").opacity(0.6), radius: 10, x: 0, y: 0)
                                            )
                                    }
                                }
                            )
                    }
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear {
            checkPermission()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("DismissAllMealViews"))) { _ in
            // First, set all state variables to false to prevent view reappearance
            self.showResultsView = false
            self.showCameraView = false
            
            // Then dismiss the view with a slight delay to ensure state updates first
            DispatchQueue.main.async {
                presentationMode.wrappedValue.dismiss()
            }
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
            // Set showCameraView to false *before* dismissal to prevent reappearance
            showCameraView = false
            presentationMode.wrappedValue.dismiss()
        }) {
            if useAnimatedFlow {
                // Use the new animated UI flow
                NutritionAnimatedFlowView(
                    viewModel: viewModel,
                    showView: $showResultsView,
                    foodImage: analyzedImage ?? UIImage(),
                    detectedLabels: detectedLabels.map { 
                        FoodLabelAnnotation(description: $0.description, confidence: Double($0.score))
                    }
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
        
        // Record animation start time
        animationStartTime = Date().timeIntervalSince1970
        
        // Store the image immediately
        self.analyzedImage = image
        
        // Start horizontal scan animation
        isHorizontalScanActive = true
        withAnimation(.linear(duration: 1.5)) {
            horizontalScanProgress = 1.0
        }
        
        // After horizontal scan completes, start vertical scan
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isHorizontalScanActive = false
            isVerticalScanActive = true
            withAnimation(.linear(duration: 1.5)) {
                verticalScanProgress = 1.0
            }
        }
        
        // Process image on background thread with high priority
        DispatchQueue.global(qos: .userInteractive).async {
            // Pre-process image to smaller size before API call
            let processedImage = self.optimizeImageForAnalysis(image)
            
            // Use the VisionService to analyze the image
            VisionService.shared.analyzeFood(image: processedImage) { result in
                DispatchQueue.main.async {
                    // Calculate time elapsed since animation started
                    let elapsedTime = Date().timeIntervalSince1970 - self.animationStartTime
                    let remainingAnimationTime = max(0, 3.0 - elapsedTime)
                    
                    // Wait for both animations to complete before showing results
                    DispatchQueue.main.asyncAfter(deadline: .now() + remainingAnimationTime) {
                        self.isAnalyzing = false
                        self.isVerticalScanActive = false
                        self.horizontalScanProgress = 0.0
                        self.verticalScanProgress = 0.0
                        
                        switch result {
                        case .success(let foodLabels):
                            // Store the results and show the detection view
                            self.detectedLabels = foodLabels
                            self.showResultsView = true
                            
                        case .failure(let error):
                            self.alertMessage = "Food detection failed: \(error.description)"
                            self.showAlert = true
                        }
                    }
                }
            }
        }
    }
    
    // Helper method to optimize images before sending to API
    private func optimizeImageForAnalysis(_ image: UIImage) -> UIImage {
        // Use a smaller max dimension (800px instead of 1024px)
        let maxDimension: CGFloat = 800
        
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        
        // Check if resizing is needed
        if originalWidth <= maxDimension && originalHeight <= maxDimension {
            return image
        }
        
        // Calculate new dimensions while maintaining aspect ratio
        var newWidth: CGFloat
        var newHeight: CGFloat
        
        if originalWidth > originalHeight {
            newWidth = maxDimension
            newHeight = (originalHeight / originalWidth) * maxDimension
        } else {
            newHeight = maxDimension
            newWidth = (originalWidth / originalHeight) * maxDimension
        }
        
        // Create a new context and draw the resized image
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: newHeight), false, 1.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return resizedImage
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


