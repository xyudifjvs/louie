import SwiftUI

// Habit Card View
struct HabitCardView: View {
    let habit: Habit
    @ObservedObject var viewModel: HabitTrackerViewModel
    @Binding var isReordering: Bool
    @State private var showMoodTagPopup = false
    @State private var showEditHabit = false
    @State private var isShowingMoodEntry = false
    
    // Swipe gesture state
    @State private var offset: CGFloat = 0
    @State private var isSwiped: Bool = false
    @State private var isEditHabitPresented: Bool = false
    
    var body: some View {
        ZStack {
            // Background swipe action indicators - only shown based on swipe direction
            HStack(spacing: 0) {
                // Complete action (swipe right reveals green checkmark)
                if offset > 0 {
                    Rectangle()
                        .foregroundColor(.green)
                        .frame(width: offset)
                        .overlay(
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.title2)
                                .opacity(min(1.0, CGFloat(offset) / 60.0))
                                .padding(.leading, 16),
                            alignment: .leading
                        )
                }
                
                Spacer()
                
                // Incomplete action (swipe left reveals red X)
                if offset < 0 {
                    Rectangle()
                        .foregroundColor(.red)
                        .frame(width: -offset)
                        .overlay(
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.title2)
                                .opacity(min(1.0, CGFloat(-offset) / 60.0))
                                .padding(.trailing, 16),
                            alignment: .trailing
                        )
                }
            }
            .frame(height: 100)
            .cornerRadius(12)
            
            // Main card content with mood entry view
            VStack(spacing: 0) {
                // Main card content
                HStack(spacing: 0) {
                    // Left section - emoji and edit button
                    VStack(alignment: .center) {
                        Spacer()
                        
                        Text(habitEmoji)
                            .font(.system(size: 42))
                            .frame(width: 65, height: 65)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                        
                        Button(action: {
                            showEditHabit = true
                        }) {
                            Image(systemName: "ellipsis")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    .frame(width: 75)
                    .padding(.vertical, 10)
                    .padding(.leading, 5)
                    
                    // Center section - habit name, streak counter, and weekly progress
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(habit.title)
                                .font(.headline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            // Streak counter moved next to title
                            if showStreakCounter {
                                Text("🔥 \(calculateStreak)")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                                    .padding(4)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Capsule())
                            }
                            
                            Spacer()
                        }
                        
                        if !habit.description.isEmpty {
                            Text(habit.description)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                        
                        // Larger weekly progress view
                        HStack(spacing: 8) {
                            ForEach(-6...0, id: \.self) { dayOffset in
                                // Calculate the date for this offset
                                let calendar = Calendar.current
                                let dateForOffset = calendar.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()

                                // Get the status from the ViewModel
                                let status = viewModel.getCompletionStatusByID(forHabit: habit.id, on: dateForOffset)

                                WeekdayProgressView(
                                    dayOffset: dayOffset,
                                    status: status
                                )
                                .frame(width: 32, height: 32)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.trailing, 5)
                }
                .frame(height: 100)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                
                // Mood entry view that appears when a habit is completed
                if isShowingMoodEntry {
                    HabitMoodEntryView(
                        habit: habit,
                        viewModel: viewModel,
                        isExpanded: $isShowingMoodEntry
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Only allow swiping when not reordering and not showing mood entry
                        if !isReordering && !isShowingMoodEntry {
                            // Limit the drag distance with some resistance
                            let translation = value.translation.width
                            offset = translation > 0 ? min(translation * 0.7, 100) : max(translation * 0.7, -100)
                        }
                    }
                    .onEnded { value in
                        // Only process swipe when not reordering and not showing mood entry
                        if !isReordering && !isShowingMoodEntry {
                            let translation = value.translation.width
                            let velocity = value.predictedEndTranslation.width - value.translation.width
                            let swipeThreshold: CGFloat = 60
                            
                            if translation > swipeThreshold || (translation > 20 && velocity > 100) {
                                // Complete the habit (swipe right)
                                withAnimation(.spring()) {
                                    offset = 0
                                }
                                logHabitAsCompleted()
                                
                            } else if translation < -swipeThreshold || (translation < -20 && velocity < -100) {
                                // Mark as not completed (swipe left)
                                withAnimation(.spring()) {
                                    offset = 0
                                }
                                logHabitAsNotCompleted()
                                
                            } else {
                                // Reset position
                                withAnimation(.spring()) {
                                    offset = 0
                                }
                            }
                        }
                    }
            )
        }
        .animation(.spring(response: 0.3), value: isShowingMoodEntry)
        .sheet(isPresented: $showMoodTagPopup) {
            MoodTagPopup(habit: habit, viewModel: viewModel, isPresented: $showMoodTagPopup)
                .background(BackgroundBlurView())
        }
        .sheet(isPresented: $showEditHabit) {
            EditHabitPopup(habit: habit, viewModel: viewModel, isPresented: $showEditHabit)
                .background(BackgroundBlurView())
        }
    }
    
    // Helper functions for habit logging
    private func logHabitAsCompleted() {
        // Only allow swiping when not reordering
        guard !isReordering else { return }
        
        // Update habit completion status
        if !isCompleted {
            viewModel.toggleCompletion(for: habit)
        }
        
        // Always show inline mood entry regardless of previous completion status
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring()) {
                isShowingMoodEntry = true
            }
        }
    }
    
    private func logHabitAsNotCompleted() {
        // Only allow swiping when not reordering
        guard !isReordering else { return }
        
        if isCompleted {
            viewModel.toggleCompletion(for: habit)
            
            // Hide mood entry if it's showing
            if isShowingMoodEntry {
                withAnimation(.spring()) {
                    isShowingMoodEntry = false
                }
            }
        }
    }
    
    // Use emoji from habit or first letter as fallback
    private var habitEmoji: String {
        if !habit.emoji.isEmpty {
            return habit.emoji
        }
        return String(habit.title.prefix(1))
    }
    
    // Computed properties
    private var isCompleted: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let habitCompletions = viewModel.completions[habit.id],
           let status = habitCompletions[today] {
            return status == .completed
        }
        return habit.completed
    }
    
    private var showStreakCounter: Bool {
        calculateStreak > 0
    }
    
    private var calculateStreak: Int {
        viewModel.calculateStreak(for: habit.id)
    }
} 