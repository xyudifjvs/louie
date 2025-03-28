import SwiftUI

// MARK: - Nutrition Module
struct NutritionView: View {
    @StateObject private var viewModel = NutritionViewModel()
    @State private var showCameraView = false
    @State private var showPermissionAlert = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color(hexCode: "1a1a2e"), Color(hexCode: "2a6041")]),
                          startPoint: .top,
                          endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 5) {
                    Text("Nutrition")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 10)
                    
                    if !viewModel.meals.isEmpty {
                        Text("Today's nutrition score: \(todayAverageScore)")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.bottom, 5)
                    }
                }
                .padding(.horizontal)
                
                // Meal List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Spacer()
                } else if viewModel.meals.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("No meals logged yet")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("Tap the camera button below to log your first meal")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 20)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(viewModel.meals) { meal in
                                MealCardView(meal: meal)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            
            // Camera Button
            VStack {
                Spacer()
                
                // Replace CircularButton with direct implementation
                Button(action: {
                    checkCameraPermission()
                }) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color(hexCode: "1a1a2e"), Color(hexCode: "2a6041")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    .frame(width: 70, height: 70)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 2)
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showCameraView) {
            CameraView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.fetchMeals()
        }
        .alert(isPresented: $showPermissionAlert) {
            Alert(
                title: Text("Camera Permission Required"),
                message: Text("Louie needs access to your camera to analyze your meals. Please grant camera access in Settings."),
                primaryButton: .default(Text("Open Settings"), action: openSettings),
                secondaryButton: .cancel()
            )
        }
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var todayAverageScore: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let todayMeals = viewModel.meals.filter { 
            Calendar.current.isDate($0.timestamp, inSameDayAs: today)
        }
        
        guard !todayMeals.isEmpty else { return 0 }
        
        let totalScore = todayMeals.reduce(0) { $0 + $1.nutritionScore }
        return totalScore / todayMeals.count
    }
    
    private func checkCameraPermission() {
        CameraManager.shared.checkCameraPermission { granted in
            if granted {
                showCameraView = true
            } else {
                showPermissionAlert = true
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
} 