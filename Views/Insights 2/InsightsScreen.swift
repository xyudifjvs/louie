//
//  InsightsScreen.swift
//  Louie
//
//  Created by Carson on 4/13/25.
//

import SwiftUI

// Redefined SpeechBubbleContainer to be a generic background shape
struct SpeechBubbleContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Main Bubble Shape
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )

            // Tail pointing towards bottom-left
            TriangleTail()
                .fill(Color.white.opacity(0.15)) // Match fill
                .frame(width: 40, height: 30) // Adjust size
                .offset(x: 50, y: 15) // Adjust offset for connection
                .zIndex(1) // Ensure tail overlaps bubble slightly if needed

            // Actual chat content placed on top
            content
                .padding(EdgeInsets(top: 20, leading: 20, bottom: 35, trailing: 20)) // Inner padding
        }
    }
}

// Redefined TriangleTail to point downwards and slightly left
struct TriangleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Start at top-left corner (relative to its frame)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        // Line to bottom-center (the point)
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        // Line to top-right corner
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        // Close path back to start
        path.closeSubpath()
        return path
    }
}

// MARK: - Data Structures

// Represents distinct steps in the conversation flow
enum ChatStepType: Hashable {
    case greeting
    case energyLevel
    case moodPrimary
    case moodSecondaryHappy
    case moodSecondaryNeutral
    case moodSecondarySad
    case moodSecondaryAngry
    case moodSecondaryAnxious
    case mentalClarity
    case physicalSymptoms
    case symptomSeverity(symptom: String) // Associated value to know which symptom
    case sleepHoursCheck
    case sleepHoursManual
    case sleepQualityRating
    case sleepQualityReason
    case stressLevel
    case stressCause
    case stressCoping
    case copingEffectiveness
    case final
}

// Represents the type of UI needed for user response
enum ResponseType {
    case none // For steps where Louie just talks
    case initialButton // The first "Ready!" button
    case slider(range: ClosedRange<Double>, step: Double)
    case emojiGrid(options: [EmojiOption])
    case tagGrid(options: [TagOption], allowsMultiple: Bool)
    case yesNo
    case textInput
    // case custom // Placeholder for potentially more complex inputs
}

// Data for an emoji option in a grid
struct EmojiOption: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    let label: String // e.g., "Happy", "Joyful"
    let value: String // Value to store (could be same as label or specific code)
}

// Data for a tag option in a grid
struct TagOption: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let value: String // Value to store
}

// Defines a single node in the conversation graph
struct ChatStep {
    let id: ChatStepType
    let louiePrompt: (Any?) -> String // Closure to potentially customize prompt based on prior data
    let responseType: ResponseType
    let dataKey: String? // Key for storing data in collectedCheckInData
    let nextStepLogic: (Any?) -> ChatStepType // Determines the next step based on current response
}

// Existing Message Struct
struct Message: Identifiable {
    let id = UUID()
    let text: String
    let fromLouie: Bool
}

