import SwiftUI

// MARK: - Workouts Module (Dark)
struct WorkoutsView: View {
    @StateObject private var viewModel = WorkoutsViewModel()
    @State private var exercise = ""
    @State private var weight = ""
    @State private var reps = ""
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "5A0000"), Color(hex: "C62828")]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 20) {
                    // Log New Workout Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Log New Workout")
                            .font(.headline)
                            .foregroundColor(.white)
                        TextField("Exercise", text: $exercise)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                        TextField("Weight", text: $weight)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                        TextField("Reps", text: $reps)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                        Button(action: {
                            viewModel.addWorkout(exercise: exercise, weight: weight, reps: reps)
                            exercise = ""
                            weight = ""
                            reps = ""
                        }) {
                            Text("Add Workout")
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    
                    // Workout History Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Workout History")
                            .font(.headline)
                            .foregroundColor(.white)
                        ForEach(viewModel.workouts) { workout in
                            VStack(alignment: .leading) {
                                Text(workout.exercise)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Weight: \(workout.weight), Reps: \(workout.reps)")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Workouts")
        .navigationBarTitleDisplayMode(.inline)
    }
} 