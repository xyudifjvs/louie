import SwiftUI
// ChatGPT Integration Successful

// MARK: - App Entry
// If you already have an @main declared elsewhere, remove or comment out this section.

// MARK: - ContentView with Splash + TabView
struct ContentView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                DarkSplashScreen()
                    .transition(.opacity)
            } else {
                MainTabView() // Show the TabView after splash
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}

// A darker, modern splash screen
struct DarkSplashScreen: View {
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.indigo]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Image(systemName: "brain.head.profile")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.white)
                Text("Optimize")
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 10)
        }
    }
}

// MARK: - Habit Grid Components

/// Represents the completion status of a habit for a specific day
enum CompletionStatus: Int, Codable {
    case noData = 0      // Not logged (gray)
    case completed = 1   // Completed (green)
    case notCompleted = 2 // Not completed (red)
    
    /// Returns the next status in the cycle: noData -> completed -> notCompleted -> noData
    var next: CompletionStatus {
        switch self {
        case .noData: return .completed
        case .completed: return .notCompleted
        case .notCompleted: return .noData
        }
    }
    
    /// Returns the color associated with this status
    var color: Color {
        switch self {
        case .noData: return Color.gray.opacity(0.3)
        case .completed: return Color.green.opacity(0.8)
        case .notCompleted: return Color.red.opacity(0.8)
        }
    }
}

/// A calendar-style grid view for displaying and updating habit completion status
struct HabitGridView: View {
    // MARK: - Properties
    
    /// The habit to display and update
    @ObservedObject var viewModel: HabitViewModel
    
    /// The habit being displayed
    let habit: Habit
    
    /// The month to display (any date within the month)
    let month: Date
    
    /// Size of each cell in the grid
    private let cellSize: CGFloat = 35
    
    // MARK: - Computed Properties
    
    /// Returns all dates to display in the grid, including days from adjacent months
    private var gridDates: [Date] {
        // Get the first day of the month
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let firstDayOfMonth = calendar.date(from: components) else { return [] }
        
        // Find the first Sunday before or on the first day of the month
        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysToSubtract = weekday - 1 // Sunday is 1 in Calendar
        guard let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstDayOfMonth) else { return [] }
        
        // Find the last day of the month
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth),
              let lastDayOfMonth = calendar.date(byAdding: .day, value: -1, to: nextMonth) else { return [] }
        
        // Find the last Saturday after or on the last day of the month
        let lastWeekday = calendar.component(.weekday, from: lastDayOfMonth)
        let daysToAdd = 7 - lastWeekday // Saturday is 7 in Calendar
        guard let endDate = calendar.date(byAdding: .day, value: daysToAdd, to: lastDayOfMonth) else { return [] }
        
        // Generate all dates from startDate to endDate
        var dates: [Date] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return dates
    }
    
    /// Returns the weekday labels (S, M, T, W, T, F, S)
    private var weekdayLabels: [String] {
        ["S", "M", "T", "W", "T", "F", "S"]
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 8) {
            // Weekday header row
            HStack(spacing: 0) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: cellSize, height: 20)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: 0), count: 7), spacing: 4) {
                ForEach(gridDates, id: \.timeIntervalSince1970) { date in
                    DayCell(
                        date: date,
                        month: month,
                        status: completionStatus(for: date),
                        cellSize: cellSize,
                        onTap: { toggleStatus(for: date) }
                    )
                }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    /// Returns the completion status for a given date
    private func completionStatus(for date: Date) -> CompletionStatus {
        // Get the start of the day (midnight) for the given date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Look up the status in the habit's completions dictionary
        return viewModel.getCompletionStatus(for: habit, on: startOfDay)
    }
    
    /// Toggles the completion status for a given date
    private func toggleStatus(for date: Date) {
        // Get the start of the day (midnight) for the given date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Update the status in the view model
        viewModel.toggleCompletionStatus(for: habit, on: startOfDay)
    }
}

/// A single day cell in the habit grid
struct DayCell: View {
    // MARK: - Properties
    
    /// The date this cell represents
    let date: Date
    
    /// The month being displayed
    let month: Date
    
    /// The completion status for this date
    let status: CompletionStatus
    
    /// The size of the cell
    let cellSize: CGFloat
    
