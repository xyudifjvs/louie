CONTEXT.md — Louie App Project Blueprint

This file defines the master context for AI copilots (Cursor, Claude, or other LLMs) assisting in the development of the Louie iOS app. Any automated code suggestions, architecture changes, or UI implementations should align with the context defined here.

⸻

🐶 App Identity

Project Name: Louie
Type: iOS Wellness + Self-Improvement App
Tone: Friendly, dog-themed, casual but premium-quality
Mascot: Based on Carson’s late dog Louie — a golden doodle. Louie functions as a virtual companion and wellness coach.

Tagline-style Concept:

Louie is a coach in your pocket — a data-driven dog that helps you feel better, move better, and live better.

⸻

🧠 Mission and Vision

Louie’s mission is to help people optimize their lifestyle habits and routines by collecting daily inputs, analyzing behavioral trends, and offering personalized, AI-generated insights grounded in the user’s own data.

It is designed for:
	•	People trying to build better daily routines
	•	Users struggling with motivation, burnout, or mood
	•	Data-focused individuals who want personalized, actionable feedback
	•	Anyone looking for a fun, casual interface that still offers elite functionality

Louie is not a chat assistant. It is a coach with memory, insight, and feedback capabilities.

⸻

📦 Core Modules & Feature Design

1. Habit Tracker
	•	Users can create custom habits with:
	•	Emoji icon (entered manually via keyboard)
	•	Name
	•	Description
	•	Frequency (Daily, Weekly, or 2x/day)
	•	Difficulty (Easy, Medium, Hard)
	•	Reminder (optional, custom time/frequency)
	•	Toggle for “Show Streak”
	•	Habits appear as stackable cards with:
	•	Left side: Emoji
	•	Center: Name and 7-day rolling completion grid
	•	Right side: Tap checkmark to mark complete + show streak + flame emoji if active
	•	Reordering via drag-and-drop (wiggle mode)
	•	Monthly calendar screen accessible via calendar icon
	•	“Achievements” popup accessible via trophy icon (blurred background)

2. Daily Check-In (AI Conversation)
	•	This is the only section where insights are generated
	•	UI is a structured chat-style conversation
	•	Fields include:
	•	Mood (emoji scale)
	•	Energy and stress levels
	•	Sleep duration + quality
	•	Food and water intake
	•	Social interactions
	•	Optional journal entries or notes
	•	Users can skip questions
	•	Insights are generated once per day, either:
	•	On-demand after check-in
	•	Automatically in the background if no check-in occurs
	•	Insights are stored and referenced in future sessions
	•	Insights must include:
	•	Cited user data
	•	Deeper pattern recognition beyond surface-level facts
	•	Actionable recommendations (“Try X tomorrow…”)
	•	Thumbs up/down rating control

3. Nutrition
	•	Users log meals via:
	•	AI meal analysis (server-based image-to-text API or typed prompt)
	•	Manual override and editing allowed
	•	Must verify AI prediction before final save
	•	Detailed nutrient breakdown:
	•	Calories, macros, and micronutrients
	•	Water intake tracked
	•	Nutrition goals linked to habit tracker, not this section

4. Workouts
	•	Unified log section (strength + cardio combined)
	•	Users can input:
	•	Exercise type
	•	Sets/reps/weight or time/distance
	•	Notes
	•	Autofill from previous entries encouraged
	•	AI monitors for overtraining, inconsistent activity, or habit correlation

5. Health Info (HealthKit)
	•	Pulls all available metrics, including:
	•	Steps
	•	HR / HRV / BP
	•	Sleep
	•	Blood oxygen
	•	Active energy, etc.
	•	Daily snapshot (not live)
	•	User can toggle which metrics are imported
	•	Health data correlates with mood, habits, and workouts
	•	Users can annotate with a note (e.g., “Was sick today”)

6. Gamification
	•	Flame icon for habit streaks
	•	24-hour grace period allowed up to 3x/year
	•	No streak penalties otherwise (users can mark vacation days green manually)
	•	Pop-up modal achievement view
	•	No leaderboards or external sharing

⸻

🧠 AI Engine Overview
	•	All AI insights are generated via server-side API (e.g., Claude or Perplexity Pro)
	•	Analysis must be deep, personalized, and backed by data
	•	Surface-level insights (“You were tired after 5 hours of sleep”) are allowed but should never be the focus
	•	Only one insight per day is generated
	•	Insights are long-form and conversational, not bullets
	•	Insights include confidence levels and user ratings
	•	AI may suggest products (e.g., gym gear) for monetization
	•	Meditation recommendations are allowed, but Louie will not create custom meditations

⸻

⚙️ Architecture & Technical Constraints
	•	Language: Swift 5+
	•	Framework: SwiftUI
	•	Architecture: MVVM
	•	Storage: CloudKit (all user data is cloud-synced)
	•	Health Data: HealthKit
	•	AI: Server-based API (no local AI)
	•	Notifications: UserNotifications framework
	•	Animation: SwiftUI + Core Animation
	•	Charts: Swift Charts
	•	Auth: Apple Sign-In + Google Sign-In (future-ready)

⸻

🎨 Design & UX Principles
	•	Dark theme with soft gradients (e.g., black to navy blue)
	•	Rounded cards, glowing toggles
	•	Emoji-rich interface (but not childish)
	•	Pop-up modals use blurred backgrounds
	•	“Louie” appears visually during insight generation (e.g., loading/fetching animation)
	•	Friendly but informative copy — casual tone, not robotic

⸻

📌 Prompting Guidelines for Cursor/Claude

All future prompts should:
	1.	Include feature goal and user intent
	2.	Reference connected files or components (by name)
	3.	Embed data flow expectations (e.g., CloudKit save, HealthKit read)
	4.	Explain behavior edge cases (e.g., habit streak grace period)
	5.	End with guardrails (e.g., “Don’t hardcode mock data unless testing,” “Use MVVM,” etc.)

⸻

📅 Development Timeline (Current Focus)
	•	README.md ✅
	•	GitHub Versioning ✅
	•	CONTEXT.md ✅ (in progress)
	•	CHANGELOG.md (next)
	•	Habit Tracker: Calendar + Achievements popup
	•	Begin backend API planning for AI insights

⸻

Last updated: March 24, 2025
