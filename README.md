### Context Prompt for "Louie" App Development in Cursor

**App Overview:**  
"Louie" is a holistic wellness iOS app designed to empower users to enhance their mental and physical health by tracking and correlating daily data points related to habits, health metrics, nutrition, workouts, and mood. The app targets individuals who want to optimize their habits and well-being, including those struggling with depression or anxiety due to poor lifestyle choices. By leveraging AI-driven insights, "Louie" provides actionable recommendations to foster positive behavior change and improve overall quality of life.

**Core Features & Modules:**  
The app is organized into six interconnected modules, each contributing to a seamless, user-centric experience:  
1. **Habit Tracker:**  
   - Users can create custom habits (e.g., "Drink water," "Meditate") and log daily completions with a simple yes/no input.  
   - Monthly progress is shown in a grid format—green for completed days, red for missed days, and gray for no data.  
   - Includes customizable reminder notifications.  
2. **Health Info:**  
   - Integrates with HealthKit to pull metrics like sleep duration, sleep quality, steps, heart rate, HRV, weight, and body composition.  
   - Displays data on a customizable dashboard.  
3. **Nutrition:**  
   - Users log meals by taking photos, analyzed via an AI API (e.g., Perplexity Pro, Google Cloud Vision) for nutritional breakdown (calories, macros, micronutrients).  
   - Optionally tracks water intake.  
4. **Workouts:**  
   - Users log workout details (exercise type, weight, reps, sets, duration).  
   - Visualizes progress through charts (e.g., strength gains).  
5. **Daily Check-In:**  
   - Users record mood (numeric scale or emoticons) and self-reported metrics (energy, stress).  
   - AI generates personalized insights linking habits, health data, and mood.  
   - Features an interactive, conversational interface.  
6. **Gamification:**  
   - Includes daily streaks, badges (e.g., “10-Day Habit Master”), and rewards.  
   - Expandable with challenges or leaderboards.

**Design & UI Guidelines:**  
- **Theme:** Dark-themed, premium design with sleek elements like dark backgrounds, gradient cards (deep blue to black), and glowing toggles (neon green for active states).  
- **Navigation:** A bottom TabView provides access to all six modules with clear icons and labels.  
- **Consistency:** Uniform typography (SF Pro), color schemes, and layouts across modules.  
- **Splash Screen:** Hero-style with a subtle animation (e.g., pulsing logo).  
- **Accessibility:** Supports VoiceOver, dynamic text sizing, high-contrast options.

**Data Points to Collect:**  
- Habit Tracker: Completion status (yes/no), timestamps, frequency, reminder settings.  
- Health Info: Sleep duration/quality, steps, active minutes, heart rate, HRV, weight, body composition.  
- Nutrition: Meal timestamps, images, nutritional breakdown, water intake.  
- Workouts: Exercise type, weight, reps, sets, duration, trends.  
- Daily Check-In: Mood ratings, energy/stress levels, journal entries.  
- Additional: Productivity, environmental factors, social interactions, screen time.

**Desired Workflow:**  
1. Morning Check-In: Log mood, energy, reflections.  
2. Throughout Day: Log habits, meals, workouts, water with reminders.  
3. Evening Review: AI insights (e.g., “Mood improved with 3+ habits”).  
4. Weekly/Monthly Summaries: Trends and suggestions.  
5. Personalization: Tailored recommendations as usage increases.

**Project Roadmap Overview:**  
1. Ideation & Concept Validation: Market research, MVP prioritization (Habit Tracker, Daily Check-In, Health Info).  
2. Product & Design: User flows, Figma mockups, prototyping, accessibility.  
3. Technical Development: SwiftUI, MVVM, HealthKit, CloudKit, AI APIs (Perplexity Pro), testing.  
4. Business Strategy & Monetization: Freemium model, in-app purchases.  
5. Legal & Compliance: Privacy policies, GDPR/HIPAA compliance.  
6. Marketing & Launch: ASO, beta testing, campaigns.  
7. Post-Launch & Scaling: Analytics, feedback loops, infrastructure scaling.

**Current Development Status:**  
- **Project Location:** `~/Documents/louie/Louie.xcodeproj`.  
- **Setup:** Xcode project created with SwiftUI, HealthKit (steps, heart rate, sleep, weight), and local notifications (reminders).  
- **Files:** Includes `LouieApp.swift`, `ContentView.swift` (TabView with placeholders), `HealthManager.swift`, `NotificationManager.swift`, `PerplexityManager.swift` (for Perplexity Pro API).  
- **AI Integration:** Perplexity Pro API integrated for insights (e.g., “What habits improve sleep quality?”).  
- **Testing:** Successfully builds in Cursor using SweetPad, tested on iPhone (post-iOS update).

**AI Analysis Focus:**  
- **Make-or-Break Feature:** High-quality AI analysis linking all data points.  
- **Approach:** Using Perplexity Pro ($5 credit, 300 searches/day) for initial insights; plan to transition to custom models (e.g., scikit-learn, TensorFlow) as data grows.  
- **Pre-existing Models:** Google Vision (nutrition), scikit-learn (correlations), IBM Watson (insights).

**Competitor Analysis:**  
- No direct competitor combines all features with AI insights. Indirect competitors: Streaks (habits), Fitbit (health), MyFitnessPal (nutrition), Daylio (mood).

**Instructions for Cursor:**  
I’m a rookie developer building "Louie" in Cursor with Claude integration. Please assist by:  
1. Providing step-by-step code examples in SwiftUI for each module, starting with the Habit Tracker.  
2. Suggesting design elements (e.g., gradient styles, layouts) adhering to the dark theme.  
3. Offering best practices for HealthKit, notifications, and AI API integration (Perplexity Pro).  
4. Helping with testing (unit, integration, UI) and scaling strategies.  
5. Asking clarifying questions to ensure alignment with my vision.  
Focus on actionable, beginner-friendly guidance, leveraging my current setup (`~/Documents/louie`) and Perplexity Pro API for AI insights.