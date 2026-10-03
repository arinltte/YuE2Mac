//
//  Presets.swift — bundled (non-AI) starter lyric sets the user can load with
//  one click. Style starters live in StyleCatalog.swift now (curated +
//  categorized). Keeping them in plain arrays keeps the app lightweight and offline.
//

import Foundation

enum Presets {
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