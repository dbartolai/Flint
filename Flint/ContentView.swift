import SwiftUI
import SwiftData
import FoundationModels
import EventKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Prompt.timestamp, order: .reverse) private var allPrompts: [Prompt]
    @State private var currentSlot: TimeSlot = TimeSlot.current()
    @State private var showHistory: Bool = false
    @State private var showCompleteFlow: Bool = false
    @State private var isLoading: Bool = false
    @State private var todayEvents: [EKEvent] = []
    @State private var relevantReminders: [EKReminder] = []
    @State private var hasLoadedContext = false
    
    private var todaysPromptForSlot: Prompt? {
        let calendar = Calendar.current
        return allPrompts.first { prompt in
            calendar.isDateInToday(prompt.timestamp) && prompt.slot == currentSlot.rawValue
        }
    }
    
    private var nextSlotTime: String {
        switch currentSlot {
        case .morning: return "12:00 PM"
        case .afternoon: return "5:00 PM"
        case .evening: return "9:00 PM"
        case .night: return "5:00 AM"
        }
    }
    
    private var nextSlot: TimeSlot {
        switch currentSlot {
        case .morning: return .afternoon
        case .afternoon: return .evening
        case .evening: return .night
        case .night: return .morning
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [FlintColors.darkCharcoal, FlintColors.charcoal],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button(action: { showHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                            .foregroundStyle(FlintColors.softAmber)
                    }
                }
                .padding(.horizontal)
                
                Label(currentSlot.label, systemImage: currentSlot.systemIcon)
                    .font(.subheadline)
                    .foregroundStyle(FlintColors.mutedGray)
                
                Spacer()
                
                if isLoading {
                    // With this:
                    VStack(spacing: 12) {
                        Image(systemName: "flame")
                            .font(.system(size: 32))
                            .foregroundStyle(FlintColors.warmAmber)
                            .symbolEffect(.pulse)
                        
                        Text("Generating...")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(FlintColors.mutedGray)
                    }
                    .padding()
                } else if let existing = todaysPromptForSlot {
                    if existing.completed {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(FlintColors.warmAmber)
                            
                            Text("Next prompt at \(nextSlotTime)")
                                .font(.system(.title2, design: .serif))
                                .foregroundStyle(FlintColors.warmWhite)
                            
                            Label(nextSlot.label, systemImage: nextSlot.systemIcon)
                                .font(.subheadline)
                                .foregroundStyle(FlintColors.mutedGray)
                        }
                    } else {
                        Text(existing.prompt)
                            .font(.system(.title2, design: .serif))
                            .foregroundStyle(FlintColors.warmWhite)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text(existing.timestamp, format: .dateTime.month(.wide).day().hour().minute())
                            .font(.caption)
                            .foregroundStyle(FlintColors.mutedGray)
                        
                        Button(action: { showCompleteFlow = true }) {
                            Label("Complete", systemImage: "checkmark.circle")
                                .font(.headline)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 32)
                                .foregroundStyle(FlintColors.charcoal)
                        }
                        .buttonStyle(.plain) // Use plain to gain full control over the 'Glass' container
                        .background {
                            ZStack {
                                // 1. The base material (provides the blur/glassiness)
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.ultraThinMaterial)
                                
                                // 2. The Liquid Amber Tint
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(FlintColors.warmAmber.opacity(1)) 
                                    .shadow(color: FlintColors.warmAmber.opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                // 3. The Inner Glow / Stroke
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(FlintColors.softAmber.opacity(0.4), lineWidth: 1)
                            }
                        }
                    }
                } else {
                    DaySummary(
                        slot: currentSlot,
                        events: todayEvents,
                        reminders: relevantReminders
                    )

                }
                
                Spacer()
                
                if todaysPromptForSlot == nil && !isLoading {
                    Button(action: generatePrompt) {
                        Label("Let's Journal", systemImage: "flame")
                            .font(.headline)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 32)
                            .foregroundStyle(FlintColors.charcoal)
                    }
                    .buttonStyle(.plain) // Use plain to gain full control over the 'Glass' container
                    .background {
                        ZStack {
                            // 1. The base material (provides the blur/glassiness)
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.ultraThinMaterial)
                            
                            // 2. The Liquid Amber Tint
                            RoundedRectangle(cornerRadius: 14)
                                .fill(FlintColors.warmAmber.opacity(1))
                                .shadow(color: FlintColors.warmAmber.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            // 3. The Inner Glow / Stroke
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(FlintColors.softAmber.opacity(0.4), lineWidth: 1)
                        }
                    }
                                        
                    #if DEBUG
                    Button("Test Prompts") {
                        Task {
                            let service = EventKitService()
                            await service.requestAccess()
                            let context = await service.buildContextString(for: currentSlot)
                            
                            for slot in TimeSlot.allCases {
                                print("\n========== \(slot.label.uppercased()) ==========")
                                let generator = PromptGenerator(slot: slot)
                                for i in 1...5 {
                                    let result = try? await generator.generate(context: context)
                                    print("  #\(i): \(result ?? "failed")")
                                }
                            }
                            print("\n========== DONE ==========")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(FlintColors.mutedGray)
                    #endif

                }
            }
            .padding(.bottom, 48)
        }
        .sheet(isPresented: $showHistory) {
            HistoryDrawer()
        }
        .sheet(isPresented: $showCompleteFlow) {
            if let prompt = todaysPromptForSlot {
                CompleteFlowSheet(prompt: prompt)
            }
        }
        .onAppear {
            loadContext()
        }

    }
    
    private func generatePrompt() {
        let slot = TimeSlot.current()
        isLoading = true
        
        Task {
            let service = EventKitService()
            await service.requestAccess()
            
            let context = await service.buildContextString(for: slot)
            let generator = PromptGenerator(slot: slot)
            
            do {
                let result = try await generator.generate(context: context)
                let saved = Prompt(timestamp: Date(), prompt: result, slot: slot)
                modelContext.insert(saved)
            } catch {
                // Handle error
            }
            
            isLoading = false
        }
    }
    
    private func loadContext() {
        guard !hasLoadedContext else { return }
        hasLoadedContext = true
        
        Task {
            let service = EventKitService()
            await service.requestAccess()
            todayEvents = service.fetchTodayEventsPublic()
            relevantReminders = await service.fetchRelevantRemindersPublic()
        }
    }

}
