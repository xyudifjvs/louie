# Louie

**Project Type:** iOS Wellness App (SwiftUI + CloudKit + AI Integration)

## Overview
**Louie** is a data-driven self-improvement app designed to help users optimize their habits, health, nutrition, workouts, and mood. Built for iPhone using SwiftUI and CloudKit, Louie leverages AI-generated insights to guide users in making more informed lifestyle decisions. The app combines structured habit tracking, HealthKit integration, nutrition logging, mood tagging, and conversational check-ins to build a personalized wellness journey.

The tone is casual and friendly, inspired by a helpful dog companion — with premium functionality expected by high-achieving users.

---

## Key Features

### 1. Habit Tracking
- Users can create custom habits with emoji icons, frequency, reminders, and difficulty.
- Daily and dynamic 7-day habit views.
- Reordering via drag-and-drop.
- Visual streak counter with flame icon.
- Mood tagging popup after habit completion, with optional text reflection.

### 2. Daily Check-Ins
- Structured conversational format that gathers data for AI.
- AI-generated insights created once daily, summarizing patterns and offering suggestions.
- Long-form insight generation with cited data points.

### 3. Nutrition
The nutrition section allows users to log and analyze their meals using AI:

- Take photos of meals with the built-in camera
- AI analyzes the image to identify foods and their nutritional content
- Calculates a "Nutrition Score" based on:
  - Macronutrient balance (33%)
  - Micronutrient diversity (25%)
  - Portion size appropriateness (20%)
  - Processing level of foods (12%)
  - Color variety (10%)
- Displays a dashboard of meal history with detailed nutritional information
- All meal data is stored in CloudKit for seamless syncing across devices

### 4. Health Data
- HealthKit integration with toggleable metric syncing (e.g., steps, HRV, sleep, etc.).
- Daily snapshot analysis stored for trend correlation.

### 5. Workout Logging
- One log section for all workouts.
- Progress auto-fill from previous entries.
- Overtraining detection and AI-generated adjustment tips.

### 6. Insights Engine
- Server-based API (e.g., Claude/Perplexity Pro) generates insights once/day.
- Runs automatically if the user does not request insights.
- Long-form explanations only. No quick takes.
- Insights shown only in Check-In section (not habits, workouts, etc.).
- Confidence indicator + thumbs-up/down rating.

### 7. Gamification
- Flame streak counter
- Grace period: 24hr leniency, 3x/year
- Achievement popup (blurred background modal)
- No social leaderboards or in-app reward store (yet)

---

## Technical Stack

| Layer              | Tech Used                    |
|-------------------|------------------------------|
| Language           | Swift, SwiftUI               |
| Architecture       | MVVM                         |
| Local Storage      | UserDefaults (placeholder)   |
| Cloud Sync         | CloudKit                     |
| AI Integration     | Server-based API (TBD)       |
| Health Data        | HealthKit                    |
| Notifications      | UserNotifications            |
| Design             | Dark UI + Gradient Styles    |


---

## Goals
- Build a fully functioning MVP using Cursor + Claude.
- Stay beginner-friendly: simple design, clean structure.
- Get to a testable build with real data-driven insights.

## Future Considerations
- macOS/iPad support
- In-app subscriptions
- Meditation/audio integration
- Richer achievements/gamification
- App Store launch with TestFlight beta

---

## Instructions for Cursor
I'm a beginner developer building "Louie" using Cursor with Claude integration. Please assist with:

### 📌 Project Context:
- Codebase uses SwiftUI and MVVM
- App is a structured wellness tracker powered by AI insights
- Habit Tracker is the primary module in focus right now
- App architecture uses CloudKit, HealthKit, and server-based API (TBD)
- Insights are generated only from Daily Check-Ins (never from Habits/Workouts directly)

### ✅ Expectations from Cursor:
1. Apply the absolute best SwiftUI code you can. Think very hard and critique your own strategies mulitple times before applying changes especially for complex views and reusable components.
2. Structure code to align with MVVM. Separate logic from views.
3. Use modern Swift best practices (i.e., Combine where applicable).
4. Follow the visual design spec: dark gradients, rounded corners, soft shadows, flame for streaks.
5. Include real-time loading animations, where appropriate.
6. For each view or feature added, update any related model, viewModel, and backend storage logic.
7. Use CloudKit for all data persistence unless told otherwise.
8. Add comments to explain any advanced logic or uncommon Swift syntax.
9. Always ask clarifying questions when something seems ambiguous.

### ⚠️ Don't:
- Generate placeholder UI without context (always read the README + prompt)
- Suggest surface-level insights in the AI engine
- Hardcode mock data unless explicitly testing

---

## Notes for Other Tools (Claude, GitHub, etc.)
- Claude should refer to this README before any major refactor or feature addition.
- All logic should be added modularly and with future scalability in mind.
- GitHub versioning will be set up soon to track progress milestones.

---

_Last updated: March 24, 2025_

