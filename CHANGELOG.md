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