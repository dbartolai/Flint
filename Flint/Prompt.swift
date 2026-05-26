//
//  Item.swift
//  Flint
//
//  Created by Drake Bartolai on 3/3/26.
//

import Foundation
import SwiftData

enum TimeSlot: String, Codable, CaseIterable {
    case morning    // 5am - 12pm
    case afternoon  // 12pm - 5pm
    case evening    // 5pm - 9pm
    case night      // 9pm - 5am
    
    static func current() -> TimeSlot {
        slot(for: Date())
    }

    static func slot(for date: Date, calendar: Calendar = .current) -> TimeSlot {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }
    
    var label: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .night: return "Night"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.fill"
        }
    }

    var next: TimeSlot {
        switch self {
        case .morning: return .afternoon
        case .afternoon: return .evening
        case .evening: return .night
        case .night: return .morning
        }
    }

    var nextStartTimeText: String {
        switch self {
        case .morning: return "12:00 PM"
        case .afternoon: return "5:00 PM"
        case .evening: return "9:00 PM"
        case .night: return "5:00 AM"
        }
    }
    
    var promptGuidance: String {
        switch self {
        case .morning:
            return """
            MORNING — The day is ahead. Prompt about intention, energy, or mindset. \
            How do they want to show up? What matters today beyond the to-do list? \
            What are they carrying in from yesterday? What needs to be left behind? \
            Encourage them to look forward on the day with positivity and energy
            """
        case .afternoon:
            return """
            AFTERNOON — They're in it. Prompt about momentum, presence, or honesty. \
            What's working, what's not? Where did they lose themselves or find themselves? \
            What small thing deserves more credit? What's being avoided? \
            Use language like "so far" and encourage them to take a midday pivot or keep their momentum 
            """
        case .evening:
            return """
            EVENING — The day is mostly done. Prompt about meaning, surprise, or connection. \
            What moment stands out? What did today reveal? Who mattered? \
            What would they tell someone about this day? \
            Try to have them think about settling down from a busy day and center themselves \
            Is there anything left to take care of tonight? Any plans? Or is it just time to relax?
            """
        case .night:
            return """
            NIGHT — Quiet hours. Prompt about release, honesty, or forward vision. \
            What's looping in their head? What needs forgiving? What's weighing on them \
            that can wait? Who do they want to be tomorrow? \
            This prompt will have the most thinking time associated with it; that should be reflected in the prompt itself \
            Look inwards, look backwards on the day, or look forwards to tomorrow.
            """
        }
    }
    var greeting: String {
        switch self {
        case .morning: return "Here's what's ahead:"
        case .afternoon: return "How's the day shaping up?"
        case .evening: return "Here's what today looked like."
        case .night: return "One more look at the day."
        }
    }
}

@Model
final class Prompt {
    var timestamp: Date
    var prompt: String
    var slot: String
    var imageData: Data?
    var completed: Bool
    var entry: String?
    
    init(timestamp: Date, prompt: String, slot: TimeSlot, imageData: Data? = nil, completed: Bool = false, entry: String? = nil) {
        self.timestamp = timestamp
        self.prompt = prompt
        self.slot = slot.rawValue
        self.imageData = imageData
        self.completed = completed
        self.entry = entry
    }
    
    var timeSlot: TimeSlot {
        TimeSlot(rawValue: slot) ?? .morning
    }
}
