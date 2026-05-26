//
//  FlintTests.swift
//  FlintTests
//
//  Created by Drake Bartolai on 3/3/26.
//

import Testing
import Foundation
@testable import Flint

struct FlintTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test func timeSlotBoundariesMatchPromptSchedule() {
        #expect(TimeSlot.slot(for: date(hour: 4), calendar: calendar) == .night)
        #expect(TimeSlot.slot(for: date(hour: 5), calendar: calendar) == .morning)
        #expect(TimeSlot.slot(for: date(hour: 12), calendar: calendar) == .afternoon)
        #expect(TimeSlot.slot(for: date(hour: 17), calendar: calendar) == .evening)
        #expect(TimeSlot.slot(for: date(hour: 20), calendar: calendar) == .evening)
        #expect(TimeSlot.slot(for: date(hour: 21), calendar: calendar) == .night)
    }

    @Test func nextSlotDisplayMatchesBoundaries() {
        #expect(TimeSlot.morning.next == .afternoon)
        #expect(TimeSlot.morning.nextStartTimeText == "12:00 PM")
        #expect(TimeSlot.afternoon.next == .evening)
        #expect(TimeSlot.afternoon.nextStartTimeText == "5:00 PM")
        #expect(TimeSlot.evening.next == .night)
        #expect(TimeSlot.evening.nextStartTimeText == "9:00 PM")
        #expect(TimeSlot.night.next == .morning)
        #expect(TimeSlot.night.nextStartTimeText == "5:00 AM")
    }

    @Test func promptGeneratorFailsBeforeNetworkWhenAPIKeyIsMissing() async {
        let generator = PromptGenerator(slot: .morning, apiKeyProvider: { "" })

        do {
            _ = try await generator.generate(context: "No events today.")
            Issue.record("Expected missing API key before network request.")
        } catch FlintError.missingAPIKey {
        } catch {
            Issue.record("Expected missing API key, got \(error).")
        }
    }

    private func date(hour: Int) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = 2026
        components.month = 1
        components.day = 1
        components.hour = hour
        return components.date!
    }
}