// MARK: - Main View
struct InsightsScreen: View {
    // MARK: - Conversation Flow Definition
    static let conversationFlow: [ChatStepType: ChatStep] = [
        // 1. Greeting
        .greeting: ChatStep(
            id: .greeting,
            louiePrompt: { _ in "Hey there! Ready to check in?" },
            responseType: .initialButton,
            dataKey: nil,
            nextStepLogic: { _ in .energyLevel }
        ),
        
        // 2. Energy Level
        .energyLevel: ChatStep(
            id: .energyLevel,
            louiePrompt: { _ in "How energized did you feel today?" },
            responseType: .slider(range: 1...10, step: 1),
            dataKey: "energyLevel",
            nextStepLogic: { _ in .moodPrimary }
        ),
        
        // 3. Mood Primary
        .moodPrimary: ChatStep(
            id: .moodPrimary,
            louiePrompt: { _ in "How has your mood been today?" },
            responseType: .emojiGrid(options: [
                EmojiOption(emoji: "😊", label: "Happy", value: "happy"),
                EmojiOption(emoji: "😐", label: "Neutral", value: "neutral"),
                EmojiOption(emoji: "😢", label: "Sad", value: "sad"),
                EmojiOption(emoji: "😠", label: "Angry", value: "angry"),
                EmojiOption(emoji: "😟", label: "Anxious", value: "anxious"),
            ]),
            dataKey: "moodPrimary",
            nextStepLogic: { response in
                guard let selectedValue = response as? String else { return .mentalClarity } // Default fallback
                switch selectedValue {
                case "happy": return .moodSecondaryHappy
                case "neutral": return .moodSecondaryNeutral
                case "sad": return .moodSecondarySad
                case "angry": return .moodSecondaryAngry
                case "anxious": return .moodSecondaryAnxious
                default: return .mentalClarity
                }
            }
        ),
        
        // 4a. Mood Secondary - Happy
        .moodSecondaryHappy: ChatStep(
            id: .moodSecondaryHappy,
            louiePrompt: { _ in "Glad to hear it! Which of these describe it best?" },
            responseType: .emojiGrid(options: [
                EmojiOption(emoji: "🥳", label: "Joyful", value: "joyful"),
                EmojiOption(emoji: "🙏", label: "Grateful", value: "grateful"),
                EmojiOption(emoji: "🤩", label: "Excited", value: "excited"),
                EmojiOption(emoji: "🤝", label: "Connected", value: "connected"),
                EmojiOption(emoji: "😌", label: "Calm", value: "calm"),
            ]),
            dataKey: "moodSecondary",
            nextStepLogic: { _ in .mentalClarity }
        ),
        
        // 4b. Mood Secondary - Neutral
        .moodSecondaryNeutral: ChatStep(
            id: .moodSecondaryNeutral,
            louiePrompt: { _ in "Okay, neutral. Can you pinpoint why?" },
            responseType: .emojiGrid(options: [
                EmojiOption(emoji: "😴", label: "Tired", value: "tired"),
                EmojiOption(emoji: "🥱", label: "Bored", value: "bored"),
                EmojiOption(emoji: "📉", label: "Unmotivated", value: "unmotivated"),
                EmojiOption(emoji: "🤔", label: "Distracted", value: "distracted"),
                EmojiOption(emoji: "😶", label: "Numb", value: "numb"),
            ]),
            dataKey: "moodSecondary",
            nextStepLogic: { _ in .mentalClarity }
        ),
        
        // 4c. Mood Secondary - Sad
        .moodSecondarySad: ChatStep(
            id: .moodSecondarySad,
            louiePrompt: { _ in "I'm sorry to hear that. What felt most prominent?" },
            responseType: .emojiGrid(options: [
                EmojiOption(emoji: "🧍", label: "Lonely", value: "lonely"),
                EmojiOption(emoji: "😞", label: "Disappointed", value: "disappointed"),
                EmojiOption(emoji: "💔", label: "Hopeless", value: "hopeless"),
                EmojiOption(emoji: "🤕", label: "Hurt", value: "hurt"),
                EmojiOption(emoji: "🫣", label: "Insecure", value: "insecure"),
            ]),
            dataKey: "moodSecondary",
            nextStepLogic: { _ in .mentalClarity }
        ),
        
        // 4d. Mood Secondary - Angry
        .moodSecondaryAngry: ChatStep(
            id: .moodSecondaryAngry,
            louiePrompt: { _ in "Anger is valid. What sparked it?" },
            responseType: .emojiGrid(options: [
                EmojiOption(emoji: "😤", label: "Frustrated", value: "frustrated"),
                EmojiOption(emoji: "😒", label: "Irritated", value: "irritated"),
                EmojiOption(emoji: "🙅", label: "Disrespected", value: "disrespected"),
                EmojiOption(emoji: "🛡️", label: "Defensive", value: "defensive"),
            ]),
            dataKey: "moodSecondary",
            nextStepLogic: { _ in .mentalClarity }
        ),
        
        // 4e. Mood Secondary - Anxious
        .moodSecondaryAnxious: ChatStep(
            id: .moodSecondaryAnxious,
            louiePrompt: { _ in "Anxiety can be tough. What's it feel like?" },
            responseType: .emojiGrid(options: [
                EmojiOption(emoji: "😥", label: "Worried", value: "worried"),
                EmojiOption(emoji: "🤯", label: "Overwhelmed", value: "overwhelmed"),
                EmojiOption(emoji: "😬", label: "Nervous", value: "nervous"),
                EmojiOption(emoji: "🧘", label: "Unsettled", value: "unsettled"), // Maybe restless emoji?
            ]),
            dataKey: "moodSecondary",
            nextStepLogic: { _ in .mentalClarity }
        ),
        
        // 5. Mental Clarity
        .mentalClarity: ChatStep(
            id: .mentalClarity,
            louiePrompt: { _ in "How did your mind feel today?" },
            responseType: .emojiGrid(options: [
                EmojiOption(emoji: "💡", label: "Clear-headed", value: "clear"),
                EmojiOption(emoji: "🌫️", label: "Foggy", value: "foggy"),
                EmojiOption(emoji: "🤯", label: "Scattered", value: "scattered"),
                EmojiOption(emoji: "😟", label: "Anxious Mind", value: "anxious_mind"),
                EmojiOption(emoji: "📉", label: "Unmotivated Mind", value: "unmotivated_mind"),
            ]),
            dataKey: "mentalClarity",
            nextStepLogic: { _ in .physicalSymptoms }
        ),
        
        // 6. Physical Symptoms
        .physicalSymptoms: ChatStep(
            id: .physicalSymptoms,
            louiePrompt: { _ in "How about your body? Anything going on?" },
            responseType: .tagGrid(options: [
                TagOption(text: "Headache", value: "headache"),
                TagOption(text: "Fatigue", value: "fatigue"),
                TagOption(text: "Bloating", value: "bloating"),
                TagOption(text: "Muscle Soreness", value: "muscle_soreness"),
                TagOption(text: "Stomach Ache", value: "stomach_ache"),
                TagOption(text: "Joint Pain", value: "joint_pain"),
                TagOption(text: "Brain Fog", value: "brain_fog"),
                TagOption(text: "None today", value: "none"),
            ], allowsMultiple: true),
            dataKey: "physicalSymptoms",
            nextStepLogic: { response in
                guard let selectedValues = response as? [String] else { return .sleepHoursCheck } // Should be array of values
                if selectedValues.contains("none") || selectedValues.isEmpty {
                    return .sleepHoursCheck // Skip severity if none selected
                } else {
                    // Need to store these selected symptoms to iterate through for severity
                    // The actual logic to start the loop will be in the main handler
                    return .symptomSeverity(symptom: "") // Placeholder, real logic needed here
                }
            }
        ),
        
        // 7. Symptom Severity (Dynamic Step)
        // Note: The prompt and nextStepLogic will be handled dynamically in the main view/handler
        // based on the list of symptoms selected in the previous step.
        // We define a template here.
        .symptomSeverity(symptom: ""): ChatStep(
            id: .symptomSeverity(symptom: ""), // ID is dynamic
            louiePrompt: { symptomName in // Expects symptom name passed in
                 guard let name = symptomName as? String, !name.isEmpty else { return "How severe was it?"}
                 // Lowercase the symptom name for the prompt
                 return "How bad was your \(name.lowercased()) today?"
            },
            responseType: .slider(range: 1...10, step: 1),
            dataKey: nil, // Severity data stored dynamically, e.g., "severity_headache"
            nextStepLogic: { _ in
                // Logic to check if more symptoms need rating, handled in main handler
                return .sleepHoursCheck // Placeholder: Go to next step after loop finishes
            }
        ),
        
        // 8. Sleep Hours Check
        .sleepHoursCheck: ChatStep(
            id: .sleepHoursCheck,
            louiePrompt: { _ in
                // TODO: Replace [Health Kit Data] with actual fetched data
                let hours = "7.5" // Placeholder
                return "I see you got \(hours) hours of sleep last night. Does that sound right to you?"
            },
            responseType: .yesNo,
            dataKey: "sleepHoursConfirmed", // Store Boolean
            nextStepLogic: { response in
                guard let confirmed = response as? Bool else { return .sleepQualityRating } // Default
                return confirmed ? .sleepQualityRating : .sleepHoursManual
            }
        ),
        
        // 9. Sleep Hours Manual
        .sleepHoursManual: ChatStep(
            id: .sleepHoursManual,
            louiePrompt: { _ in "Oops! How many hours did you get?" },
            responseType: .slider(range: 0...16, step: 0.5), // Allow .5 increments
            dataKey: "sleepHoursManual",
            nextStepLogic: { _ in .sleepQualityRating }
        ),
        
        // 10. Sleep Quality Rating
        .sleepQualityRating: ChatStep(
            id: .sleepQualityRating,
            louiePrompt: { _ in "How would you rate your sleep last night?" },
            responseType: .slider(range: 1...10, step: 1),
            dataKey: "sleepQualityRating",
            nextStepLogic: { response in
                guard let rating = response as? Double else { return .stressLevel } // Default
                return rating <= 5 ? .sleepQualityReason : .stressLevel
            }
        ),
        
        // 11. Sleep Quality Reason
        .sleepQualityReason: ChatStep(
            id: .sleepQualityReason,
            louiePrompt: { _ in "Sorry to hear that, what would you say affected your sleep quality last night?" },
            responseType: .tagGrid(options: [
                TagOption(text: "Late Screen Time", value: "screen_time"),
                TagOption(text: "Racing Thoughts", value: "racing_thoughts"),
                TagOption(text: "Body Discomfort", value: "discomfort"),
                TagOption(text: "Bad Dreams", value: "bad_dreams"),
                TagOption(text: "Substance Use", value: "substance_use"),
            ], allowsMultiple: true),
            dataKey: "sleepQualityReasons",
            nextStepLogic: { _ in .stressLevel }
        ),
        
        // 12. Stress Level
        .stressLevel: ChatStep(
            id: .stressLevel,
            louiePrompt: { _ in "How stressed did you feel today?" },
            responseType: .slider(range: 1...10, step: 1),
            dataKey: "stressLevel",
            nextStepLogic: { _ in .stressCause }
        ),
        
        // 13. Stress Cause
        .stressCause: ChatStep(
            id: .stressCause,
            louiePrompt: { _ in "What caused that stress, if you can identify it?" },
            responseType: .textInput,
            dataKey: "stressCause",
            nextStepLogic: { _ in .stressCoping }
        ),
        
        // 14. Stress Coping
        .stressCoping: ChatStep(
            id: .stressCoping,
            louiePrompt: { _ in "How did you cope with that stress?" },
            responseType: .textInput,
            dataKey: "stressCopingMethod",
            nextStepLogic: { _ in .copingEffectiveness }
        ),
        
        // 15. Coping Effectiveness
        .copingEffectiveness: ChatStep(
            id: .copingEffectiveness,
            louiePrompt: { _ in "Was that coping method effective?" },
            responseType: .slider(range: 1...10, step: 1),
            dataKey: "copingEffectiveness",
            nextStepLogic: { _ in .final }
        ),
        
        // 16. Final
        .final: ChatStep(
            id: .final,
            louiePrompt: { _ in "Thanks for being honest, you're doing great! Time to fetch your insights." },
            responseType: .none,
            dataKey: nil,
            nextStepLogic: { _ in .final } // Stays here, maybe transition view later
        )
    ]