    /// Callback when the cell is tapped
    let onTap: () -> Void
    
    // MARK: - Computed Properties
    
    /// Returns true if this date is in the displayed month
    private var isInCurrentMonth: Bool {
        let calendar = Calendar.current
        return calendar.component(.month, from: date) == calendar.component(.month, from: month)
    }
    
    /// Returns the day number as a string
    private var dayText: String {
        let calendar = Calendar.current
        return "\(calendar.component(.day, from: date))"
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                Text(dayText)
                    .font(.caption)
                    .foregroundColor(.white)
                    .opacity(isInCurrentMonth ? 1.0 : 0.5)
                
                Rectangle()
                    .fill(status.color)
                    .opacity(isInCurrentMonth ? 1.0 : 0.5)
                    .frame(width: cellSize - 8, height: cellSize - 20)
                    .cornerRadius(4)
            }
            .frame(width: cellSize, height: cellSize)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Add HabitViewModel class
class HabitViewModel: ObservableObject {
    // MARK: - Properties
    
    /// Published property to trigger view updates
    @Published var habits: [Habit] = []
    
    /// Dictionary to store completion status for each habit and date
    @Published var completions: [UUID: [Date: CompletionStatus]] = [:]
    
    // MARK: - Methods
    
    /// Returns the completion status for a habit on a specific date
    func getCompletionStatus(for habit: Habit, on date: Date) -> CompletionStatus {
        guard let habitCompletions = completions[habit.id] else {
            return .noData
        }
        
        return habitCompletions[date] ?? .noData
    }
    
    /// Toggles the completion status for a habit on a specific date
    func toggleCompletionStatus(for habit: Habit, on date: Date) {
        // Ensure we have a dictionary for this habit
        if completions[habit.id] == nil {
            completions[habit.id] = [:]
        }
        
        // Get the current status and toggle to the next one
        let currentStatus = getCompletionStatus(for: habit, on: date)
        completions[habit.id]?[date] = currentStatus.next
        
        // Also update the habit's progress dictionary for compatibility with existing code
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            let day = Calendar.current.component(.day, from: date)
            let isCompleted = currentStatus.next == .completed
            habits[index].progress[day] = isCompleted
        }
        
        // Save the updated completions
        saveCompletions()
    }
    
    /// Saves the completions dictionary to UserDefaults
    private func saveCompletions() {
        // Implementation would go here - convert completions to Data and save to UserDefaults
    }
    
    /// Loads the completions dictionary from UserDefaults
    private func loadCompletions() {
        // Implementation would go here - load Data from UserDefaults and convert to completions dictionary
    }
    
    /// Initializer to convert from HabitTrackerViewModel
    init(from tracker: HabitTrackerViewModel) {
        self.habits = tracker.habits
        self.completions = tracker.completions
    }
}

struct MainTabView: View {
    
    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor.white.withAlphaComponent(0.6)
        UITabBar.appearance().tintColor = UIColor.white
    }
    
    var body: some View {
        TabView {
            NavigationView { HabitTrackerView() }
                .tabItem {
                    Label("Habits", systemImage: "list.bullet.rectangle")
                }

            NavigationView { HealthInfoView() }
                .tabItem {
                    Label("Health", systemImage: "heart.fill")
                }

            NavigationView { NutritionView() }
                .tabItem {
                    Label("Nutrition", systemImage: "leaf.fill")
                }

            NavigationView { WorkoutsView() }
                .tabItem {
                    Label("Workouts", systemImage: "flame.fill")
                }

            NavigationView { DailyCheckInView() }
                .tabItem {
                    Label("Check-In", systemImage: "bubble.left.and.bubble.right")
                }

            NavigationView {
                GamificationView()
            }
                .tabItem {
                    Label("Rewards", systemImage: "star.fill")
                }
        }
        .accentColor(.white)
    }
}

// MARK: - Habit Tracker Module (Dark UI Example)
class HabitTrackerViewModel: ObservableObject {
    @Published var habits: [Habit] = [] {
        didSet {
            saveHabits()
        }
    }
    
    // Add completions dictionary for habit status tracking
    @Published var completions: [UUID: [Date: CompletionStatus]] = [:]
    
    init() {
        loadHabits()
    }
    
