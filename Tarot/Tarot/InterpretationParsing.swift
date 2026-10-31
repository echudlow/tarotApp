//
//  InterpretationParsing.swift
//  The Read
//
//  Created by Elijah Hudlow on 10/31/26.
//

import Foundation

struct InterpretationSection: Identifiable {
    let id = UUID()
    let header: String
    let body: String
}

func parseInterpretationSections(_ text: String) -> [InterpretationSection] {
    var sections: [InterpretationSection] = []
    var header: String? = nil
    var bodyLines: [String] = []

    func flush() {
        if let h = header {
            let body = bodyLines.joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            sections.append(InterpretationSection(header: h, body: body))
        }
        bodyLines = []
    }

    for raw in text.components(separatedBy: "\n") {
        let line = raw.trimmingCharacters(in: .whitespaces)
        if line.hasPrefix("**") && line.hasSuffix("**") && line.count > 4 {
            flush()
            header = line
                .replacingOccurrences(of: "**", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: ": "))
        } else {
            bodyLines.append(raw)
        }
    }
    flush()
    return sections
}
