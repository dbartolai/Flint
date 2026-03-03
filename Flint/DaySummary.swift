//
//  DaySummary.swift
//  Flint
//
//  Created by Drake Bartolai on 3/3/26.
//

import Foundation
import SwiftUI
import EventKit

struct IdentifiedEvent: Identifiable {
    let id = UUID()
    let event: EKEvent
}

struct IdentifiedReminder: Identifiable {
    let id = UUID()
    let reminder: EKReminder
}

struct DaySummary: View {
    let slot: TimeSlot
    let events: [EKEvent]
    let reminders: [EKReminder]
    
    private var identifiedEvents: [IdentifiedEvent] {
        events.map { IdentifiedEvent(event: $0) }
    }
    
    private var now: Date { Date() }
    
    private var currentEvents: [IdentifiedEvent] {
        identifiedEvents.filter { $0.event.startDate <= now && $0.event.endDate >= now }
    }
    
    private var upcomingEvents: [IdentifiedEvent] {
        identifiedEvents.filter { $0.event.startDate > now }
    }
    
    private var pastEvents: [IdentifiedEvent] {
        identifiedEvents.filter { $0.event.endDate < now }
    }
    
    private var todayReminders: [IdentifiedReminder] {
        reminders
            .filter { r in
                guard let due = r.dueDateComponents?.date else { return false }
                return Calendar.current.isDateInToday(due)
            }
            .map { IdentifiedReminder(reminder: $0) }
    }
    
    private var overdueReminders: [IdentifiedReminder] {
        reminders
            .filter { r in
                guard let due = r.dueDateComponents?.date else { return false }
                return due < Calendar.current.startOfDay(for: Date())
            }
            .map { IdentifiedReminder(reminder: $0) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(slot.greeting)
                .font(.system(.title, design: .serif))
                .foregroundStyle(FlintColors.softAmber)
                .frame(maxWidth: .infinity, alignment: .center)
            
            if !events.isEmpty {
                if !currentEvents.isEmpty {
                    Text("Now")
                        .font(.caption)
                        .foregroundStyle(FlintColors.warmAmber)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    ForEach(currentEvents) { item in
                        HStack(spacing: 10) {
                            Text(item.event.startDate.formatted(date: .omitted, time: .shortened))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(FlintColors.warmAmber)
                                .frame(width: 65, alignment: .leading)
                            
                            Text(item.event.title ?? "Untitled")
                                .font(.system(.subheadline, design: .serif))
                                .foregroundStyle(FlintColors.warmWhite)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(FlintColors.warmAmber.opacity(0.08))
                        )
                    }
                }
                
                if !upcomingEvents.isEmpty {
                    Text("Upcoming")
                        .font(.caption)
                        .foregroundStyle(FlintColors.mutedGray)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    ForEach(upcomingEvents) { item in
                        HStack(spacing: 10) {
                            Text(item.event.startDate.formatted(date: .omitted, time: .shortened))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(FlintColors.mutedGray)
                                .frame(width: 65, alignment: .leading)
                            
                            Text(item.event.title ?? "Untitled")
                                .font(.system(.subheadline, design: .serif))
                                .foregroundStyle(FlintColors.warmWhite)
                        }
                    }
                }
                
                if !pastEvents.isEmpty {
                    Text("Earlier")
                        .font(.caption)
                        .foregroundStyle(FlintColors.mutedGray)
                        .textCase(.uppercase)
                        .tracking(1)
                        .padding(.top, 4)
                    
                    ForEach(pastEvents) { item in
                        HStack(spacing: 10) {
                            Text(item.event.startDate.formatted(date: .omitted, time: .shortened))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(FlintColors.mutedGray.opacity(0.5))
                                .frame(width: 65, alignment: .leading)
                            
                            Text(item.event.title ?? "Untitled")
                                .font(.system(.subheadline, design: .serif))
                                .foregroundStyle(FlintColors.mutedGray)
                        }
                    }
                }
            }
            
            if !todayReminders.isEmpty {
                Text("Due Today")
                    .font(.caption)
                    .foregroundStyle(FlintColors.ember)
                    .textCase(.uppercase)
                    .tracking(1)
                    .padding(.top, 4)
                
                ForEach(todayReminders) { item in
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundStyle(FlintColors.ember.opacity(0.7))
                        
                        Text(item.reminder.title ?? "Untitled")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(FlintColors.softAmber)
                    }
                }
            }
            
            if !overdueReminders.isEmpty {
                Text("Overdue")
                    .font(.caption)
                    .foregroundStyle(FlintColors.ember)
                    .textCase(.uppercase)
                    .tracking(1)
                    .padding(.top, 4)
                
                ForEach(overdueReminders) { item in
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundStyle(FlintColors.ember.opacity(0.7))
                        
                        Text(item.reminder.title ?? "Untitled")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(FlintColors.softAmber)
                    }
                }
            }
            
            if events.isEmpty && reminders.isEmpty {
                Text("Clear schedule today")
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(FlintColors.mutedGray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, 32)
    }
}