    func addHabit(title: String, description: String, reminderTime: Date, frequency: HabitFrequency, customDays: [Int] = [], emoji: String = "📝") {
        guard !title.isEmpty else { return }
        let newHabit = Habit(
            title: title,
            description: description,
            reminderTime: reminderTime,
            frequency: frequency,
            customDays: frequency == .custom ? customDays : [],
            emoji: emoji
        )
        // Insert the new habit at the top of the list
        habits.insert(newHabit, at: 0)
    }
    
    func toggleCompletion(for habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index].completed.toggle()
            let day = Calendar.current.component(.day, from: Date())
            habits[index].progress[day] = habits[index].completed
            
            // Update completions dictionary for HabitGridView compatibility
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            if completions[habit.id] == nil {
                completions[habit.id] = [:]
            }
            
            let status: CompletionStatus = habits[index].completed ? .completed : .notCompleted
            completions[habit.id]?[today] = status
        }
    }
    
    // Function to get completion status for a habit on a specific date
    func getCompletionStatus(for habit: Habit, on date: Date) -> CompletionStatus {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Check in completions dictionary first
        if let habitCompletions = completions[habit.id],
           let status = habitCompletions[startOfDay] {
            return status
        }
        
        // Check in old progress format as fallback
        let day = calendar.component(.day, from: date)
        if let isCompleted = habit.progress[day] {
            return isCompleted ? .completed : .notCompleted
        }
        
        return .noData
    }
    
    func reorderHabits(fromIndex: Int, toIndex: Int) {
        guard fromIndex != toIndex && fromIndex >= 0 && fromIndex < habits.count && toIndex >= 0 && toIndex < habits.count else { return }
        
        let habit = habits.remove(at: fromIndex)
        habits.insert(habit, at: toIndex)
    }
    
    func deleteHabit(at indexSet: IndexSet) {
        habits.remove(atOffsets: indexSet)
    }
    
    // MARK: - Persistence
    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: "habits")
        }
    }
    
    private func loadHabits() {
        if let savedHabits = UserDefaults.standard.data(forKey: "habits") {
            if let decodedHabits = try? JSONDecoder().decode([Habit].self, from: savedHabits) {
                habits = decodedHabits
            }
        }
    }
    
    func addMoodEntry(for habit: Habit, mood: Mood, reflection: String = "") {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            let today = Calendar.current.startOfDay(for: Date())
            let moodEntry = MoodEntry(mood: mood, reflection: reflection, date: today)
            habits[index].moodEntries[today] = moodEntry
        }
    }
    
    func getMoodEntry(for habit: Habit, on date: Date = Date()) -> MoodEntry? {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            let day = Calendar.current.startOfDay(for: date)
            return habits[index].moodEntries[day]
        }
        return nil
    }
    
    // Calculate the current streak for a habit
    func calculateStreak(for habit: Habit) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var currentStreak = 0
        var dayToCheck = today
        
        // Loop backward through days until we find a day without completion
        while true {
            let day = calendar.component(.day, from: dayToCheck)
            
            // Check if the habit was completed on this day
            if let isCompleted = habit.progress[day], isCompleted {
                currentStreak += 1
            } else if let habitCompletions = self.completions[habit.id],
                      let status = habitCompletions[dayToCheck], 
                      status == .completed {
                currentStreak += 1
            } else {
                // Break the streak if not completed and it's a day the habit should be done
                if shouldCompleteHabit(habit, on: dayToCheck) {
                    break
                }
                // If it's not a day the habit should be done, continue the streak
            }
            
            // Move to the previous day
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: dayToCheck) else {
                break
            }
            dayToCheck = previousDay
            
            // Limit streak calculation to prevent infinite loops (e.g., 365 days)
            if currentStreak > 365 {
                break
            }
        }
        
        return currentStreak
    }
    
    // Helper function to determine if a habit should be completed on a specific day
    private func shouldCompleteHabit(_ habit: Habit, on date: Date) -> Bool {
        let calendar = Calendar.current
        
        switch habit.frequency {
        case .daily:
            return true
            
        case .weekly:
            // Default to Monday if not specified
            let weekday = calendar.component(.weekday, from: date)
            return weekday == 2 // Monday
            
        case .monthly:
            // Default to 1st day of month
            let day = calendar.component(.day, from: date)
            return day == 1
            
        case .custom:
            // Check if the current weekday is in customDays
            let weekday = calendar.component(.weekday, from: date)
            // Convert from Sunday-based (1-7) to Monday-based (1-7)
            let adjustedWeekday = weekday == 1 ? 7 : weekday - 1
            return habit.customDays.contains(adjustedWeekday)
        }
    }
}

