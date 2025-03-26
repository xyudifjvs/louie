import SwiftUI

// New HabitDashboardView to replace HabitTrackerContent
struct HabitDashboardView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @State private var showAchievements = false
    @State private var showCreateHabit = false
    @State private var isReordering = false
    
    // State variables for drag and reordering
    @State private var draggedHabitID: UUID? = nil
    @State private var originalPosition: CGPoint? = nil
    @State private var dragOffset: CGFloat = 0
    @State private var habitPositions: [UUID: CGFloat] = [:]
    
    // Add wiggle animation state
    @State private var wiggleAmount = false
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with title and action buttons
            ZStack {
                // Centered title
                Text("My Habits")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                // Left aligned buttons
                HStack {
                    NavigationLink(destination: HabitCalendarView(viewModel: viewModel)) {
                        Image(systemName: "calendar")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                
                // Right aligned buttons
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showAchievements = true
                    }) {
                        Image(systemName: "trophy.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        showCreateHabit = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal)
            
            // Habits list
            if viewModel.habits.isEmpty {
                emptyStateView
            } else {
                habitListView
            }
        }
        .sheet(isPresented: $showCreateHabit) {
            CreateHabitPopup(viewModel: viewModel, isPresented: $showCreateHabit)
                .background(BackgroundBlurView())
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsPopup(isPresented: $showAchievements)
                .background(BackgroundBlurView())
        }
        .onChange(of: isReordering) { newValue in
            // Start or stop the animation timer when reordering changes
            if newValue {
                startWiggleTimer()
            } else {
                stopWiggleTimer()
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            stopWiggleTimer()
        }
    }
    
    // Timer functions for wiggle animation
    private func startWiggleTimer() {
        // Reset wiggle state
        wiggleAmount = false
        
        // Create timer that toggles the wiggle state every 0.15 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            wiggleAmount.toggle()
        }
    }
    
    private func stopWiggleTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // Empty state when no habits exist
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.5))
            
            Text("No habits yet")
                .font(.title2)
                .foregroundColor(.white)
            
            Text("Tap + to create your first habit")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
        }
    }
    
    // Scrollable list of habit cards
    private var habitListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(viewModel.habits.enumerated()), id: \.element.id) { index, habit in
                    habitCardView(for: habit, at: index)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            .coordinateSpace(name: "reorderSpace")
            .onPreferenceChange(ReorderPreferenceKey.self) { preferences in
                // Store the positions of all habits
                for preference in preferences {
                    habitPositions[preference.id] = preference.rect.minY
                }
            }
        }
        .overlay(
            isReordering ?
            Button(action: exitReorderingMode) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.purple)
                    .cornerRadius(8)
            }
            .padding()
            .transition(.opacity)
            : nil,
            alignment: .bottom
        )
        // Allow scrolling even when reordering 
        .disabled(false)
    }
    
    // Helper function to create habit card views with appropriate gestures
    private func habitCardView(for habit: Habit, at index: Int) -> some View {
        let card = HabitCardView(
            habit: habit,
            viewModel: viewModel,
            isReordering: $isReordering
        )
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: ReorderPreferenceKey.self,
                    value: [ReorderInfo(id: habit.id, rect: geo.frame(in: .named("reorderSpace")))]
                )
            }
        )
        .offset(y: offsetFor(habit: habit))
        .zIndex(draggedHabitID == habit.id ? 100 : 0) // Give dragged item higher z-index
        
        // Add rotation animation when reordering
        let cardWithRotation = card
            .rotationEffect(isReordering && draggedHabitID != habit.id ? 
                           Angle(degrees: wiggleAmount ? -1 : 1) : .zero)
            .animation(.easeInOut(duration: 0.15), value: wiggleAmount)
        
        // Return card with appropriate gestures
        return AnyView(
            cardWithRotation
                .onLongPressGesture(minimumDuration: 0.5) {
                    if !isReordering {
                        withAnimation {
                            isReordering = true
                            impactFeedback(style: .medium)
                        }
                    }
                }
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            if isReordering {
                                handleDragChange(value: value, habitID: habit.id)
                            }
                        }
                        .onEnded { _ in
                            if isReordering {
                                handleDragEnd()
                            }
                        }
                )
        )
    }
    
    // Helper function to handle drag changes
    private func handleDragChange(value: DragGesture.Value, habitID: UUID) {
        // Always set the draggedHabitID when a drag starts
        if draggedHabitID == nil {
            draggedHabitID = habitID
            originalPosition = value.startLocation
        }
        
        // Only update if this is the habit being dragged
        if draggedHabitID == habitID {
            // Update vertical offset based on drag gesture
            dragOffset = value.translation.height
            
            // Find current position of the dragged habit
            guard let currentIndex = viewModel.habits.firstIndex(where: { $0.id == habitID }) else { return }
            
            // Calculate the current position with the drag offset
            let currentPosition = habitPositions[habitID] ?? 0
            let draggedPosition = currentPosition + dragOffset
            
            // Check if we've dragged over other habits
            for (id, position) in habitPositions where id != habitID {
                // Find the index of the habit we're potentially dragging over
                guard let otherIndex = viewModel.habits.firstIndex(where: { $0.id == id }) else { continue }
                
                // Only consider habits above or below us
                if (draggedPosition > position && currentIndex < otherIndex) || 
                   (draggedPosition < position && currentIndex > otherIndex) {
                    
                    // Perform the reorder
                    withAnimation(.spring()) {
                        viewModel.reorderHabits(fromIndex: currentIndex, toIndex: otherIndex)
                        impactFeedback(style: .light)
                    }
                    
                    // Update positions after a slight delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        // This is needed because the layout may have changed
                        // but don't reset dragOffset to keep dragging smooth
                    }
                    return
                }
            }
        }
    }
    
    // Helper function to handle drag end
    private func handleDragEnd() {
        withAnimation(.spring()) {
            draggedHabitID = nil
            dragOffset = 0
            // Don't exit reordering mode automatically
        }
    }
    
    // Helper function for the Done button
    private func exitReorderingMode() {
        withAnimation {
            isReordering = false
            draggedHabitID = nil
            dragOffset = 0
        }
        stopWiggleTimer()
    }
    
    // Helper function to calculate the offset for each habit card
    private func offsetFor(habit: Habit) -> CGFloat {
        guard let draggedID = draggedHabitID, isReordering else { return 0 }
        
        // If this is the habit being dragged, use the dragOffset
        if habit.id == draggedID {
            return dragOffset
        }
        
        // Otherwise, return 0 as we're handling reordering through the actual list
        return 0
    }
    
    // Haptic feedback helper
    private func impactFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
} 