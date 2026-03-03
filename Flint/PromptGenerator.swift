//
//  PromptGenerator.swift
//  Flint
//

import Foundation

struct PromptGenerator {
    let slot: TimeSlot
    
    private var apiKey: String {
            Bundle.main.infoDictionary?["AnthropicAPIKey"] as? String ?? ""
        }

    private let model = "claude-haiku-4-5-20251001"
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    
    func generate(context: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 100,
            "temperature": 0.9,
            "system": """
            You generate a single journaling prompt. One question, under 20 words. \
            No preamble, no quotes, no label — just the question itself.

            VOICE:
            - Direct second-person ("you", "your")
            - Honest and grounded, never cheesy or motivational-poster
            - Conversational but pointed, like a sharp friend asking the right question
            - Vary your openings: "What", "Where", "Who", "How", "Name one", "Finish this:", "Describe"

            WHAT MAKES A GOOD PROMPT:
            - It stops someone mid-thought and makes them actually reflect
            - It asks about feelings, alignment, tension, or meaning — not logistics
            - It's specific enough to anchor real writing, open enough to go deep
            - Examples:
              "What would you do differently if today were a practice run?"
              "What's draining you right now? What's energizing you?"
              "Who made today better, and did you tell them?"
              "What assumption are you carrying that might not be true?"
              "Describe today in three words. Then explain one of them."
              "What's one thing you're overthinking right now?"

            WHAT TO AVOID:
            - Generic self-help ("What are you grateful for?", "How can you grow?")
            - Productivity framing ("What's your top priority?") unless it ties to meaning
            - Anything that sounds like a therapy worksheet or corporate icebreaker
            - Starting every prompt with "What" — mix it up
            - Referencing specific event names from the calendar — keep it abstract
            - Going over 20 words

            CALENDAR/REMINDER CONTEXT:
            You'll receive the user's schedule and reminders. Use this context \
            only when it genuinely sharpens the prompt. Think about:
            - How completed events may have shaped their mood or energy
            - How upcoming events might be creating anticipation or dread
            - Overdue reminders as possible sources of avoidance or stress
            - But a great prompt with no calendar reference beats a forced one
            If the day is light or empty, lean into that — open space is its own prompt.

            \(slot.promptGuidance)
            """,
            "messages": [
                ["role": "user", "content": context]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("[Flint] API Key present: \(!apiKey.isEmpty)")
        print("[Flint] API Key prefix: \(String(apiKey.prefix(10)))")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let httpResponse = response as? HTTPURLResponse
        print("[Flint] Status: \(httpResponse?.statusCode ?? -1)")
        print("[Flint] Body: \(String(data: data, encoding: .utf8) ?? "nil")")
        
        guard httpResponse?.statusCode == 200 else {
            throw FlintError.generationFailed
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content = json?["content"] as? [[String: Any]]
        let text = content?.first?["text"] as? String
        
        guard let prompt = text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw FlintError.generationFailed
        }
        
        return prompt
    }
}

enum FlintError: Error {
    case generationFailed
}