struct Habit: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String = ""
    var reminderTime: Date
    var completed: Bool = false
    var progress: [Int: Bool] = [:]
    var frequency: HabitFrequency = .daily
    var customDays: [Int] = [] // 1 = Monday, 2 = Tuesday, etc.
    var emoji: String = "📝" // Default emoji
    
    // Mood tracking
    var moodEntries: [Date: MoodEntry] = [:]
}

// Enum for tracking user mood
enum Mood: String, Codable {
    case happy = "😊"
    case neutral = "😐"
    case angry = "😠"
    case sad = "😢"
    
    var description: String {
        switch self {
        case .happy: return "Happy"
        case .neutral: return "Indifferent"
        case .angry: return "Angry"
        case .sad: return "Sad"
        }
    }
}

// Structure to store mood and reflection
struct MoodEntry: Codable {
    var mood: Mood
    var reflection: String
    var date: Date
}

enum HabitFrequency: String, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case custom = "Custom"
}

struct HabitTrackerView: View {
    @StateObject private var viewModel = HabitTrackerViewModel()
    @State private var showingAddHabitSheet = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "6a3093"), Color(hex: "a044ff")]),
                          startPoint: .top,
                          endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            HabitDashboardView(viewModel: viewModel)
        }
    }
}

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
            Button(action: {
                withAnimation {
                    isReordering = false
                    draggedHabitID = nil
                    dragOffset = 0
                }
            }) {
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
        .offset(y: dragOffset(for: habit.id))
        .zIndex(draggedHabitID == habit.id ? 1 : 0)
        
        // Add rotation animation when reordering
        let cardWithRotation = card
            .rotationEffect(isReordering && draggedHabitID != habit.id ? 
                            Angle(degrees: -1 + Double.random(in: 0...2)) : .zero)
            .animation(isReordering && draggedHabitID != habit.id ? 
                      Animation.easeInOut(duration: 0.15).repeatForever(autoreverses: true) : .default, 
                      value: isReordering)
        
        // Return card with appropriate gestures attached
        if isReordering {
            return AnyView(
                cardWithRotation.onLongPressGesture {
                    // Nothing happens on long press during reordering
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            handleDragChange(value: value, habitID: habit.id)
                        }
                        .onEnded { _ in
                            handleDragEnd()
                        }
                )
            )
        } else {
            return AnyView(
                cardWithRotation.onLongPressGesture(minimumDuration: 0.5) {
                    withAnimation {
                        isReordering = true
                        impactFeedback(style: .medium)
                    }
                }
            )
        }
    }
    
    // Helper function to handle drag changes
    private func handleDragChange(value: DragGesture.Value, habitID: UUID) {
        if draggedHabitID == nil {
            draggedHabitID = habitID
            originalPosition = value.startLocation
        }
        
        if draggedHabitID == habitID {
            dragOffset = value.translation.height
            
            let currentPosition = habitPositions[habitID] ?? 0
            let newPosition = findNewPosition(from: currentPosition, offset: dragOffset)
            
            if let fromIndex = viewModel.habits.firstIndex(where: { $0.id == habitID }),
               let toIndex = Int(exactly: min(max(0, newPosition), viewModel.habits.count - 1)),
               fromIndex != toIndex {
                withAnimation(.spring()) {
                    viewModel.reorderHabits(fromIndex: fromIndex, toIndex: toIndex)
                    impactFeedback(style: .light)
                }
            }
        }
    }
    
    // Helper function to handle drag end
    private func handleDragEnd() {
        withAnimation(.spring()) {
            draggedHabitID = nil
            dragOffset = 0
            isReordering = false
        }
    }
    
    // Helper function to calculate the offset for each habit during drag
    private func dragOffset(for habitID: UUID) -> CGFloat {
        guard let draggedID = draggedHabitID else { return 0 }
        if habitID == draggedID {
            return dragOffset
        }
        return 0
    }
    
    // Helper function to find the new position for a dragged habit
    private func findNewPosition(from currentPosition: CGFloat, offset: CGFloat) -> Int {
        let targetPosition = currentPosition + offset
        
        // Sort the positions
        let sortedPositions = habitPositions.sorted { $0.value < $1.value }
        
        // Find the position index where the target position fits
        for (index, position) in sortedPositions.enumerated() {
            if targetPosition < position.value {
                return index
            }
        }
        
        return sortedPositions.count - 1
    }
    
    // Haptic feedback helper
    private func impactFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// Habit Card View
