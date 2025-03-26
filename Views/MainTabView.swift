import SwiftUI

struct MainTabView: View {
    
    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor.white.withAlphaComponent(0.6)
        UITabBar.appearance().tintColor = UIColor.white
    }
    
    var body: some View {
        TabView {
            if #available(iOS 16.0, *) {
                NavigationStack { HabitTrackerView() }
                    .tabItem {
                        Label("Habits", systemImage: "list.bullet.rectangle")
                    }

                NavigationStack { HealthInfoView() }
                    .tabItem {
                        Label("Health", systemImage: "heart.fill")
                    }

                NavigationStack { NutritionView() }
                    .tabItem {
                        Label("Nutrition", systemImage: "leaf.fill")
                    }

                NavigationStack { WorkoutsView() }
                    .tabItem {
                        Label("Workouts", systemImage: "flame.fill")
                    }

                NavigationStack { DailyCheckInView() }
                    .tabItem {
                        Label("Check-In", systemImage: "bubble.left.and.bubble.right")
                    }

                NavigationStack {
                    GamificationView()
                }
                    .tabItem {
                        Label("Rewards", systemImage: "star.fill")
                    }
            } else {
                NavigationView { HabitTrackerView() }
                    .tabItem {
                        Label("Habits", systemImage: "list.bullet.rectangle")
                    }
                    .navigationViewStyle(StackNavigationViewStyle())

                NavigationView { HealthInfoView() }
                    .tabItem {
                        Label("Health", systemImage: "heart.fill")
                    }
                    .navigationViewStyle(StackNavigationViewStyle())

                NavigationView { NutritionView() }
                    .tabItem {
                        Label("Nutrition", systemImage: "leaf.fill")
                    }
                    .navigationViewStyle(StackNavigationViewStyle())

                NavigationView { WorkoutsView() }
                    .tabItem {
                        Label("Workouts", systemImage: "flame.fill")
                    }
                    .navigationViewStyle(StackNavigationViewStyle())

                NavigationView { DailyCheckInView() }
                    .tabItem {
                        Label("Check-In", systemImage: "bubble.left.and.bubble.right")
                    }
                    .navigationViewStyle(StackNavigationViewStyle())

                NavigationView {
                    GamificationView()
                }
                    .tabItem {
                        Label("Rewards", systemImage: "star.fill")
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
            }
        }
        .accentColor(.white)
    }
} 