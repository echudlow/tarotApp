//  TarotAPI.swift
//  Tarot

import Foundation

// MARK: - Request/Response models (keep these)
struct TarotAPICard: Codable {
    let name: String
    let position: String
    let isReversed: Bool
    let uprightMeaning: String
    let reversedMeaning: String
    let suit: String?
    let arcana: String?

    enum CodingKeys: String, CodingKey {
        case name, position, suit, arcana
        case isReversed = "is_reversed"
        case uprightMeaning = "upright_meaning"
        case reversedMeaning = "reversed_meaning"
    }
}

struct SpreadRequestBody: Codable {
    let spread_type: String
    let cards: [TarotAPICard]
}

struct SpreadResponseBody: Codable {
    let interpretation: String
}

// MARK: - Anthropic response models
struct AnthropicResponse: Codable {
    let content: [AnthropicContent]
}

struct AnthropicContent: Codable {
    let type: String
    let text: String
}

// MARK: - TarotService
struct TarotService {

    private let apiKey: String
    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!

    init() {
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let key = dict["ANTHROPIC_API_KEY"] as? String {
            self.apiKey = key
        } else {
            fatalError("Missing Config.plist or ANTHROPIC_API_KEY")
        }
    }

    func interpretSpread(_ body: SpreadRequestBody) async throws -> SpreadResponseBody {
        let prompt = buildPrompt(body)

        let requestBody: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 700,
            "system": "You are an experienced tarot reader speaking directly to someone. Be warm, honest, and grounded - you can be poetic when it fits naturally, but avoid cliches, filler phrases, and anything that sounds like a chatbot. Speak like a real person who genuinely knows this card. Follow the formatting rules exactly.",
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(domain: "TarotService", code: http.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "API error: \(body)"])
        }

        let decoded = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        let text = decoded.content.first?.text ?? "I couldn't interpret this spread right now."

        return SpreadResponseBody(interpretation: normalizeOutput(body, text: text))
    }

    // MARK: - Prompt building
    private func buildPrompt(_ req: SpreadRequestBody) -> String {
        let isDaily = req.spread_type == "daily" || req.cards.count == 1

        if isDaily, let c = req.cards.first {
            let orientation = c.isReversed ? "Reversed" : "Upright"
            let meaning = c.isReversed ? c.reversedMeaning : c.uprightMeaning
            return """
            Write a daily tarot interpretation. Speak directly to the person - be specific, grounded, and conversational. A little poetic is fine.

            STRICT RULES:
            - Do NOT use Past/Present/Future.
            - Do NOT include greetings or filler.
            - Do NOT mention that you're an AI.
            - Output ONLY in this exact structure:

            **Daily Card - \(c.name) (\(orientation)):**
            <1-2 short paragraphs>

            **Overall Message:**
            <1 short paragraph>

            Card meaning reference (use as guidance, do not quote verbatim):
            \(meaning)
            """
        }

        var lines = [
            "Interpret the following tarot spread. Speak directly to the person.",
            "",
            "STRICT RULES:",
            "- Do NOT include greetings or filler.",
            "- For EACH card, output exactly one section in this format:",
            "  **<Position> - <Card Name> (<Upright/Reversed>):**",
            "  <1 paragraph interpretation>",
            "- End with:",
            "  **Putting It All Together:**",
            "  <1 paragraph synthesis>",
            "",
            "CARDS:"
        ]

        for c in req.cards {
            let orientation = c.isReversed ? "Reversed" : "Upright"
            let meaning = c.isReversed ? c.reversedMeaning : c.uprightMeaning
            lines.append("- Position: \(c.position) | Card: \(c.name) | Orientation: \(orientation) | MeaningRef: \(meaning)")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Output normalization
    private func normalizeOutput(_ req: SpreadRequestBody, text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let fillerPhrases = ["Certainly!", "Sure!", "Of course!", "Absolutely!", "Okay!", "Alright!"]
        for phrase in fillerPhrases {
            if result.hasPrefix(phrase) {
                result = String(result.dropFirst(phrase.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return result
    }
}
