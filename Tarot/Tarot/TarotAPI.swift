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
    let question: String?
}

struct SpreadResponseBody: Codable {
    let interpretation: String
}

// MARK: - Anthropic response models
struct AnthropicResponse: Codable {
    let content: [AnthropicContent]
    let stop_reason: String?
}

struct AnthropicContent: Codable {
    let type: String
    let text: String
}

// MARK: - TarotService
struct TarotService {

    private let apiKey: String
    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let systemPrompt = "You are an experienced tarot reader speaking directly to someone. Be warm, honest, and grounded. You can be poetic when it fits naturally, but avoid cliches, filler phrases, and anything that sounds like a chatbot. Speak like a real person who genuinely knows this card. Do not use em dashes in your writing. Use commas, periods, or just start a new sentence instead. Follow the formatting rules exactly. Try to sound as little like AI as possible."

    init() {
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let key = dict["ANTHROPIC_API_KEY"] as? String {
            self.apiKey = key
        } else {
            fatalError("Missing Config.plist or ANTHROPIC_API_KEY")
        }
    }
    
    private func stripDashes(_ text: String) -> String {
        text.components(separatedBy: "\n").map { line in
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("**") {
                // header line, keep it readable
                return line.replacingOccurrences(of: " — ", with: " - ")
                           .replacingOccurrences(of: "—", with: "-")
            } else {
                return line.replacingOccurrences(of: " — ", with: ", ")
                           .replacingOccurrences(of: "—", with: ", ")
            }
        }.joined(separator: "\n")
    }
    
