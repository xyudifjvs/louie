import SwiftUI

// Make struct public to ensure it's accessible everywhere
public struct HabitStatsView: View {
    let habit: Habit
    @ObservedObject var viewModel: HabitTrackerViewModel
    
    // Grid layout for stat cards
    private var columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    init(habit: Habit, viewModel: HabitTrackerViewModel) {
        self.habit = habit
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "121212"), Color(hex: "1e1e1e")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Habit header
                    habitHeader
                    
                    // Stats grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        // Total Completions Card
                        StatCard(title: "Total Completions") {
                            totalCompletionsView
                        }
                        
                        // Best Streak Card
                        StatCard(title: "Best Streak") {
                            bestStreakView
                        }
                        
                        // Days Tracked Card
                        StatCard(title: "Days Tracked") {
                            daysTrackedView
                        }
                        
                        // Mood Frequency Card
                        StatCard(title: "Mood Frequency") {
                            moodFrequencyView
                        }
                    }
                    .padding(.horizontal)
                    
                    // Completions per Month Card (now outside the grid)
                    StatCard(title: "Completions per Month", isWide: true) {
                        completionsPerMonthView
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
        }
    }
    
    // Header with habit info
    private var habitHeader: some View {
        HStack(spacing: 16) {
            Text(habit.emoji)
                .font(.system(size: 50))
                .frame(width: 80, height: 80)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if !habit.description.isEmpty {
                    Text(habit.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Text(habit.frequency.rawValue)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.3))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // Total completions view
    private var totalCompletionsView: some View {
        VStack {
            Text("\(getTotalCompletions())")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
            Text("times completed")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // Best streak view
    private var bestStreakView: some View {
        VStack {
            Text("\(getBestStreak())")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
            Text("day streak")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // Days tracked view
    private var daysTrackedView: some View {
        VStack {
            Text("\(getDaysTracked())")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
            Text("days tracked")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // Mood frequency view
    private var moodFrequencyView: some View {
        VStack {
            let moodData = getMoodFrequency()
            
            if moodData.isEmpty {
                Text("No mood data")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(moodData, id: \.mood) { item in
                        VStack {
                            Text("\(item.count)")
                                .font(.caption2)
                                .foregroundColor(.white)
                            
                            Rectangle()
                                .fill(getMoodColor(item.mood))
                                .frame(width: 20, height: CGFloat(item.count) * 8)
                                .cornerRadius(4)
                            
                            Text(item.mood.rawValue)
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
    }
    
    // Completions per month view
    private var completionsPerMonthView: some View {
        VStack(alignment: .leading, spacing: 8) {
            let monthlyData = getCompletionsPerMonth()
            
            if monthlyData.isEmpty {
                Text("No completion data")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                // Chart labels
                HStack {
                    Text("Monthly completion trends")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text("Completed")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.top, 4)
                
                // Chart
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(monthlyData, id: \.month) { item in
                        VStack(spacing: 4) {
                            Text("\(item.count)")
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Rectangle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.green.opacity(0.7), Color.green]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .frame(width: 28, height: max(CGFloat(item.count) * 6, 5))
                                .cornerRadius(4)
                            
                            Text(item.month)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 10)
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Data Helper Methods
    
    // Get total number of completions for this habit
    private func getTotalCompletions() -> Int {
        var count = 0
        if let habitCompletions = viewModel.completions[habit.id] {
            for (_, status) in habitCompletions {
                if status == .completed {
                    count += 1
                }
            }
        }
        return count
    }
    
    // Get best streak for this habit
    private func getBestStreak() -> Int {
        return viewModel.calculateStreak(for: habit.id)
    }
    
    // Get total days tracked for this habit (completed + not completed)
    private func getDaysTracked() -> Int {
        if let habitCompletions = viewModel.completions[habit.id] {
            return habitCompletions.count
        }
        return 0
    }
    
    // Get mood frequency data
    private func getMoodFrequency() -> [MoodFrequencyItem] {
        var moodCounts: [Mood: Int] = [:]
        
        for entry in habit.moodEntries.values {
            moodCounts[entry.mood, default: 0] += 1
        }
        
        return moodCounts.map { MoodFrequencyItem(mood: $0.key, count: $0.value) }
            .sorted { $0.mood.rawValue < $1.mood.rawValue }
    }
    
    // Get monthly completion data
    private func getCompletionsPerMonth() -> [MonthlyCompletions] {
        var monthlyCounts: [String: Int] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        
        let calendar = Calendar.current
        
        if let habitCompletions = viewModel.completions[habit.id] {
            for (date, status) in habitCompletions {
                if status == .completed {
                    let month = dateFormatter.string(from: date)
                    monthlyCounts[month, default: 0] += 1
                }
            }
        }
        
        // Get the last 6 months or fewer if not enough data
        let sortedMonths = getLastSixMonths()
        
        return sortedMonths.map { month in
            MonthlyCompletions(month: month, count: monthlyCounts[month] ?? 0)
        }
    }
    
    // Helper to get the last 6 months as strings
    private func getLastSixMonths() -> [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        
        let calendar = Calendar.current
        let currentDate = Date()
        
        var months: [String] = []
        
        for i in 0..<6 {
            if let date = calendar.date(byAdding: .month, value: -i, to: currentDate) {
                months.append(dateFormatter.string(from: date))
            }
        }
        
        return months.reversed()
    }
    
    // Helper to get color for mood
    private func getMoodColor(_ mood: Mood) -> Color {
        switch mood {
        case .happy: return .green
        case .neutral: return .yellow
        case .sad: return .blue
        case .angry: return .red
        }
    }
}

// MARK: - Helper Structs

// Struct for mood frequency data
public struct MoodFrequencyItem {
    let mood: Mood
    let count: Int
}

// Struct for monthly completions data
public struct MonthlyCompletions {
    let month: String
    let count: Int
}

// MARK: - Stat Card Component

public struct StatCard<Content: View>: View {
    let title: String
    let isWide: Bool
    let content: Content
    
    public init(title: String, isWide: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isWide = isWide
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            HStack {
                Spacer()
                content
                Spacer()
            }
            
            Spacer()
        }
        .padding()
        .frame(height: 180)
        .frame(maxWidth: isWide ? .infinity : nil)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
} 