struct HabitCardView: View {
    let habit: Habit
    @ObservedObject var viewModel: HabitTrackerViewModel
    @Binding var isReordering: Bool
    @State private var showMoodTagPopup = false
    @State private var showEditHabit = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Left section - emoji and edit button
            VStack(alignment: .center) {
                Button(action: {
                    showEditHabit = true
                }) {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Text(habitEmoji)
                    .font(.system(size: 30))
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                
                Spacer()
            }
            .frame(width: 60)
            .padding(.vertical, 10)
            
            // Center section - habit name and weekly progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(habit.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let moodEntry = viewModel.getMoodEntry(for: habit) {
                        Text(moodEntry.mood.rawValue)
                            .font(.caption2)
                    }
                }
                
                if !habit.description.isEmpty {
                    Text(habit.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                HStack(spacing: 4) {
                    ForEach(-6...0, id: \.self) { dayOffset in
                        WeekdayProgressView(
                            dayOffset: dayOffset,
                            habit: habit
                        )
                    }
                }
            }
            .padding(.horizontal, 10)
            
            // Right section - completion checkmark
            VStack {
                Button(action: {
                    viewModel.toggleCompletion(for: habit)
                    
                    // Fixed: Check if habit is marked as completed after toggling
                    let isNowCompleted = habit.completed || 
                        (viewModel.completions[habit.id]?[Calendar.current.startOfDay(for: Date())] == .completed)
                    
                    if isNowCompleted {
                        showMoodTagPopup = true
                    }
                }) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 30))
                        .foregroundColor(isCompleted ? .green : .white.opacity(0.7))
                }
                
                if showStreakCounter {
                    Text("🔥 \(calculateStreak)")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                        .padding(4)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Capsule())
                }
            }
            .frame(width: 60)
            .padding(.trailing, 10)
        }
        .frame(height: 100)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .sheet(isPresented: $showMoodTagPopup) {
            MoodTagPopup(habit: habit, viewModel: viewModel, isPresented: $showMoodTagPopup)
                .background(BackgroundBlurView())
        }
        .sheet(isPresented: $showEditHabit) {
            EditHabitPopup(habit: habit, viewModel: viewModel, isPresented: $showEditHabit)
                .background(BackgroundBlurView())
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
        // Placeholder logic - would depend on user settings
        return true
    }
    
    private var calculateStreak: Int {
        return viewModel.calculateStreak(for: habit)
    }
}

// Weekday progress view (single day cell)
struct WeekdayProgressView: View {
    let dayOffset: Int
    let habit: Habit
    
    var body: some View {
        VStack(spacing: 2) {
            Text(dayLabel)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
            
            Circle()
                .fill(dayColor)
                .frame(width: 20, height: 20)
        }
    }
    
    // Computed properties
    private var dayLabel: String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date).prefix(1).uppercased()
    }
    
    private var dayColor: Color {
        let calendar = Calendar.current
        guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else {
            return Color.gray.opacity(0.3)
        }
        
        let day = calendar.component(.day, from: date)
        
        // Check if habit was completed on this day
        if let isCompleted = habit.progress[day] {
            return isCompleted ? .green : .red
        }
        
        // No data for this day
        return Color.gray.opacity(0.3)
    }
}

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
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            
            HStack {
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: {
                    saveReflection()
                    // Set flag to dismiss parent after this is dismissed
                    shouldDismissParent = true
                    // Dismiss this sheet
                    isPresented = false
                }) {
                    Text("Save")
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.purple)
                        .cornerRadius(8)
                }
            }
        }
        .padding(30)
        .background(Color.black.opacity(0.6))
        .cornerRadius(20)
        .onDisappear {
            // When this view disappears, check if we should dismiss parent
            if shouldDismissParent {
                // Use a small delay to ensure smooth transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    parentPresented = false
                }
            }
        }
    }
    
    private func saveReflection() {
        viewModel.addMoodEntry(for: habit, mood: mood, reflection: reflectionText)
    }
}

