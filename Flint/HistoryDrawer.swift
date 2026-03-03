// HistoryDrawer.swift
import SwiftUI
import SwiftData

struct HistoryDrawer: View {
    @Query(filter: #Predicate<Prompt> { $0.completed == true },
           sort: \Prompt.timestamp, order: .reverse)
    private var completedPrompts: [Prompt]
    
    @Environment(\.dismiss) private var dismiss
    
    private var groupedByDate: [(String, [Prompt])] {
        let grouped = Dictionary(grouping: completedPrompts) { prompt in
            prompt.timestamp.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
        }
        return grouped.sorted { a, b in
            completedPrompts.first { $0.timestamp.formatted(.dateTime.weekday(.wide).month(.wide).day().year()) == a.key }?.timestamp ?? .distantPast >
            completedPrompts.first { $0.timestamp.formatted(.dateTime.weekday(.wide).month(.wide).day().year()) == b.key }?.timestamp ?? .distantPast
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedByDate, id: \.0) { dateString, prompts in
                    DisclosureGroup {
                        ForEach(prompts) { prompt in
                            NavigationLink {
                                PromptDetailView(prompt: prompt)
                            } label: {
                                HStack {
                                    Label(prompt.timeSlot.label, systemImage: prompt.timeSlot.systemIcon)
                                        .font(.caption)
                                        .foregroundStyle(FlintColors.softAmber)
                                    
                                    Spacer()
                                    
                                    if prompt.imageData != nil {
                                        Image(systemName: "photo")
                                            .font(.caption2)
                                            .foregroundStyle(FlintColors.mutedGray.opacity(0.6))
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listRowBackground(FlintColors.charcoal)
                    } label: {
                        Text(dateString)
                            .foregroundStyle(FlintColors.warmWhite)
                    }
                    .listRowBackground(FlintColors.charcoal)
                    .tint(FlintColors.softAmber)
                }
            }
            .scrollContentBackground(.hidden)
            .background(FlintColors.darkCharcoal)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(FlintColors.softAmber)
                }
            }
        }
    }
}
