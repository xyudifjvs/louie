import SwiftUI

struct HabitMoodEntryView: View {
    let habit: Habit
    @ObservedObject var viewModel: HabitTrackerViewModel
    @Binding var isExpanded: Bool
    @State private var selectedMood: String?
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    @State private var isSaved: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    // Mood options
    private let moodOptions: [(emoji: String, label: String)] = [
        ("😞", "Bad"),
        ("😐", "Okay"),
        ("🙂", "Good"),
        ("😊", "Great"),
        ("🤩", "Excellent")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How did it feel?")
                .font(.headline)
                .foregroundColor(.white)
            
            // Mood picker
            HStack(spacing: 12) {
                ForEach(moodOptions, id: \.emoji) { mood in
                    let isSelected = selectedMood == mood.emoji
                    
                    VStack(spacing: 4) {
                        Text(mood.emoji)
                            .font(.system(size: 28))
                            .frame(width: 44, height: 44)
                            .background(isSelected ? Color.white.opacity(0.2) : Color.clear)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                        
                        Text(mood.label)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedMood = mood.emoji
                            saveData()
                            
                            // Dismiss keyboard if it's open
                            isTextFieldFocused = false
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            
            // Notes field
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes (optional)")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                TextEditor(text: $notes)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .focused($isTextFieldFocused)
                    .onChange(of: notes) { _ in
                        // Debounce saving
                        isSaved = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            saveData()
                        }
                    }
                
                HStack {
                    Text("\(notes.count)/100 characters")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    // Save indicator
                    if isSaving {
                        Text("Saving...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else if isSaved {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Saved")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Done button
            Button {
                // Dismiss keyboard
                isTextFieldFocused = false
                
                withAnimation(.spring(response: 0.3)) {
                    isExpanded = false
                }
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(8)
            }
            
            // Keyboard dismiss button when keyboard is visible
            if isTextFieldFocused {
                Button {
                    isTextFieldFocused = false
                } label: {
                    Text("Dismiss Keyboard")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.top, 8)
                .transition(.opacity)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .onTapGesture {
            // Dismiss keyboard when tapping anywhere in the view
            isTextFieldFocused = false
        }
        .animation(.spring(response: 0.3), value: isTextFieldFocused)
        .onAppear {
            // Load existing data if available
            if let existingMood = viewModel.getMoodForHabit(habit.id, forDate: Date()) {
                selectedMood = existingMood
            }
            
            if let existingNotes = viewModel.getNotesForHabit(habit.id, forDate: Date()) {
                notes = existingNotes
            }
        }
    }
    
    private func saveData() {
        isSaving = true
        
        // Save mood and notes
        viewModel.saveMoodForHabit(habit.id, mood: selectedMood, forDate: Date())
        viewModel.saveNotesForHabit(habit.id, notes: notes, forDate: Date())
        
        // Show saved indicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            isSaved = true
        }
    }
} 