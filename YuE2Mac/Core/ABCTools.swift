//
//  ABCTools.swift — light-weight helpers for the ABC score YuE2 already saves
//  next to every song (analysis §B): structural validation before a re-render,
//  and the official instrumental recipe — move every Vocal note to the Ins
//  voice — which is far more robust than prompt injection.
//

import Foundation

enum ABCTools {
    // MARK: Validation

    struct Summary: Equatable {
        var notes: Int
        var bars: Int
        var voices: [String]
        var problems: [String]

        var isPlausible: Bool { problems.isEmpty && notes > 0 }
    }

    /// A quick, dependency-free sanity check. Not a full ABC parser — it catches
    /// the editing accidents (deleted key line, truncated score, zero notes).
    static func summary(_ abc: String) -> Summary {
        var problems: [String] = []
        let lines = abc.components(separatedBy: .newlines)

        let hasX = lines.contains { $0.hasPrefix("X:") }
        let hasK = lines.contains { $0.trimmingCharacters(in: .whitespaces).hasPrefix("K:") }
        if !hasX { problems.append("Missing the “X:” header line.") }
        if !hasK { problems.append("Missing the “K:” key line — the model won't know the key.") }

        // Note heads: a letter a–g/A–G not glued to other letters (skips "K:", "Voice"…).
        // ICU regex via NSRegularExpression — lookbehind isn't available in Swift Regex literals.
        let notes = matchCount(abc, pattern: #"(?<![A-Za-z])[a-gA-G](?![A-Za-z])"#)
        if notes == 0 { problems.append("No musical notes found.") }

        // Bar lines: count '|' in pure music lines.
        let bars = lines.reduce(0) { count, line in
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.isEmpty || t.hasPrefix("%") || t.contains(":") { return count }
            return count + line.filter { $0 == "|" }.count
        }

        let voices: [String] = lines.compactMap { line in
            guard let m = line.firstMatch(of: #/^V:\s*(\w+)/#) else { return nil }
            return String(m.1)
        }

        let quotes = abc.filter { $0 == "\"" }.count
        if quotes % 2 != 0 { problems.append("Unbalanced quotation mark in chord symbols.") }

        return Summary(notes: notes, bars: bars, voices: voices, problems: problems)
    }

    /// Compare an edited score against its original: warns when the edit went
    /// beyond safe tweaks (the invariant idea from the official editing docs).
    static func changeWarning(original: String, edited: String) -> String? {
        let a = summary(original), b = summary(edited)
        guard a.notes > 0, b.notes > 0 else { return nil }
        let noteDelta = abs(Double(b.notes - a.notes)) / Double(a.notes)
        let barDelta = a.bars > 0 ? abs(Double(b.bars - a.bars)) / Double(a.bars) : 0
        if noteDelta > 0.25 || barDelta > 0.15 {
            return "Structure changed a lot (\(a.notes)→\(b.notes) notes, \(a.bars)→\(b.bars) bars). The re-render may drift from your lyrics."
        }
        return nil
    }

    // MARK: Instrumental (official YuE2 recipe: Vocal → Ins)

    /// Rewrites the score so every sung note is played by the Ins (instrument)
    /// voice — the official YuE2 instrumental recipe. YuE2 scores declare voices
    /// like `V: Vocal clef=treble name="Vocal Melody" snm="Vocal"` and switch
    /// sections in the body with bare `V: Vocal` lines; both are renamed.
    static func makeInstrumental(_ abc: String) -> String {
        let voiceRegex = try? NSRegularExpression(pattern: #"\b(Voice|Vocal)\b"#, options: [.caseInsensitive])
        let lines = abc.components(separatedBy: "\n").map { line -> String in
            let t = line.trimmingCharacters(in: .whitespaces)
            guard t.hasPrefix("V:"), t.uppercased().contains("VOCAL") || t.uppercased().contains("VOICE"),
                  let voiceRegex else { return line }
            let range = NSRange(line.startIndex..., in: line)
            return voiceRegex.stringByReplacingMatches(in: line, options: [], range: range, withTemplate: "Ins")
        }
        return lines.joined(separator: "\n")
    }

    static func isInstrumental(_ abc: String) -> Bool {
        let s = summary(abc)
        let lower = s.voices.map { $0.lowercased() }
        return lower.contains("ins") && !lower.contains("voice") && !lower.contains("vocal")
    }

    // MARK: Helpers

    private static func matchCount(_ text: String, pattern: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        return regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
    }
}