// Achievements popup
struct AchievementsPopup: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            
            Text("Achievements")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { i in
                        AchievementRow(
                            title: "Achievement \(i)",
                            description: "Complete \(i*5) habits",
                            isUnlocked: i <= 3
                        )
                    }
                }
            }
        }
        .padding(30)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
    }
}

// Single achievement row
struct AchievementRow: View {
    let title: String
    let description: String
    let isUnlocked: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isUnlocked ? "trophy.fill" : "lock.fill")
                .font(.title2)
                .foregroundColor(isUnlocked ? .yellow : .gray)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

// Create habit popup
struct CreateHabitPopup: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @Binding var isPresented: Bool
    @State private var title = ""
    @State private var description = ""
    @State private var reminderTime = Date()
    @State private var frequency: HabitFrequency = .daily
    @State private var customDays: [Int] = []
    @State private var selectedEmoji: String = "📝"
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("New Habit")
                    .font(.system(size: 24, weight: .bold))
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
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Icon")
                    .foregroundColor(.white)
                
                TextField("📝", text: $selectedEmoji)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .onChange(of: selectedEmoji) { newValue in
                        if newValue.count > 1 {
                            selectedEmoji = String(newValue.prefix(1))
                        }
                    }
                
                Text("Title")
                    .foregroundColor(.white)
                
                TextField("", text: $title)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                
                Text("Description (Optional)")
                    .foregroundColor(.white)
                
                TextField("", text: $description)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                
                Text("Frequency")
                    .foregroundColor(.white)
                
                Picker("Frequency", selection: $frequency) {
                    ForEach([HabitFrequency.daily, .weekly, .monthly, .custom], id: \.self) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if frequency == .custom {
                    CustomDaysSelector(customDays: $customDays)
                }
                
                Text("Reminder")
                    .foregroundColor(.white)
                
                DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .foregroundColor(.white)
            }
            
            Button(action: {
                addHabit()
                isPresented = false
            }) {
                Text("Create Habit")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(10)
            }
            .disabled(title.isEmpty)
        }
        .padding(30)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
    }
    
    private func addHabit() {
        viewModel.addHabit(
            title: title,
            description: description,
            reminderTime: reminderTime,
            frequency: frequency,
            customDays: customDays,
            emoji: selectedEmoji.isEmpty ? "📝" : selectedEmoji
        )
    }
}

// Edit habit popup
struct EditHabitPopup: View {
    let habit: Habit
    @ObservedObject var viewModel: HabitTrackerViewModel
    @Binding var isPresented: Bool
    @State private var title: String
    @State private var description: String
    @State private var frequency: HabitFrequency
    @State private var reminderTime: Date
    @State private var customDays: [Int]
    @State private var selectedEmoji: String
    
    init(habit: Habit, viewModel: HabitTrackerViewModel, isPresented: Binding<Bool>) {
        self.habit = habit
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._title = State(initialValue: habit.title)
        self._description = State(initialValue: habit.description)
        self._frequency = State(initialValue: habit.frequency)
        self._reminderTime = State(initialValue: habit.reminderTime)
        self._customDays = State(initialValue: habit.customDays)
        self._selectedEmoji = State(initialValue: habit.emoji)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Edit Habit")
                    .font(.system(size: 24, weight: .bold))
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
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Icon")
                    .foregroundColor(.white)
                
                TextField("📝", text: $selectedEmoji)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .onChange(of: selectedEmoji) { newValue in
                        if newValue.count > 1 {
                            selectedEmoji = String(newValue.prefix(1))
                        }
                    }
                
                Text("Title")
                    .foregroundColor(.white)
                
                TextField("", text: $title)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                
                Text("Description")
                    .foregroundColor(.white)
                
                TextField("", text: $description)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                
                Text("Frequency")
                    .foregroundColor(.white)
                
                Picker("Frequency", selection: $frequency) {
                    ForEach([HabitFrequency.daily, .weekly, .monthly, .custom], id: \.self) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if frequency == .custom {
                    CustomDaysSelector(customDays: $customDays)
                }
                
                Text("Reminder")
                    .foregroundColor(.white)
                
                DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .foregroundColor(.white)
            }
            
            HStack {
                Button(action: {
                    deleteHabit()
                    isPresented = false
                }) {
                    Text("Delete")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                
                Spacer()
                
                Button(action: {
                    updateHabit()
                    isPresented = false
                }) {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(10)
                }
            }
        }
        .padding(30)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
    }
    
