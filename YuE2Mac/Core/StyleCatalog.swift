//
//  StyleCatalog.swift — curated, blendable style presets in pure Swift.
//  Replaces the old 10-string starter list: LITE shows friendly chips,
//  PRO gets the full category browser. Prompts carry the voice/timbre
//  detail the model responds to (analysis §2.D.4).
//

import Foundation

struct StylePreset: Identifiable, Equatable {
    let id: String          // stable id = name
    let name: String
    let emoji: String
    let category: String
    let prompt: String

    /// Presets surfaced as one-tap chips in LITE mode (curated, diverse).
    static let litePicks = ["Indie Pop", "Lo-fi", "Dream Pop", "Soft Rock", "Synthwave", "Cinematic", "Bossa Nova", "Acoustic Folk"]
}

enum StyleCatalog {
    static let categories = [
        "Popular", "Chill", "Rock", "Electronic", "Jazz & Soul",
        "Cinematic", "Global", "Songbook",
    ]

    static let presets: [StylePreset] = [
        // Popular
        StylePreset(id: "Indie Pop", name: "Indie Pop", emoji: "🎤", category: "Popular",
                    prompt: "English, indie pop, warm lead vocal, bright acoustic guitar, soft drums"),
        StylePreset(id: "Dream Pop", name: "Dream Pop", emoji: "☁️", category: "Popular",
                    prompt: "English, dream pop, airy female vocal, lush reverb, shimmering synths, slow tempo"),
        StylePreset(id: "Synthwave", name: "Synthwave", emoji: "🌆", category: "Popular",
                    prompt: "English, synthwave, retro 80s, driving bassline, gated reverb, bright synth lead, male baritone vocal"),
        StylePreset(id: "Pop Anthem", name: "Pop Anthem", emoji: "🎆", category: "Popular",
                    prompt: "English, stadium pop anthem, powerful belting female vocal, huge chorus, punchy drums, layered synths"),
        StylePreset(id: "R&B Soul", name: "R&B Soul", emoji: "💜", category: "Popular",
                    prompt: "English, r&b, soulful vocal, warm keys, subtle groove, tight drums, smooth bass"),

        // Chill
        StylePreset(id: "Lo-fi", name: "Lo-fi", emoji: "📼", category: "Chill",
                    prompt: "English, lo-fi, mellow, vinyl warmth, gentle piano, light tape hiss, soft spoken-word vocal"),
        StylePreset(id: "Bedroom Folk", name: "Bedroom Folk", emoji: "🛏️", category: "Chill",
                    prompt: "English, bedroom folk, intimate vocal, fingerpicked guitar, close mic, minimal percussion"),
        StylePreset(id: "Acoustic Folk", name: "Acoustic Folk", emoji: "🪕", category: "Chill",
                    prompt: "English, acoustic singer-songwriter, gentle, heartfelt, roomy reverb, guitar and light strings"),
        StylePreset(id: "Bossa Nova", name: "Bossa Nova", emoji: "🌴", category: "Chill",
                    prompt: "English, bossa nova, relaxed, nylon guitar, soft percussion, breathy female vocal"),
        StylePreset(id: "Late-Night Jazz", name: "Late-Night Jazz", emoji: "🍸", category: "Chill",
                    prompt: "English, late-night jazz bar, brushed drums, upright bass, smoky male vocal, piano trio"),
        StylePreset(id: "Ambient Pop", name: "Ambient Pop", emoji: "🌙", category: "Chill",
                    prompt: "English, ambient pop, ethereal female vocal, pads, sparse piano, long reverb tails"),

        // Rock
        StylePreset(id: "Soft Rock", name: "Soft Rock", emoji: "🚗", category: "Rock",
                    prompt: "English, soft rock, 70s feel, smooth bass, electric piano, brushed drums, warm tenor vocal"),
        StylePreset(id: "Garage Rock", name: "Garage Rock", emoji: "🎸", category: "Rock",
                    prompt: "English, garage rock, raw energy, distorted guitars, energetic male vocal, live band feel"),
        StylePreset(id: "Punk Burst", name: "Punk Burst", emoji: "⚡️", category: "Rock",
                    prompt: "English, pop-punk, fast, punchy power chords, youthful shouted vocals, tight drums"),
        StylePreset(id: "Metal Edge", name: "Metal Edge", emoji: "🤘", category: "Rock",
                    prompt: "English, melodic metal, heavy palm-muted guitars, growled verses, soaring clean chorus, double kick"),
        StylePreset(id: "Blues Rock", name: "Blues Rock", emoji: "🎺", category: "Rock",
                    prompt: "English, blues rock, gritty male vocal, wailing electric guitar solos, shuffle drums, hammond organ"),

        // Electronic
        StylePreset(id: "House Groove", name: "House Groove", emoji: "🕺", category: "Electronic",
                    prompt: "English, deep house, four-on-the-floor, groovy bassline, filtered female vocal hooks, warm pads"),
        StylePreset(id: "Drum & Bass", name: "Drum & Bass", emoji: "🥁", category: "Electronic",
                    prompt: "English, drum and bass, fast breakbeats, rolling sub-bass, airy female vocal, atmospheric pads"),
        StylePreset(id: "Trip Hop", name: "Trip Hop", emoji: "🕶️", category: "Electronic",
                    prompt: "English, trip hop, slow head-nod groove, moody samples, husky female vocal, dusty vinyl drums"),
        StylePreset(id: "Future Bass", name: "Future Bass", emoji: "🛸", category: "Electronic",
                    prompt: "English, future bass, supersaw chords, vocal chops, punchy sidechain drums, euphoric drops"),
        StylePreset(id: "Euro Dance", name: "Euro Dance", emoji: "💃", category: "Electronic",
                    prompt: "English, euro dance, 90s piano house, diva vocal, energetic tempo, catchy hook"),

        // Jazz & Soul
        StylePreset(id: "Soul Ballad", name: "Soul Ballad", emoji: "🕯️", category: "Jazz & Soul",
                    prompt: "English, soul ballad, gospel-tinged female vocal, slow groove, organ, swelling strings"),
        StylePreset(id: "Swing Jazz", name: "Swing Jazz", emoji: "🎷", category: "Jazz & Soul",
                    prompt: "English, swing jazz, big band brass, walking bass, playful scat vocal, bright tempo"),
        StylePreset(id: "Funk Party", name: "Funk Party", emoji: "🕺🏿", category: "Jazz & Soul",
                    prompt: "English, funk, slap bass, tight rhythm guitar, horn stabs, charismatic male vocal, party energy"),
        StylePreset(id: "Gospel Choir", name: "Gospel Choir", emoji: "🙏", category: "Jazz & Soul",
                    prompt: "English, gospel, uplifting choir harmonies, piano, hand claps, powerful lead vocal"),

        // Cinematic
        StylePreset(id: "Cinematic", name: "Cinematic", emoji: "🎬", category: "Cinematic",
                    prompt: "English, cinematic, sparse, piano and strings, emotional build, wordless female vocal"),
        StylePreset(id: "Epic Trailer", name: "Epic Trailer", emoji: "🏔️", category: "Cinematic",
                    prompt: "English, epic orchestral trailer, thunderous percussion, brass, choir, heroic female vocal"),
        StylePreset(id: "Game Score", name: "Game Score", emoji: "🎮", category: "Cinematic",
                    prompt: "English, adventure game soundtrack, playful woodwinds, heroic brass theme, light percussion"),
        StylePreset(id: "Noir", name: "Noir", emoji: "🕵️", category: "Cinematic",
                    prompt: "English, film noir, muted trumpet, walking bass, mysterious smoky female vocal, rain ambience"),

        // Global
        StylePreset(id: "Latin Pop", name: "Latin Pop", emoji: "🌶️", category: "Global",
                    prompt: "Spanish, latin pop, reggaeton groove, nylon guitar, flirtatious female vocal, sunny energy"),
        StylePreset(id: "City Pop", name: "City Pop", emoji: "🏙️", category: "Global",
                    prompt: "Japanese, city pop, 80s funk, funky bassline, brass stabs, smooth female vocal, shiny production"),
        StylePreset(id: "K-Ballad", name: "K-Ballad", emoji: "🇰🇷", category: "Global",
                    prompt: "Korean, emotional ballad, tender female vocal, piano, sweeping strings, dramatic final chorus"),
        StylePreset(id: "Mandopop", name: "Mandopop", emoji: "🏮", category: "Global",
                    prompt: "Mandarin, mandopop, sweet female vocal, bright synth pop, modern production, catchy chorus"),
        StylePreset(id: "Afrobeat", name: "Afrobeat", emoji: "🪘", category: "Global",
                    prompt: "English, afrobeat, syncopated percussion, warm bass groove, joyful male vocal, sunny horns"),

        // Songbook (the original starters, kept for continuity)
        StylePreset(id: "Studio Classic", name: "Studio Classic", emoji: "✨", category: "Songbook",
                    prompt: "English, indie pop, bright acoustic guitar, soft drums, warm lead vocal"),
        StylePreset(id: "Tape Warmth", name: "Tape Warmth", emoji: "🎹", category: "Songbook",
                    prompt: "English, lo-fi, mellow, vinyl warmth, gentle piano, light tape hiss"),
        StylePreset(id: "Ether", name: "Ether", emoji: "🌫️", category: "Songbook",
                    prompt: "English, dream pop, airy vocals, lush reverb, shimmering synths"),
        StylePreset(id: "Campfire", name: "Campfire", emoji: "🔥", category: "Songbook",
                    prompt: "English, bedroom folk, intimate vocal, fingerpicked guitar, close mic"),
        StylePreset(id: "Seventies", name: "Seventies", emoji: "📻", category: "Songbook",
                    prompt: "English, soft rock, 70s feel, smooth bass, electric piano, brushed drums"),
        StylePreset(id: "Score Sketch", name: "Score Sketch", emoji: "🎼", category: "Songbook",
                    prompt: "English, cinematic, sparse, piano and strings, emotional build"),
        StylePreset(id: "Retro Drive", name: "Retro Drive", emoji: "🛣️", category: "Songbook",
                    prompt: "English, synthwave, retro, driving bassline, gated reverb, bright lead"),
        StylePreset(id: "Velvet Groove", name: "Velvet Groove", emoji: "🎤🩰", category: "Songbook",
                    prompt: "English, r&b, soulful vocal, warm keys, subtle groove, tight drums"),
        StylePreset(id: "Storyteller", name: "Storyteller", emoji: "📖", category: "Songbook",
                    prompt: "English, acoustic singer-songwriter, gentle, heartfelt, roomy reverb"),
    ]

    static func preset(named name: String) -> StylePreset? {
        presets.first { $0.id == name }
    }

    static func preset(forPrompt prompt: String) -> StylePreset? {
        presets.first { $0.prompt == prompt.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    static func presets(in category: String) -> [StylePreset] {
        presets.filter { $0.category == category }
    }
}