    private func makeRequest(_ body: SpreadRequestBody, stream: Bool) throws -> URLRequest {
        let requestBody: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 700,
            "stream": stream,
            "system": systemPrompt,
            "messages": [["role": "user", "content": buildPrompt(body)]]
        ]
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        return request
    }

    func interpretSpread(_ body: SpreadRequestBody) async throws -> SpreadResponseBody {
        let request = try makeRequest(body, stream: false)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(domain: "TarotService", code: http.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "API error: \(body)"])
        }

        let decoded = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        if decoded.stop_reason == "max_tokens" {
            print("[warn] \(body.spread_type) hit max_tokens, the reading was cut off")
        }
        let text = decoded.content.first?.text ?? "I couldn't interpret this spread right now."

        return SpreadResponseBody(interpretation: normalizeOutput(body, text: text))
    }
    
    func streamSpread(_ body: SpreadRequestBody,
                      onUpdate: @MainActor @Sendable (String) -> Void) async throws -> SpreadResponseBody {
        let started = Date()
        let request = try makeRequest(body, stream: true)
        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            var errorText = ""
            for try await line in bytes.lines { errorText += line }
            throw NSError(domain: "TarotService", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "API error: \(errorText)"])
        }
        
        var gotFirst = false
        var full = ""

        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            guard let data = String(line.dropFirst(6)).data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = obj["type"] as? String else { continue }

            switch type {
            case "content_block_delta":
                if let delta = obj["delta"] as? [String: Any], let piece = delta["text"] as? String {
                    if !gotFirst {
                        gotFirst = true
                        print("[timing] \(body.spread_type) first text after \(String(format: "%.1f", Date().timeIntervalSince(started)))s")
                    }
                    full += piece
                    onUpdate(stripDashes(full))
                }
            case "message_delta":
                if let delta = obj["delta"] as? [String: Any],
                   delta["stop_reason"] as? String == "max_tokens" {
                    print("[warn] \(body.spread_type) hit max_tokens, the reading was cut off")
                }
            case "error":
                throw NSError(domain: "TarotService", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Stream error"])
            default:
                break
            }
        }

        return SpreadResponseBody(interpretation: normalizeOutput(body, text: full))
    }

    // MARK: - Prompt building
    private func buildPrompt(_ req: SpreadRequestBody) -> String {
        let isDaily = req.spread_type == "daily" || req.cards.count == 1
        let isQuestion = req.spread_type == "question"

        if isDaily, let c = req.cards.first {
            let orientation = c.isReversed ? "Reversed" : "Upright"
            let meaning = c.isReversed ? c.reversedMeaning : c.uprightMeaning
            return """
            Write a daily tarot interpretation. Speak directly to the person - be specific, grounded, and conversational. A little poetic is fine.

            STRICT RULES:
            - Do NOT sound like AI.
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

        if isQuestion, let question = req.question {
            var lines = [
                "You are a tarot reader. The seeker has asked a specific question. Interpret each card in direct relation to their question.",
                "",
                "THE QUESTION: \"\(question)\"",
                "",
                "STRICT RULES:",
                "- Do NOT sound like AI",
                "- Speak directly to the seeker.",
                "- Every card interpretation must relate back to their specific question.",
                "- You can be poetic but stay grounded and specific.",
                "- Do NOT include greetings or filler.",
                "- For EACH card output exactly one section in this format:",
                "  **<Position> - <Card Name> (<Upright/Reversed>):**",
                "  <1 paragraph interpretation>",
                "- End with:",
                "  **The Answer:**",
                "  <1 clear paragraph directly answering the question based on all 5 cards>",
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
        
        if req.spread_type == "read_me" {
            var lines = [
                "You are a tarot reader with the energy of a fabulous, flamboyant drag mentor who has seen it all and is not here to waste anyone's time. Think the warmth and wisdom of RuPaul combined with the sharp eye and emotional honesty of Michelle Visage - big, expressive, a little extra, and always coming from a place of love. You build people up when the cards call for it and you lovingly but firmly call them out when they need to hear it. You are never cruel, but you are always honest and a little dramatic about it. When something is working, you celebrate it like it deserves to be celebrated. When something needs work, you name it clearly, tell them what to do about it, and send them off feeling like they just had a moment. Your tone is warm, direct, theatrical, and always in service of the seeker winning.",
                "",
                "STRICT RULES:",
                "- Do NOT sound like AI",
                "- Do NOT include greetings or filler.",
                "- Do NOT use em dashes.",
                "- Do NOT use drag-specific catchphrases.",
                "- For EACH card output exactly one section in this format:",
                "  **<Position> - <Card Name> (<Upright/Reversed>):**",
                "  <1 paragraph - honest, warm, direct, and a little theatrical>",
                "- End with:",
                "  **The Verdict:**",
                "  <1 paragraph that ties it together - send them off feeling seen and ready>",
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
        
        if req.spread_type == "clarity" {
            var lines = [
                "You are a tarot reader doing a Clarity Spread. Card 1 is the overall situation - the most powerful card, the anchor of the reading. Cards 2, 3, and 4 are contributing factors that flesh out the narrative in no particular order of importance. Speak directly to the seeker. Be grounded, clear, and insightful.",
                "",
                "STRICT RULES:",
                "- Do NOT sound like AI",
                "- Do NOT include greetings or filler.",
                "- For card 1 output:",
                "  **The Situation - <Card Name> (<Upright/Reversed>):**",
                "  <1-2 paragraphs - this is the heart of the reading>",
                "- For cards 2-4 output:",
                "  **Contributing Factor - <Card Name> (<Upright/Reversed>):**",
                "  <1 paragraph each>",
                "- End with:",
                "  **The Bigger Picture:**",
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

        var lines = [
            "Interpret the following tarot spread. Speak directly to the person.",
            "",
            "STRICT RULES:",
            "- Do NOT sound like AI",
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
        var result = stripDashes(text).trimmingCharacters(in: .whitespacesAndNewlines)
        let fillerPhrases = ["Certainly!", "Sure!", "Of course!", "Absolutely!", "Okay!", "Alright!"]
        for phrase in fillerPhrases {
            if result.hasPrefix(phrase) {
                result = String(result.dropFirst(phrase.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return result
    }
}