    private func updateHabit() {
        if let index = viewModel.habits.firstIndex(where: { $0.id == habit.id }) {
            viewModel.habits[index].title = title
            viewModel.habits[index].description = description
            viewModel.habits[index].frequency = frequency
            viewModel.habits[index].reminderTime = reminderTime
            viewModel.habits[index].customDays = customDays
            viewModel.habits[index].emoji = selectedEmoji.isEmpty ? "📝" : selectedEmoji
        }
    }
    
    private func deleteHabit() {
        if let index = viewModel.habits.firstIndex(where: { $0.id == habit.id }) {
            viewModel.habits.remove(at: index)
        }
    }
}

// Habit calendar view
struct HabitCalendarView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @State private var selectedMonth: Date = Date()
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "6a3093"), Color(hex: "a044ff")]),
                          startPoint: .top,
                          endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Month selector
                MonthSelector(selectedMonth: $selectedMonth)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(viewModel.habits) { habit in
                            HabitProgressCard(
                                habit: habit,
                                selectedMonth: selectedMonth,
                                viewModel: HabitViewModel(from: viewModel)
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Habit Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Background blur view
struct BackgroundBlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// Preference key for reordering
struct ReorderPreferenceKey: PreferenceKey {
    static var defaultValue: [ReorderInfo] = []
    
    static func reduce(value: inout [ReorderInfo], nextValue: () -> [ReorderInfo]) {
        value.append(contentsOf: nextValue())
    }
}

struct ReorderInfo: Identifiable, Equatable {
    let id: UUID
    let rect: CGRect
    
    static func == (lhs: ReorderInfo, rhs: ReorderInfo) -> Bool {
        lhs.id == rhs.id && lhs.rect == rhs.rect
    }
}

// MARK: - Health Info Module (Dark Placeholder)
struct HealthInfoView: View {
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "2b5876"), Color(hex: "4e4376")]),
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 10) {
                Text("Health Info")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                // Placeholder for HealthKit integration
                Text("Steps: 0").foregroundColor(.white)
                Text("Sleep: 0h").foregroundColor(.white)
                Text("Heart Rate: 0 bpm").foregroundColor(.white)
            }
        }
        .navigationTitle("Health Info")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Nutrition Module (Dark Placeholder)
struct NutritionView: View {
    @State private var showAlert = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "1a1a2e"), Color(hex: "2a6041")]),
                          startPoint: .top,
                          endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Text("Nutrition")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                
                Button(action: {
                    showAlert = true
                }) {
                    Text("Log Meal")
                        .font(.headline)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Meal Logged"),
                          message: Text("Meal analyzed: 500 calories, macros: ..."),
                          dismissButton: .default(Text("OK")))
                }
            }
        }
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.inline)
    }
}

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

// MARK: - Daily Check-In (Dark UI + AI Insights)
struct DailyCheckInView: View {
    @State private var checkInText: String = ""
    @State private var aiResponse: String = ""
    @State private var isSubmitting = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "3c1053"), Color(hex: "ad5389")]),
                          startPoint: .top,
                          endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Text("Daily Check-In")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                
                TextField("How are you feeling today?", text: $checkInText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .foregroundColor(.white)
                
                Button(action: submitCheckIn) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Submit Check-In")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                if !aiResponse.isEmpty {
                    Text("Your Daily Insights:")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top)
                    Text(aiResponse)
                        .foregroundColor(.white)
                        .padding()
                }
                
                Spacer()
            }
        }
        .navigationTitle("Daily Check-In")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func submitCheckIn() {
        guard !checkInText.isEmpty else { return }
        isSubmitting = true
        // Simulate AI call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            aiResponse = "Based on your input, consider maintaining your exercise routine and focusing on hydration for better mood stability."
            isSubmitting = false
        }
    }
}

