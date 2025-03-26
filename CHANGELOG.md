# CHANGELOG.md — Louie App

All notable changes to this project will be documented in this file.

---

## [0.1.0] – 2025-03-24
### Added
- Full README with dev workflow, tech stack, and project vision
- CONTEXT.md with detailed breakdown of app features, architecture, and AI prompt standards
- Habit Tracker base UI implemented
- Git repository cleaned up and pushed to GitHub

### Fixed
- Removed nested Git repo causing submodule warnings
- Reconnected `Louie/` directory as part of root project

---

(Next version: calendar view, achievements popup, and insights integration)

• Updated splash screen in ContentView.swift to use new mascot image ("SplashImage") with dark background.
• Implemented fade transition from splash to main tab view.
• Updated HabitCardView to use swipe gestures for habit tracking instead of checkmark button.
• Moved streak counter next to habit title for improved visibility.
• Redesigned weekly progress indicators to be larger and more prominent.
• Added swipe right (green) for completing habits and swipe left (red) for marking as not completed.
• Disabled habit completion editing in monthly calendar view while preserving visual indicators.
• Removed mood emoji display from habit cards while maintaining underlying data structures.
• Improved drag-to-reorder experience with more responsive animations and visual feedback.
• Removed reminder time input fields from habit creation and editing screens.

## Unreleased

### Added
- Added HabitStatsView to display detailed statistics for each habit
  - Shows total completions, best streaks, and mood tags frequency
  - Includes a rectangular monthly completion chart spanning the width of two cards
  - Enhanced bar chart with gradient fills and improved spacing
  - Available by tapping on habit cards in the calendar view
  - Provides visual insights through bar charts and stat cards
- Added inline mood entry view when completing habits
  - Allows users to record how they felt after completing a habit
  - Includes emotional state selection and optional notes field
  - Automatically saves data as users type

### Fixed
- Fixed mood entry view to always appear when completing a habit, regardless of previous completion status
- Added keyboard dismissal functionality for the notes field in the mood entry view
- Resolved ambiguity errors with duplicate class declarations in the project
- Fixed file naming consistency throughout the project structure

### Changed
- Modernized navigation system using NavigationStack for iOS 16+ and NavigationView with StackNavigationViewStyle for older versions
- Fixed navigation issues to ensure proper transition between views
- Added transition animations for smoother user experience
- Implemented proper access control for view components
- Cleaned up project structure by flattening directory hierarchy
- Fixed duplicate folder issues for improved stability
- Modularized the codebase by splitting ContentView.swift into separate files
- Created Models folder for Habit, HabitViewModel, and Workout
- Created Views folder with dedicated subfolders for Habit, Health, Nutrition, Workouts, DailyCheckIn, and Gamification
- Created Utilities folder for helper components like Color+Hex, ReorderHelpers, and BackgroundBlurView
- Enhanced HabitCardView design:
  - Enlarged habit emoji (42pt) and container (65x65) for better visibility
  - Increased size of daily tracker circles (24pt) with subtle white outlines
  - Improved spacing and layout to utilize the full width of the card
  - Added visual refinements to day indicators and progress markers

## [0.1.1] - 2025-03-26
### Fixed
- Resolved ambiguous type errors with CompletionStatus by creating a centralized type file
- Fixed multiple declarations of CompletionStatus enum across files
- Simplified architecture by using a standard project file instead of a Swift Package
- Fixed HabitViewModel initialization in HabitCalendarView
- Added missing updateHabitCompletion method to HabitViewModel
- Added calculateStreak(for:) method overload to support UUID parameter

## [0.2.0] - 2025-03-27
### Added
- Integrated CloudKit for data sync across devices
  - Implemented full CRUD operations for habits, completions, and mood logs
  - Added CloudKitManager with proper error handling and optimization
  - Ensures unique records with UUID-based identifiers
- Two-way sync between local storage and CloudKit
  - Automatically syncs data at app launch
  - Real-time sync when habits are added, updated, or deleted
  - Handles merge conflicts with smart precedence rules
- Added iCloud account status checking
- Added CloudKit schema migration utilities
- Enhanced error handling with user-friendly messages
- Optimized queries with sorting and filters