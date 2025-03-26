import SwiftUI

class WorkoutsViewModel: ObservableObject {
    @Published var workouts: [WorkoutEntry] = []
    
    func addWorkout(exercise: String, weight: String, reps: String) {
        let entry = WorkoutEntry(exercise: exercise, weight: weight, reps: reps)
        workouts.append(entry)
    }
}

struct WorkoutEntry: Identifiable {
    var id = UUID()
    var exercise: String
    var weight: String
    var reps: String
} 