// MARK: - Gamification Module (Dark)
struct GamificationView: View {
    @State private var dailyStreak: Int = 5 // Placeholder
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "654ea3"), Color(hex: "eaafc8")]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 20) {
                    Text("Gamification")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding()
                    
                    Text("Daily Streak: \(dailyStreak) days")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Gamification")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// Add Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


struct MoreView: View {
    var body: some View {
        ZStack {
            // Full-screen gradient
            LinearGradient(gradient: Gradient(colors: [Color(hex: "654ea3"), Color(hex: "eaafc8")]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        NavigationLink(destination: DailyCheckInView()) {
                            Text("Check-In")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
 
                        NavigationLink(destination: GamificationView()) {
                            Text("Rewards")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                .background(Color.clear) // Removes default ScrollView background
                .navigationTitle("More")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar) // Force NavigationView to be transparent
            }
            .background(Color.clear) // Ensures NavigationView does not add white background
        }
    }
}

// Add missing CustomDaysSelector component
struct CustomDaysSelector: View {
    @Binding var customDays: Array<Int>
    
    // Extract day names into a computed property
    private var dayNames: Array<String> {
        return ["M", "T", "W", "T", "F", "S", "S"]
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // Extract header into a separate view
            daySelectionHeader
            
            // Extract day buttons into a separate view
            daySelectionButtons
        }
    }
    
    // Header view
    private var daySelectionHeader: some View {
        Text("Select Days")
            .font(.caption)
            .foregroundColor(.white)
    }
    
    // Day buttons view
    private var daySelectionButtons: some View {
        HStack {
            ForEach(1...7, id: \.self) { day in
                dayButton(for: day)
            }
        }
    }
    
    // Individual day button
    private func dayButton(for day: Int) -> some View {
        let dayName = dayNames[day-1]
        let isSelected = customDays.contains(day)
        
        return Button(action: {
            toggleDay(day)
        }) {
            Text(dayName)
                .frame(width: 30, height: 30)
                .background(isSelected ? Color.purple : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .clipShape(Circle())
        }
    }
    
    // Toggle day selection
    private func toggleDay(_ day: Int) {
        if customDays.contains(day) {
            customDays.removeAll { $0 == day }
        } else {
            customDays.append(day)
        }
    }
}

// Add missing MonthSelector component
struct MonthSelector: View {
    @Binding var selectedMonth: Date
    
    var body: some View {
        HStack {
            previousMonthButton
            
            Spacer()
            
            monthYearText
            
            Spacer()
            
            nextMonthButton
        }
        .padding()
    }
    
    // Previous month button
    private var previousMonthButton: some View {
        Button(action: {
            changeMonth(by: -1)
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.white)
        }
    }
    
    // Month and year text
    private var monthYearText: some View {
        Text(monthYearFormatter.string(from: selectedMonth))
            .font(.headline)
            .foregroundColor(.white)
    }
    
    // Next month button
    private var nextMonthButton: some View {
        Button(action: {
            changeMonth(by: 1)
        }) {
            Image(systemName: "chevron.right")
                .foregroundColor(.white)
        }
    }
    
    // Helper method to change month
    private func changeMonth(by value: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}

// Add missing HabitProgressCard component
struct HabitProgressCard: View {
    let habit: Habit
    let selectedMonth: Date
    @ObservedObject var viewModel: HabitViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            cardHeader
            
            if !habit.description.isEmpty {
                descriptionText
            }
            
            // Use the HabitGridView instead
            HabitGridView(
                viewModel: viewModel,
                habit: habit,
                month: selectedMonth
            )
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // Card header with title and frequency badge
    private var cardHeader: some View {
        HStack {
            Text(habit.title)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            frequencyBadge
        }
    }
    
    // Description text
    private var descriptionText: some View {
        Text(habit.description)
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
    }
    
    // Frequency badge
    private var frequencyBadge: some View {
        Text(habit.frequency.rawValue)
            .font(.caption)
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.purple.opacity(0.3))
            .cornerRadius(8)
    }
}
