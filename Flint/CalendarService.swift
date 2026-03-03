//
//  CalendarService.swift
//  Flint
//
//  Created by Drake Bartolai on 3/3/26.
//


import EventKit
import Foundation

@MainActor
class EventKitService {
    private let store = EKEventStore()
    
    private var hasCalendarAccess = false
    private var hasRemindersAccess = false
    
    // MARK: - Permissions
    
    func requestAccess() async {
        // Calendar
        do {
            hasCalendarAccess = try await store.requestFullAccessToEvents()
        } catch {
            hasCalendarAccess = false
        }
        
        // Reminders
        do {
            hasRemindersAccess = try await store.requestFullAccessToReminders()
        } catch {
            hasRemindersAccess = false
        }
    }
    
    // MARK: - Fetch Events
    
    private func fetchTodayEvents() -> [EKEvent] {
        guard hasCalendarAccess else { return [] }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = store.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )
        
        return store.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
    }
    
    // MARK: - Fetch Reminders
    
    private func fetchRelevantReminders() async -> [EKReminder] {
        guard hasRemindersAccess else { return [] }
        
        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: nil,       // no lower bound — catches overdue
            ending: Calendar.current.date(   // through end of today
                byAdding: .day, value: 1,
                to: Calendar.current.startOfDay(for: Date())
            ),
            calendars: nil
        )
        
        return await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }
    
    // MARK: - Build Context String
    
    func buildContextString(for slot: TimeSlot) async -> String {
        var parts: [String] = []
        
        // Date header
        parts.append("Today is \(Date().formatted(date: .complete, time: .omitted)).")
        parts.append("Current time slot: \(slot.label)")
        
        // Events
        let events = fetchTodayEvents()
        if events.isEmpty {
            parts.append("\nCalendar: No events today.")
        } else {
            parts.append("\nCalendar events:")
            for event in events {
                let time = event.startDate.formatted(date: .omitted, time: .shortened)
                parts.append("- \(time): \(event.title ?? "Untitled")")
            }
        }
        
        // Reminders
        let reminders = await fetchRelevantReminders()
        let overdue = reminders.filter { reminder in
            guard let due = reminder.dueDateComponents?.date else { return false }
            return due < Calendar.current.startOfDay(for: Date())
        }
        let dueToday = reminders.filter { reminder in
            guard let due = reminder.dueDateComponents?.date else { return false }
            return Calendar.current.isDateInToday(due)
        }
        let noDueDate = reminders.filter { $0.dueDateComponents?.date == nil }
        
        if !overdue.isEmpty {
            parts.append("\nOverdue reminders:")
            for r in overdue {
                let daysOverdue = overdueDescription(for: r)
                parts.append("- \(r.title ?? "Untitled")\(daysOverdue)")
            }
        }
        
        if !dueToday.isEmpty {
            parts.append("\nDue today:")
            for r in dueToday {
                parts.append("- \(r.title ?? "Untitled")")
            }
        }
        
        // Include a few with no due date for extra context, capped at 5
        if !noDueDate.isEmpty {
            parts.append("\nOpen reminders:")
            for r in noDueDate.prefix(5) {
                parts.append("- \(r.title ?? "Untitled")")
            }
        }
        
        return parts.joined(separator: "\n")
    }
    
    func fetchTodayEventsPublic() -> [EKEvent] {
        fetchTodayEvents()
    }

    func fetchRelevantRemindersPublic() async -> [EKReminder] {
        await fetchRelevantReminders()
    }
    
    // MARK: - Helpers
    
    private func overdueDescription(for reminder: EKReminder) -> String {
        guard let dueComps = reminder.dueDateComponents,
              let dueDate = Calendar.current.date(from: dueComps) else {
            return ""
        }
        
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: dueDate),
            to: Calendar.current.startOfDay(for: Date())
        ).day ?? 0
        
        if days == 1 {
            return " (1 day overdue)"
        } else if days > 1 {
            return " (\(days) days overdue)"
        }
        return ""
    }
}
