import SwiftUI

// Mood tag popup
struct MoodTagPopup: View {
    let habit: Habit
    @ObservedObject var viewModel: HabitTrackerViewModel
    @Binding var isPresented: Bool
    @State private var showReflection = false
    @State private var selectedMood: Mood?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("How do you feel?")
                .font(.headline)
                .foregroundColor(.white)
            
            // Mood buttons row
            moodButtonsRow
            
            // Action buttons row
            actionButtonsRow
        }
        .padding(30)
        .background(Color.black.opacity(0.6))
        .cornerRadius(20)
        .sheet(isPresented: $showReflection) {
            if let mood = selectedMood {
                MoodReflectionPopup(
                    habit: habit,
                    viewModel: viewModel,
                    mood: mood,
                    isPresented: $showReflection,
                    parentPresented: $isPresented
                )
            }
        }
    }
    
    // Extracted mood selection buttons
    private var moodButtonsRow: some View {
        HStack(spacing: 30) {
            ForEach([Mood.happy, .neutral, .angry, .sad], id: \.self) { mood in
                Button(action: {
                    selectMood(mood)
                }) {
                    VStack {
                        Text(mood.rawValue)
                            .font(.system(size: 40))
                        
                        Text(mood.description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(8)
                    .background(selectedMood == mood ? Color.purple.opacity(0.3) : Color.clear)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // Extracted action buttons
    private var actionButtonsRow: some View {
        HStack {
            Spacer()
            
            // Save button
            saveButton
            
            Spacer()
            
            // Add Notes button
            addNotesButton
        }
    }
    
    // Save button
    private var saveButton: some View {
        Button(action: {
            guard let mood = selectedMood else { return }
            // Save mood without reflection
            viewModel.addMoodEntry(for: habit, mood: mood)
            isPresented = false
        }) {
            Text("Save")
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.purple)
                .cornerRadius(8)
        }
        .disabled(selectedMood == nil)
        .opacity(selectedMood == nil ? 0.5 : 1)
    }
    
    // Add Notes button
    private var addNotesButton: some View {
        Button(action: {
            guard let mood = selectedMood else { return }
            // Save mood temporarily and show reflection popup
            showReflection = true
        }) {
            HStack {
                Text("Add Notes")
                Image(systemName: "pencil")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .cornerRadius(8)
        }
        .disabled(selectedMood == nil)
        .opacity(selectedMood == nil ? 0.5 : 1)
    }
    
    private func selectMood(_ mood: Mood) {
        withAnimation {
            selectedMood = mood
        }
    }
}

// Mood reflection popup
struct MoodReflectionPopup: View {
    let habit: Habit
    let viewModel: HabitTrackerViewModel
    let mood: Mood
    @Binding var isPresented: Bool
    @Binding var parentPresented: Bool
    @State private var reflectionText = ""
    @State private var shouldDismissParent = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("How are you feeling \(mood.rawValue)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            
            TextEditor(text: $reflectionText)
                .frame(height: 150)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .foregroundColor(.white)
            
            // Save button
            Button(action: {
                // Create a local copy of the binding flag
                let shouldDismissParent = true
                
                // First dismiss this sheet
                isPresented = false
                
                // Then dismiss parent after a delay
                if shouldDismissParent {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        parentPresented = false 
                    }
                }
                
                // Save mood with reflection
                viewModel.addMoodEntry(for: habit, mood: mood, reflection: reflectionText)
            }) {
                Text("Save Reflection")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .background(BackgroundBlurView())
    }
} 