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

## [0.2.1] - 2025-03-28
### Fixed
- Fixed CloudKit record type issues with MoodLog
  - Added automatic schema creation when record types don't exist
  - Implemented sample record creation to establish schemas
  - Added proper error handling with automatic retry after schema creation
- Enhanced CloudKit error logging
  - Added consistent [CloudKitError] prefix for all error logs
  - Implemented specific error handling for common CloudKit errors
  - Added detailed logging for troubleshooting
- Added initialization protection
  - Schema initialization on app startup
  - Automatic cleanup of sample schema records
  - Added forced schema initialization method

### Added
- Enhanced time tracking for habit completions
  - Now tracking exact time of day for habit completions
  - Improved date range queries to find completions by day
  - Added better logging for completion timestamps
  - Updated UI to display time information when available
- Improved schema migration
  - Added force schema initialization method
  - Better handling of schema-related errors
  - Automatic retry mechanism for CloudKit operations

## [0.2.2] - 2025-03-29
### Fixed
- Fixed CloudKit query issues with recordName field
  - Migrated all queries to use the custom `id` field instead of `recordName`
  - Fixed "Field recordName is not marked queryable" errors in CloudKit Dashboard
  - Updated all NSPredicate queries to use the proper queryable fields
  - Improved database schema to better match CloudKit Dashboard requirements
- Enhanced CloudKit reliability
  - Fixed issues with records not appearing in CloudKit Dashboard
  - Improved error handling for schema-related errors
  - Added more detailed logging for CloudKit operations

## [0.2.3] - 2025-03-30
### Fixed
- Fixed CloudKit query reliability issues
  - Added dedicated helper methods for fetching records by custom ID
  - Ensured consistent usage of custom ID fields across all query operations
  - Replaced any implicit recordName references with explicit ID field references
  - Enhanced error handling for non-queryable field errors
- Enhanced CloudKit dashboard compatibility
  - Added record type validation in debug utilities
  - Added custom ID field verification in database debug tools
  - Ensured all sort descriptors use queryable fields

## [0.2.4] - 2025-03-31
### Fixed
- Completed CloudKit recordName to customID migration
  - Added schema verification to ensure custom ID fields are queryable
  - Fixed all schema creation and test record handling to use custom IDs consistently
  - Added built-in verification checks during schema creation
  - Created consistent test UUIDs for schema initialization to improve reliability
- Enhanced CloudKit error resilience
  - Improved detection of non-queryable field errors
  - Added safeguards to prevent recordName-based queries
  - Added self-verification of correct query patterns

## [0.2.5] - 2025-04-01
### Fixed
- Implemented CloudKit safe update pattern for mood logs
  - Added fetch-before-update logic to prevent optimistic locking conflicts
  - Fixed "client oplock error updating record" issues when multiple devices update the same record
  - Ensures app always operates on the most recent version of CloudKit records
  - Maintains backwards compatibility with existing CloudKit data
- Enhanced CloudKit reliability
  - Improved logging for CloudKit update operations
  - Added clearer distinction between new record creation and record updates
  - Preserved original record creation functionality to maintain performance