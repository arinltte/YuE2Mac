//
//  LyricWriter.swift — on-device lyric writing via Apple's FoundationModels
//  (the system model behind Apple Intelligence). Zero network, zero extra
//  dependencies; per-section @Guide constraints keep the small on-device model
//  from repeating itself (the pattern tonywestonuk/YuE-Studio found works).
//  Gracefully unavailable on Macs without Apple Intelligence or below
//  macOS 26 — the UI simply hides the feature.
//

import Foundation
import FoundationModels

enum LyricWriter {
    enum WriterError: LocalizedError {
        case unavailable
        var errorDescription: String? {
            switch self {
            case .unavailable: return "On-device lyric writing isn't available on this Mac."
            }
        }
    }

    /// True when the system model is ready to use right now.
    static var isAvailable: Bool {
        guard #available(macOS 26.0, *) else { return false }
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    /// Write a full lyric sheet (verse/chorus/verse/chorus/bridge/outro).
    static func write(idea: String, mood: String) async throws -> String {
        guard #available(macOS 26.0, *) else { throw WriterError.unavailable }
        return try await writeSections(idea: idea, mood: mood)
    }

    @available(macOS 26.0, *)
    private static func writeSections(idea: String, mood: String) async throws -> String {
        let session = LanguageModelSession(instructions: """
            You are a concise, vivid songwriter for a short AI-generated song \
            (about 2 minutes). Write plain, singable lines — no section labels, \
            no markdown, no explanations. Keep rhymes natural and imagery concrete.
            """)
        let prompt = """
            Write lyrics for a \(mood) song about: \(idea).
            Keep every section short — the model sings roughly what you give it.
            """
        let response = try await session.respond(to: prompt, generating: SongSections.self)
        return format(response.content)
    }

    @available(macOS 26.0, *)
    private static func format(_ s: SongSections) -> String {
        [
            "[Verse]", s.verseOne, "",
            "[Chorus]", s.chorus, "",
            "[Verse]", s.verseTwo, "",
            "[Chorus]", s.chorus, "",
            "[Bridge]", s.bridge, "",
            "[Outro]", s.outro,
        ].joined(separator: "\n")
    }
}

/// Guided per-section generation — each field gets its own guide so the model
/// doesn't blend sections together or repeat one hook four times.
@available(macOS 26.0, *)
@Generable
struct SongSections {
    @Guide(description: "The first verse: 2-4 short concrete lines that set the scene")
    var verseOne: String

    @Guide(description: "The chorus: a catchy 2-4 line hook that repeats well")
    var chorus: String

    @Guide(description: "The second verse: 2-4 new lines that develop the story")
    var verseTwo: String

    @Guide(description: "A bridge: 1-3 lines offering a twist or new angle")
    var bridge: String

    @Guide(description: "An outro: 1-2 fading farewell lines")
    var outro: String
}
