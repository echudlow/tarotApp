//
//  TarotAPI.swift
//  Tarot
//
//  Created by Elijah Hudlow on 12/12/25.
//

import Foundation

struct TarotAPICard: Codable {
    let name: String
    let position: String
    let isReversed: Bool
    let uprightMeaning: String
    let reversedMeaning: String
    let suit: String?
    let arcana: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case position
        case suit
        case arcana
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

struct TarotService {
    // For now: local FastAPI server
    // Later: deployed URL
    let baseURL = URL(string: "http://localhost:8000")!
    
    func interpretSpread(_ body: SpreadRequestBody) async throws -> SpreadResponseBody {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("interpret_spread")
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(
                domain: "TarotService",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Server returned error: \(bodyString)"]
            )
        }
        return try JSONDecoder().decode(SpreadResponseBody.self, from: data)
    }
}
