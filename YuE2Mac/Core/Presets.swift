//
//  Presets.swift — bundled (non-AI) starter prompts & lyric sets the user can
//  shuffle/load. Keeping them in plain arrays keeps the app lightweight and offline.
//

import Foundation

enum Presets {
    /// Starter style prompts. The shuffle button in the UI cycles through these.
    static let styles: [String] = [
        "English, indie pop, warm lead vocal, bright acoustic guitar, soft drums",
        "English, lo-fi, mellow, vinyl warmth, gentle piano, light tape hiss",
        "English, dream pop, airy vocals, lush reverb, shimmering synths",
        "English, bedroom folk, intimate vocal, fingerpicked guitar, close mic",
        "English, soft rock, 70s feel, smooth bass, electric piano, brushed drums",
        "English, cinematic, sparse, piano and strings, emotional build",
        "English, bossa nova, relaxed, nylon guitar, soft percussion",
        "English, synthwave, retro, driving bassline, gated reverb, bright lead",
        "English, r&b, soulful vocal, warm keys, subtle groove, tight drums",
        "English, acoustic singer-songwriter, gentle, heartfelt, roomy reverb",
    ]

    struct LyricSet {
        let name: String
        let text: String
    }

    /// Starter lyric sets the user can load with one click.
    static let lyrics: [LyricSet] = [
        LyricSet(name: "Golden Hour", text: """
        [Verse]
        Golden hour on the avenue
        Soft shadows stretch, the day turns blue

        [Chorus]
        Stay a little longer, hold on through
        The sun keeps slipping, but so do we

        [Verse]
        You left your coat on the kitchen chair
        A humming fridge, a summer air

        [Chorus]
        Stay a little longer, hold on through
        The night keeps coming, but so do we

        [Outro]
        Stay a little longer…
        """),

        LyricSet(name: "Coastline", text: """
        [Verse]
        Salt on the breeze, sand in my shoes
        We drove the coast with nothing to lose

        [Chorus]
        Take me to the waterline again
        Where the waves forget the shore

        [Verse]
        Radio hums an old refrain
        Two dollar coffee, souvenir rain

        [Chorus]
        Take me to the waterline again
        Where the waves forget the shore
        """),

        LyricSet(name: "Late Bloomer", text: """
        [Verse]
        I took my time, I took the slow lane
        Learned to love the quiet rain

        [Chorus]
        I bloomed when nobody was watching
        Good things come late, and that's okay

        [Verse]
        All my once-upons grew roots at last
        I stopped replaying failed takes from the past

        [Chorus]
        I bloomed when nobody was watching
        Good things come late, and that's okay
        """),

        LyricSet(name: "Night Drive", text: """
        [Verse]
        Streetlamps blink, the engine hums
        We chase the glow where the city becomes

        [Chorus]
        On a night drive, counting miles of light
        Windows down, we fade into tonight

        [Verse]
        Every corner holds a memory's song
        We sing along 'til the signal is gone

        [Chorus]
        On a night drive, counting miles of light
        Windows down, we fade into tonight
        """),

        LyricSet(name: "Instrumental Only", text: """
        [Intro]
        [Instrumental]

        [Verse]
        [Instrumental]

        [Chorus]
        [Instrumental]

        [Outro]
        """),
    ]
}