    // MARK: - State Variables
    // -- Conversation Flow State --
    @State private var currentStepId: ChatStepType = .greeting
    @State private var conversation: [Message] = []
    @State private var isLouieTalking: Bool = true
    @State private var showUserInputControls: Bool = false // Renamed from showUserOptions
    
    // -- User Input State (Temporary for current step) --
    @State private var currentSliderValue: Double = 5.0
    @State private var currentSelectedEmojiOption: EmojiOption? = nil
    @State private var currentSelectedTagIDs: Set<TagOption.ID> = []
    @State private var currentYesNoResponse: Bool? = nil
    @State private var currentTextResponse: String = ""

    // -- Data Collection State --
    @State private var collectedCheckInData: [String: Any] = [:]
    
    // -- Symptom Severity Loop State --
    @State private var symptomOptionsToRate: [TagOption] = [] // Store the full options
    @State private var currentSymptomIndex: Int = 0
    
    // MARK: - Computed Properties
    private var currentChatStep: ChatStep? {
        // Handle symptom severity lookup specially
        if case .symptomSeverity = currentStepId {
            return Self.conversationFlow[.symptomSeverity(symptom: "")]
        } else {
            return Self.conversationFlow[currentStepId]
        }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hexCode: "1a1a2e"), Color(hexCode: "3a2a60")]),
                          startPoint: .top,
                          endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in
                VStack {
                    Spacer()
                    
                    // Use the new SpeechBubbleContainer with content inside
                    SpeechBubbleContainer {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(conversation) { message in
                                    Text(message.text)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(message.fromLouie ? Color.blue.opacity(0.4) : Color.green.opacity(0.4)) // Example styling
                                        .cornerRadius(15)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: message.fromLouie ? .leading : .trailing)
                                }
                            }
                            .padding(.vertical, 5) // Padding inside ScrollView before content hits edges
                        }
                        // Give the ScrollView a flexible frame within the bubble
                        .frame(minHeight: 50, maxHeight: geometry.size.height * 0.4) 

                        // User Response Area (Moved Inside Bubble) - REMOVE FROM HERE
                        /*
                        if showUserOptions {
                            Button("Ready!") {
                                // Call the response handler
                                handleUserResponse(response: "Ready!")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple) // Example tint
                            .padding(.top, 5) // Add some padding above the button
                            .frame(maxWidth: .infinity, alignment: .trailing) // Align button to the right
                            .transition(.scale.combined(with: .opacity)) // Add animation
                        }
                        */
                    }
                    .padding(.horizontal, 20) // Padding around the bubble
                    // Use a smaller fixed bottom padding to reduce gap above Louie
                    .padding(.bottom, 20)

                    // User Response Area (Dynamic Input Controls)
                    if showUserInputControls, let step = currentChatStep {
                        VStack {
                            // Dynamically display the correct input view
                            inputView(for: step)
                            
                            // Main action button ("Done" or "Ready!")
                            Button(action: { 
                                // Call the new processing function
                                processUserInputAndProceed()
                            }) {
                                Text(buttonText(for: step))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                            .disabled(!isInputValid(for: step)) // Disable if needed
                            .padding(.horizontal, 20)
                            .padding(.top, 5) // Space between input and button
                            .padding(.bottom, 10)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Louie Avatar Section (Updated for talking state)
                    HStack {
                        Image(isLouieTalking ? "louie_talking" : "louie_listening") // Conditional image
                            .resizable()
                            // .scaledToFit() // Removed
                            .frame(width: 320, height: 320) // Restored fixed size
                            .offset(x: -40) // Restored fixed offset
                            .padding(.bottom, 20) // Restored padding
                            .animation(.easeInOut(duration: 0.3), value: isLouieTalking) // Animate image change
                        Spacer()
                    }
                    // .frame(height: geometry.size.height * 0.3) // Removed frame on HStack
                    // .padding(.bottom, -20) // Removed padding on HStack
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .padding(.top, 40) // Add padding to the top of the VStack
            }
        }
        .onAppear(perform: startConversation) // Trigger conversation start
    }
    
    // MARK: - UI Builder Helper
    @ViewBuilder
    private func inputView(for step: ChatStep) -> some View {
        // Ensure responseType has associated values extracted
        let responseType = step.responseType
        
        switch responseType {
        case .initialButton:
            EmptyView() // Button is handled separately below Vstack

        case .slider(let range, let stepValue):
            RatingsSliderView(
                value: $currentSliderValue,
                range: range,
                step: stepValue
            )
            .padding(.horizontal, 20) // Add padding to match button

        case .emojiGrid(let options):
            EmojiGridView(
                options: options,
                selectedOption: $currentSelectedEmojiOption
            )
            .padding(.horizontal, 20)

        case .tagGrid(let options, let allowsMultiple):
            TagGridView(
                options: options,
                selectedIDs: $currentSelectedTagIDs,
                allowsMultiple: allowsMultiple
            )
            .padding(.horizontal, 20)

        case .yesNo:
            YesNoButtonsView(selection: $currentYesNoResponse)
             .padding(.horizontal, 20)

        case .textInput:
            // We need placeholder text from the step definition if available
            TextInputView(text: $currentTextResponse, placeholder: "Type your response...")
             .padding(.horizontal, 20)

        case .none:
            EmptyView() // No input needed for this step
        }
    }
    
    // Helper to determine button text
    private func buttonText(for step: ChatStep) -> String {
        switch step.responseType {
        case .initialButton: return "Ready!"
        default: return "Done"
        }
    }
    
    // Helper to determine if input is valid for enabling button (basic examples)
    private func isInputValid(for step: ChatStep) -> Bool {
        switch step.responseType {
        case .initialButton: return true // Always enabled
        case .slider: return true // Slider always has a value
        case .emojiGrid: return currentSelectedEmojiOption != nil
        case .tagGrid: return !currentSelectedTagIDs.isEmpty
        case .yesNo: return currentYesNoResponse != nil
        case .textInput: return !currentTextResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .none: return false // No button for .none steps
        }
    }

    // MARK: - Conversation Logic
    func startConversation() {
        // Ensure conversation starts fresh if view appears again
        conversation.removeAll()
        collectedCheckInData.removeAll()
        symptomOptionsToRate.removeAll() // Add new
        currentSymptomIndex = 0
        currentStepId = .greeting // Start at greeting
        resetInputStates() // Reset temporary inputs
        
        isLouieTalking = true
        showUserInputControls = false
        
        // Get the initial step definition
        guard let initialStep = Self.conversationFlow[.greeting] else { return }
        
        // Add Louie's initial message
        let initialMessage = Message(text: initialStep.louiePrompt(nil), fromLouie: true)
        conversation.append(initialMessage)
        
        // Simulate Louie finishing talking and show user options
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { // Adjust delay as needed
            withAnimation {
                 isLouieTalking = false
                 // Use pattern matching for enums with associated values
                 if case .none = initialStep.responseType {}
                 else { // If it's not .none
                     showUserInputControls = true
                 }
            }
        }
    }

    // Renamed and refactored function to handle conversation progression
    func processUserInputAndProceed() {
        guard let currentStep = currentChatStep else { return }

        // 1. Extract Data and Determine User Message Text
        var userInputData: Any? = nil
        var userMessageText: String? = nil

        switch currentStep.responseType {
            case .initialButton:
                userMessageText = "Ready!"
                userInputData = "Ready!" // Or nil, depending on if greeting needs data
            case .slider: 
                userInputData = currentSliderValue
                userMessageText = String(format: "%.1f / 10", currentSliderValue) // Example format
            case .emojiGrid: 
                userInputData = currentSelectedEmojiOption?.value // Store the value
                userMessageText = currentSelectedEmojiOption?.label // Display the label
            case .tagGrid(let options, let allowsMultiple):
                // Use options directly from the case, type is [TagOption]
                let selectedOptions = options.filter { currentSelectedTagIDs.contains($0.id) }
                let values = selectedOptions.map { $0.value }
                let labels = selectedOptions.map { $0.text }
                userInputData = values // Store array of values
                if !allowsMultiple { userInputData = values.first } // Store single value if not multi-select
            case .yesNo: 
                userInputData = currentYesNoResponse
                userMessageText = currentYesNoResponse == true ? "Yes" : (currentYesNoResponse == false ? "No" : nil)
            case .textInput: 
                let trimmedText = currentTextResponse.trimmingCharacters(in: .whitespacesAndNewlines)
                userInputData = trimmedText.isEmpty ? nil : trimmedText
                userMessageText = trimmedText.isEmpty ? nil : trimmedText
            case .none:
                break // No input data or user message needed
        }

        // 2. Hide Controls & Add User Message
        withAnimation {
            showUserInputControls = false
        }
        if let text = userMessageText, !text.isEmpty {
            let userMessage = Message(text: text, fromLouie: false)
            conversation.append(userMessage)
        }
        
        // Immediately set Louie to talking for his response/next question
        isLouieTalking = true

        // 3. Store Data (if key exists)
        if let key = currentStep.dataKey, let data = userInputData {
            collectedCheckInData[key] = data
        }
        
        // 4. Determine Next Step ID & Handle Symptom Loop
        var nextStepId: ChatStepType
        var symptomLoopJustStarted = false
        
        if currentStepId == .physicalSymptoms, let selectedSymptomValues = userInputData as? [String] {
            // Find the actual TagOption objects selected
            if let physicalSymptomOptions = Self.getOptions(from: currentStep.responseType) as? [TagOption] {
                symptomOptionsToRate = physicalSymptomOptions.filter { selectedSymptomValues.contains($0.value) && $0.value != "none" }
            } else {
                symptomOptionsToRate = [] // Should not happen if setup is correct
            }

            if !symptomOptionsToRate.isEmpty {
                currentSymptomIndex = 0
                // Use the value from the first option to create the specific step ID
                nextStepId = .symptomSeverity(symptom: symptomOptionsToRate[currentSymptomIndex].value)
                symptomLoopJustStarted = true
                 // REMOVE Storage here - value is not set yet
                 // collectedCheckInData["severity_\(symptomsToRate[currentSymptomIndex])"] = currentSliderValue 
            } else {
                // No valid symptoms selected (only "none" or empty)
                nextStepId = currentStep.nextStepLogic(userInputData) // Should lead to .sleepHoursCheck
            }
        } else if case .symptomSeverity(let currentSymptomValue) = currentStepId { // Use value here
             // Store the severity rating for the *completed* symptom using its value
             collectedCheckInData["severity_\(currentSymptomValue)"] = currentSliderValue

            // Check against the count of stored options
            // Increment index *before* checking for next step
            currentSymptomIndex += 1
            if currentSymptomIndex < symptomOptionsToRate.count {
                 // Get the value for the next symptom ID
                nextStepId = .symptomSeverity(symptom: symptomOptionsToRate[currentSymptomIndex].value)
            } else {
                // Finished loop, get the step defined after severity loop in the template
                nextStepId = currentStep.nextStepLogic(userInputData) // Should be .sleepHoursCheck
            }
        } else {
            // General case: Use the defined logic
            nextStepId = currentStep.nextStepLogic(userInputData)
        }

        // 5. Transition to Next Step
        // Fetch the step definition using the correct key
        var nextStepDefinition: ChatStep?
        if case .symptomSeverity = nextStepId {
             // Use the placeholder key to get the template definition for severity steps
            nextStepDefinition = Self.conversationFlow[.symptomSeverity(symptom: "")]
        } else {
            // Use the exact ID for all other steps
            nextStepDefinition = Self.conversationFlow[nextStepId]
        }

        guard let nextStep = nextStepDefinition else { 
            print("Error: Could not find next step definition for ID: \(nextStepId)")
            // Attempt to gracefully recover or default, e.g., go to final step
            // For now, just return to prevent crash
            return 
        }

        // Determine prompt (pass symptom TEXT if starting/in severity loop)
        var promptArg: Any? = nil
        // Check based on the *next* step ID we are transitioning TO
        if case .symptomSeverity = nextStepId, currentSymptomIndex < symptomOptionsToRate.count {
             // Pass the TEXT of the symptom we are about to ask for
            promptArg = symptomOptionsToRate[currentSymptomIndex].text
        }
        // The check for symptomLoopJustStarted is implicitly handled by the above condition now

        let louieResponseText = nextStep.louiePrompt(promptArg)

        // Add Louie's response message after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            let louieMessage = Message(text: louieResponseText, fromLouie: true)
            withAnimation { conversation.append(louieMessage) }

            // Schedule state update for showing next input (if any)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    self.currentStepId = nextStepId // Update current step ID *here*
                    self.resetInputStates() // Reset temporary fields
                    isLouieTalking = false
                    // Use pattern matching for enums with associated values
                    if case .none = nextStep.responseType {}
                    else { // If it's not .none
                        showUserInputControls = true
                    }
                }
                 // If final step, trigger save
                 if nextStepId == .final {
                     saveCheckInDataToCloudKit()
                 }
            }
        }
    }
    
    // Helper function to get options from ResponseType enum case
    static func getOptions(from responseType: ResponseType?) -> [any Identifiable & Hashable]? {
        switch responseType {
            case .emojiGrid(let options): return options
            case .tagGrid(let options, _): return options
            default: return nil
        }
    }

    // TODO: Implement CloudKit Saving Logic
    func saveCheckInDataToCloudKit() {
        print("--- Saving Check-In Data --- \n\(collectedCheckInData)\n---------------------------")
        // Add actual CloudKit saving code here using collectedCheckInData dictionary
    }
    
    // Helper to reset temporary input states between steps
    func resetInputStates() {
        currentSliderValue = 5.0
        currentSelectedEmojiOption = nil
        currentSelectedTagIDs = []
        currentYesNoResponse = nil
        currentTextResponse = ""
    }
}

struct InsightsScreen_Previews: PreviewProvider {
    static var previews: some View {
        InsightsScreen()
    }
}
