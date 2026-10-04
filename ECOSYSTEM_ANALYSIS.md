# Ecosystem Feature Analysis — awesome-YuE repos as reference for YuE2Mac

> **Purpose:** Analysis of all 63 GitHub repos listed in `awesomeYuE README_EN.md` (everything except `arinltte/YuE2Mac` itself, which is this project). All repos were cloned temporarily into `.awesome-repos-tmp/` for analysis and have been removed afterwards.
> **Method:** shallow clone → README/docs/source review → feature extraction mapped against YuE2Mac's feature set. Nothing was built or run.
> **Date:** October 2025 (list header says "Last updated 2026-09-26").
> **Status:** **Tier 1 of the roadmap shipped in v0.2.0** and was verified end-to-end (engine test + full app-path test + Release build). This document now serves as the **forward roadmap**; the deep dives in §1 are kept as implementation references for the remaining items.

---

## 0. What shipped in v0.2.0 (Tier 1 complete)

All nine Tier-1 items are implemented and verified:

| Shipped | Notes |
|---|---|
| **LITE / PRO two-mode UI** | toolbar switch; lyrics/style/results carry over between modes |
| **Queue** | many jobs, one render at a time, live stage chips (Load→Plan→Compose→Refine→Render→Save), tok/s readout, instant cancel of queued jobs, honest *Stopped* labels |
| **Song library** | timestamped folders, `song.json` sidecar (seed/settings/kind), search, replay, M4A export via `afconvert`, new-variation retakes, delete; old loose `.wav` files still listed |
| **Saved artifacts** | `song.abc`, `song.tokens.json` (song project), `song.latents.npy` beside each WAV |
| **ABC score editing** | validate (notes/bars/voices), big-change warning, same-seed re-render, **Vocal→Ins** instrumental rewrite |
| **Draft → Finish** | 8-step draft; *Finish at full quality* re-renders the same take (saved tokens + seed) at 32 steps |
| **Style catalog** | ~40 curated starters in categories; chips in Lite, browser in Pro, shuffle |
| **Advanced sampling** | temperature / top-p / top-k / repetition penalty, one-click reset, "custom" badge |
| **On-device lyrics** | Apple FoundationModels with per-section `@Generable` guides (macOS 26+, Apple Intelligence; hidden otherwise) |

**Still not present (the forward roadmap, §2/§4):** covers/transcription/hum, score-conditioned input, piano-roll editor, persistent worker, FLAC/MP3/ZIP export, projects/albums, LoRA adapters, karaoke alignment, mastering, long-song chunking.

---

## 1. The most valuable reference repos (deep dives)

### 1.1 `tonywestonuk/YuE-Studio` — the closest native-Mac sibling ⭐⭐⭐
A native SwiftUI macOS app around the same upstream pipeline, with a **long-lived Python worker** (`tools/yue2_worker.py`) exchanging **JSON lines over stdin/stdout**, so the model loads once. Highlights directly transferable:

| Feature | Evidence | YuE2Mac relevance |
|---|---|---|
| **Queue with 4 visible stages** (Planning → Tokenizing → Synthing → Rendering) with live per-stage throughput (tok/s, GFLOP/s) | `Song.swift` status enum + `Backend.swift` JSON protocol | YuE2Mac already parses stages; making the engine persistent + queueing is the single biggest UX/throughput win |
| **Draft → Full-quality render split** | draft = 8 solver steps on GPU; "Render full quality" reuses the *same tokens and seed* at 32 steps | The engine already emits tokens before NAR; saving semantic tokens lets a cheap 8-step draft be "finished" later at full quality — smittyPNW and ianiv do the same thing |
| **Hum a melody** | Record 10–30 s → SheetSage2 transcription → choose "exactly my hum" or **"continue from it"** (`abc_open=True`, planner writes the rest around your opening) | Distinctive, very demo-able feature; `HumSheetView.swift` is a complete reference implementation |
| **iPhone as second Neural Engine** | `app/YuERemote` iOS companion; 2.8 GB synthesis weights streamed once; two songs synthesize concurrently (Mac + phone) | Ambitious but a genuinely unique selling point on this platform |
| **Neural Engine synthesis** | flow-matching net compiled to ANE via private in-memory MIL route (`src/yue2/ane/libyue2ane.m`), ~2× GPU on short songs; one program per length bucket | Advanced perf reference with full measurements |
| **Batched AR decoding** | `src/yue2/batched.py` + two MPS patches (flatten `[B,1,H]` Linear to 2D; broadcast-matmul attention instead of per-row K/V copies) — 14 → **73 aggregate tok/s** at batch 8, because weight reads are shared | Concrete recipe if YuE2Mac ever queues multiple songs |
| **On-device lyric writing** | `TitleSuggester.swift` uses Apple **FoundationModels** (`@Generable` struct with per-section `@Guide` constraints) to write verse/chorus/bridge/outro on-device (macOS 26 + Apple Intelligence) | Perfect fit for a native Mac app — no Python, no cloud, Apple-native |
| **Memory tuning for 16 GB Macs** | `docs/apple-silicon.md` footprint tables; ANE address-window constraints (~3.5 GiB/program) | Directly applicable hardware guidance |

### 1.2 `vanch007/mlx-Yue` — the torch-free MLX runtime YuE2Mac-style ports descend from ⭐⭐⭐
- **All five generation modes** incl. *supplied ABC score* (condition on user's own notation — YuE2Mac has no score input today).
- **Native MLX transcription**: SheetSage2 + MERT2 in MLX, audio → ABC/MIDI/LAB, multi-window stitching for arbitrarily long sources.
- **8-bit AR quantization**: 4.33 → 2.66 GB, 59 → 83 tok/s; **8-step "fast mode" reaches <1.0 RTF** (faster than realtime) on M3 Max.
- **Steel SDPA FP32-accumulator**: synthesis 363 s → 187 s, bit-identical latents.
- **Resource guard**: sampled memory budget (footprint), swap-out detection, abort before thrashing — with stavitian's patch below.
- End-to-end **cover pipeline**: transcribe → melody/structure → resynthesize in new style.

### 1.3 `stavitian/yue2-studio` — native app + installer + 24 GB-Mac fixes ⭐⭐⭐
- Architecture: `YuE2 Studio.app` (Swift + WKWebView) supervising a **stdlib-only local HTTP server** (`server.py`, job queue, progress parsing, **Range-capable audio serving**, MP3 export, library) over the mlx-Yue CLI.
- **24 GB Mac patches** (genuinely useful bug knowledge): upstream's guard aborts on *transient* macOS memory-pressure warnings during weight-load bursts — the patch tolerates pressure while ≥N GiB free and counts warnings as metadata; transcription default memory budget derived from actual RAM.
- CLI flags worth adopting: `--precision 8bit`, `--vae-core-frames 128` (tiled VAE decode), `--memory-budget-gib`, `MLX_ENABLE_TF32=0`.
- Idempotent, re-runnable installer with `install.sh --check`; hardware gating (M1–M4 vs M5 macOS version).
- Benchmarks on M5 Pro/24 GB: 3:20 song in 337 s (RTF 1.68); 1:16 in 8 steps in 47 s (**RTF 0.62**); transcription of 16 s in 5.7 s.

### 1.4 `ianiv/YuE2` — the best *product design* reference (local MLX web app) ⭐⭐⭐
- **Stage chips** on every job card (Load → Plan → Semantic → Synthesize → Decode → Save) with tokens/s, elapsed, ETA; **score rendered live while it's being planned**.
- **Queue**: one GPU job at a time; queued jobs cancel instantly, running jobs stop at the next token/step/chunk; waiting jobs survive server restarts; a running job killed by a restart is *honestly labeled* and re-submittable.
- **Library**: kind badges (`CREATE / REGENERATE / COVER / HUM`), variation groups (`VAR 2/3`), **project tracks** (`Summer Nights EP › Harbour Lights`, ★ chosen take), duration, "made in" with per-stage split + RTF, preset/seed/mode, **FLAC/MP3/ZIP downloads** (MP3 transcoded on demand), search across title/style/lyrics, filters, multi-select → delete / add to project.
- **Cover wizard**: drop file (≤200 MB, any common format) or reuse recent upload; clip start/end; task = melody→full (recommended) / melody→vocal / full transcription; **"Continue from the clip"** mode (trailing rests trimmed, planner continues the open score, 15–30 s clip works best).
- **Hum page**: in-browser recording; "Continue my melody" (hum becomes the hook) / "Hum is the whole melody" / "Ignore the notes" + **prosody adapter** (`hum_adapter_v1_combined.safetensors`) with **Hum influence** (0–3) and **Hum starts at** (offset) controls.
- **LoRA adapters**: drop files into `models/loras/`, rescanned every 5 s, two layouts (HF safetensors / PEFT dir), AR (planner) vs NAR (decoder) kinds, `lora_scale` metadata honored.
- **Projects**: albums/EPs with named tracks, takes rated and starred, "New take" menus from Create/Cover/Hum pre-fill the banner.

### 1.5 `VincentGourbin/yue2-mlx-swift` — a full Swift/MLX port, no Python at inference ⭐⭐⭐
- Whole pipeline in Swift (`YuE2Core`), published on the **App Store as PocketAnthem for iPhone** — a full song generated *entirely on an A17 Pro* with a 2.5 GB 4-bit pack. Proves a no-Python future for YuE2Mac is realistic.
- **Stage-scoped residency** (only the current stage's weights resident), **per-step checkpoints** (resumable synthesis), **GPU gate** (survive losing the GPU when backgrounded), VAE backend choice.
- Seven measured reference configs; prequantized packs on HF; `plan / semantic / synthesize / decode` CLI stages each resumable; artifacts incl. `trace.json`.

### 1.6 `smittyPNW/YuE-Studio` — native app + **editor** + **mastering** ⭐⭐
- **Draft vs Full**: full 32-step quality stays default; Draft is an explicit 8-step preview; a draft's saved composition can be finished with all 32 steps later ("recover useful work", "failed jobs remain visible").
- **Edit workspace**: sample-level selection, cutting/arrangement, fades, crossfades, gain ramps, repair, channel tools, markers, frequency analysis, persistent undo/redo; external recordings importable.
- **Master workspace**: complete JUCE mastering engine — Smart Master recommendations, 43 starting styles, before/after listening, iOS-style one-tap buttons (HiFi · Max Volume · Fix Stereo · More Bass · Clear Mids · Smooth Highs), 24-bit WAV render, private source copies, export never overwrites.
- **Admission gate + file lock**: generation, editing, and mastering share "one heavy job at a time"; the generation worker exits before mastering begins.
- **Songwriter companion** agent skill with source-backed guidance on key/time-signature/BPM/solos/breaks for lyric writing.

### 1.7 Official `multimodal-art-projection/YuE` — the upstream feature contract ⭐⭐⭐
- `SongRequest {style, lyrics, cot, seed, cfg_scale, abc}`; `plan() → generate_semantic() → synthesize() → decode()` **staged API** — plan can be saved, inspected, edited, and rendered later; `SymbolicPlan.load` verifies token IDs.
- **`save_artifacts()`**: audio.flac, score.abc, plan.json, semantic tokens, latent.npy, effective config, timings, model identities, integrity records, `truncated` flags → the definition of a portable "song project" folder.
- **Editing loop** (docs/editing.md): copy score → edit → `abc_tools.py compare` invariant check (notes/timing/meter/section order unchanged, `--allow-tempo-change` option) → render → listen. **Agentic editing**: bounded brief to an LLM agent, then invariant-checked re-render.
- **Cover recipe** (docs/covers.md): SheetSage2 `--melody-only` → review melody/meter/section order → strip chords → `cot=melody` (melody-only recommended because the accompaniment gets freedom); `cot=full` keeps harmony.
- **Instrumental workflow** (skill): move every `Vocal` note to `Ins` in the ABC — *much* more robust than YuE2Mac's current prompt-injection approach.
- Two decoders (listening vs benchmark-legacy) and cached-latent re-decode.

---

## 2. Feature catalog — implementable in YuE2Mac

Organized by theme. Each entry: **what / who does it / how it could land in YuE2Mac.**

### A. Generation UX & workflow

1. **Persistent worker process** (model loads once) — tonywestonuk, ianiv, krakenunbound, stavitian. YuE2Mac's per-song cold start wastes ~30–60 s reloading weights. A JSON-lines stdin/stdout worker keeps the current "unloaded after song" memory story optional (idle worker could self-exit after N minutes — yue2-sidecar's `POST /unload` pattern) instead of mandatory.
2. **Song queue + batch generation** — tonywestonuk ("Songs per run"), Workbench ("queue dozens"), vrgamegirl19 "Surprise me" batch (batch size, vocal gender, style, language). *Shipped in v0.2.0: the queue UI (sequential, one render at a time).* Still open: true batched AR decode, which makes a queue of drafts dramatically cheaper than sequential runs.
3. **Draft → full-quality render** — tonywestonuk (8-step GPU draft → 32-step ANE render reusing tokens+seed), smittyPNW ("Preview, then finish"), mlx-Yue fast mode (RTF < 1.0). *Shipped in v0.2.0: draft(8) → Finish(32) reusing the saved song project.*
4. **Song library with metadata + persistence** — ianiv (badges, search, filters, multi-select), Whiskerwave (searchable libraries), Workbench (per-task unique IDs used as filenames). *Shipped in v0.2.0: timestamped output folders + library with search/replay/M4A/variations.* Still open: multi-select, filters, project tracks.
5. **Variations / regenerate** — ianiv variation groups, ACE-Step "Retake" tab (same request, new seed). *Shipped in v0.2.0: "New variation" retakes from the library.* Still open: grouping retakes into families.
6. **Cancel granularity** — ianiv: queued cancels instantly; running stops at next token/step/chunk. *Shipped in v0.2.0: instant queued-cancel, honest "Stopped" labels.* Still open: keep partial artifacts when requested.
7. **Honest interruption labels & restart recovery** — Workbench (only jobs started before this process may be called "interrupted by restart"; queue state file written atomically), ianiv (waiting jobs re-queued on start).
8. **Long songs via chunk + crossfade** — cicalooo/ComfyUI-YuE2-LongSong: split lyrics/ABC into chunks with a shared-chorus overlap, pad bars, matching cot modes, edge-trim, 2–6 s equal-power crossfade; warns against slicing one ABC into broken halves. YuE2 hard 360 s cap becomes soft.
9. **Export formats** — *M4A shipped in v0.2.0 (native `afconvert`).* Still open: MP3, FLAC, ZIP of the whole song folder (ianiv); nvmax saves MP3 320k / FLAC 16-24 bit.
10. **Project/album organization** — ianiv Projects: named tracks, rated takes, chosen take per track, add-from-library, plays/exports as an album.

### B. The score (ABC) — editing + Vocal→Ins shipped in v0.2.0; score *input*/piano-roll still open

1. **Score-conditioned regeneration**: save the ABC YuE2Mac already writes, let the user edit it (or just tweak tempo/key/sections), validate, re-render. References: official editing.md; ds-yue-webui (browser editor → validate → invariant compare → regenerate); yue2_groove (**freeze baseline → edit → CHECK INVARIANTS → generation refuses to run unless the check passed on the current ABC**, `edit_manifest.json`); YuE2Fast Score Studio (section reorder/duplicate/delete with lyric blocks following, transpose, tempo, bar-length check).
2. **Piano-roll editor** — FL-YuE2 (click to add notes, drag pitch/time/length, snap values, gaps→rests, two voices + chord lane, browser synth preview + metronome), yue2-studio-pc (`pianoroll.js`: dependency-free, narrow lossless ABC dialect, octave buttons), pytraveler (track window). A SwiftUI piano roll is a serious but high-payoff component; a staff-notation preview (abcjs-style) is the lighter alternative (ds-yue-webui).
3. **ABC validation & invariant checks** — official `abc_tools.py inspect/compare`; ScryptHunter: safer transposition/cleanup preserving pitch across key signatures, accidentals, slash chords; key-aware enharmonic chord spelling (A#→Bb in the right key).
4. **Duration budgeting from the score** — ScryptHunter `YuE2 ABC Duration Budget`: derive a semantic-token ceiling from the final ABC incl. tempo changes. Would replace YuE2Mac's blind max-token slider with a smart default when a score is supplied.
5. **Syllable fit-check for new lyrics on a kept melody** — mitnits/yue2-same-music-new-lyrics: transcribe → edit score on canvas → fit-check lyrics → **visual syllable-to-note aligner** (no notation needed) → transpose (octave down / other key) → render; optional language-aware syllable counting.
6. **`semantic_keep` — keep the start of a render, change from a cut** — engival/yue2.cpp SPEC_KEEP: force an earlier render's semantic codes as history and continue sampling from there ("this take is the one; keep it to the cut, change it from there"). Distinct from score-editing: preserves the *performance*, not just the composition.
7. **Score PNG pack** — UnlimitedEditing/ComfyUI-YuE2Fast: lossless M3DS PNG carrying score + style + lyrics + seed (`song.yue2.json`), CRC-checked, re-renderable by dropping it back in. A tidy shareable artifact format.
8. **Edit Track (sample-accurate partial re-render)** — pytraveler/YuE2-ComfyUI: retake a stretch / new words / new notes / cut / move / extend past the end / instrumental break on a finished song; 1–4 takes to choose by ear; everything outside the edit is the old recording to the sample. (Implemented via re-render + sample-accurate assembly.) The most powerful editing feature in the ecosystem.

### C. Covers, transcription, hum, MIDI

1. **Cover wizard** (audio → ABC → new style/lyrics) — official covers.md + ds-yue-webui 3-step wizard (upload → review transcription text + warnings → strip-chords(melody)/keep-chords(full) choice) + ianiv (clip range, task picker, recent uploads). SheetSage2 runs ~5 GiB, transcription of 16 s ≈ 5.7 s on M5 Pro (stavitian).
2. **Hum-to-song** — tonywestonuk (mic record in-app, "exactly my hum" vs "planner continues it"), ianiv (+ prosody adapter: hum influence 0–3, hum offset; "the hummed phrase tends to come back as the hook"), FS_Audio_Suite (hum adapter + melody modes + waveform scrub). Highest-demo-value feature for a Mac app with a built-in mic.
3. **Continue-from-clip** — tonywestonuk `abc_open=True`; ianiv "Continue from the clip" (trailing rests trimmed). Generalizes hum to any recording: *your intro, the model's song*.
4. **MIDI → song** — pytraveler `YuE2 Load MIDI` (`.mid/.midi/.kar/.rmi`, karaoke words included); Whiskerwave ABC/MIDI remixing + **SpessaSynth browser MIDI monitoring** (SoundFont preview, metronome) — a Mac app could preview scores via AVAudioUnitSampler or core MIDI DLS without loading the model.
5. **Vocal/stem separation** — pytraveler `YuE2 Vocals Only` (0.85 GB model); YuE2gen-studio runs **demucs on CPU on purpose** ("stems don't use the GPU — they would fight YuE2 for VRAM"), htdemucs/htdemucs_ft/6s models; krakenunbound same. Useful before RVC, covers of your own voice, or karaoke tracks.
6. **RVC voice conversion** — RevolutionLA/YuE2-Music-Workbench: four artifacts per job (full song w/ accompaniment, converted dry vocals, original vocals, accompaniment), **silence gate** (compress non-vocal segments to −60 dB based on the actual vocal envelope — RVC emits phantom buzz on silence), HP5 de-harmonize option, serial queue with cancel, exact `.index` binding. Heavy (needs a Windows-first stack today) but the *product design* transfers.
7. **Karaoke LRC/eLRC** — Workbench: **forced alignment, not ASR** (known lyrics pressed onto audio): FunASR char-level (Chinese) + wav2vec2 CTC (English) + VAD onset anchors → `.lrc` line-level + `.elrc` word-level. Pair with the in-app player for a karaoke highlight mode. krakenunbound has the same (MMS aligner or Whisper-assisted).
8. **Ableton bridge** — nheegen/yue2-session-bridge: Max for Live device sends Session chord/bass clips + tempo/meter/scale as ABC to a local server, gets audio back into an empty Session slot. A Mac app talking to Ableton Live (OSC/Max) is a niche but unique integration.

### D. LLM-assisted writing (lyrics, style, titles)

1. **On-device writing via Apple FoundationModels** — tonywestonuk `TitleSuggester.swift`: `@Generable` struct with one `@Guide`-described field per section (verse/chorus/bridge/outro) because "guided generation keeps the small on-device model from repeating itself"; falls back gracefully when unavailable. Zero-dependency, Apple-native — **shipped in v0.2.0** (`LyricWriter.swift`).
2. **Writing room with a local LLM** — yue2-mlx.pinokio + Whiskerwave + vrgamegirl19 + krakenunbound: **LM Studio / Ollama / any OpenAI-compatible endpoint**; "Generate Lyrics from Idea", "Generate Style from Idea", "Expand Lyrics" (add verses/bridges), lyric preferences. tio-music-studio: Claude API with **Ollama qwen3:8b fallback** for prompt translation.
3. **Idea → style + lyrics in one shot** — pytraveler `YuE2 Write Song`; Workbench's DeepSeek assistant producing "six-element style tags + structured lyrics"; nvmax `YuE2 LLM Co-Producer` that "formats lyrics, refines rhymes, adds vocal taxonomy, tailors concepts for YuE2".
4. **Style preset libraries** — SongScribe: **73 presets × 14 categories**, detail levels (tags/full/rich), vocal selector, language tag, `blend_with` mixing, free-text extras; nvmax voice taxonomy with explicit range tags (`[voice: warm baritone...] [range: G2-G4]`); 200-tag list from the YuE1 era (`top_200_tags.json`). *Shipped in v0.2.0: ~40-preset categorized catalog (pure Swift).* Still open: blending, voice-range tags.
5. **Song analyzer** — SongScribe `Song Analyzer` (audio → caption + lyrics + duration); mitnits style-drafter (Audio Flamingo 3 + CLAP — heavy); simpler: use transcription + heuristics. Feeds covers ("keep the source's feel").
6. **Lyric micro-controls** — pytraveler's finding: **mid-word capitals break the BPE merge at the stressed syllable** (`recORD` → `rec|ORD`) while ALL-CAPS does nothing — a documented, model-specific trick for stress placement.

### E. Conditioning & advanced controls

1. **Sampling overrides** — ds-yue-webui (temperature / top-p / top-k / repetition penalty / window / token caps per model), FS_Audio_Suite (rep penalty 1.2 "else a memorized song may replay"; **CFG "weirdness" > 1 costs 2× time**, 1.0 = native single-pass). *Shipped in v0.2.0: the Advanced sampling card (temperature/top-p/top-k/rep penalty + reset).* Still open: window / token caps per stage.
2. **Concept sliders** — mikkel/yue2-concept-sliders: 16 voice/genre "particle" adapters (female, metal, …) applied as scaled residuals hooked on AR attention during planning only, removable before synthesis; distilled standard-LoRA versions; scale slider with 0.5 interpolation. A "voice character" slider row in YuE2Mac's UI mapped to adapter files.
3. **LoRA adapter support** — ianiv (hot-reload folder, AR vs NAR kinds, strengths), ScryptHunter (stacking with independent AR/NAR strengths, LoKr, universal loader incl. FL/Starnodes/PEFT/HOT-Step/Mothersuperior formats), pytraveler (`YuE2 LoRA` + the 279 MB **instrumental LoRA**). Mothersuperior publishes: instrumental AR LoRA, realaudio NAR LoRA, hum adapters.
4. **Style/Artist LoRA training** — Starnodes2024 trainer (audio → VAE latents cached once; **NAR-only** flow-matching LoRA with `[Tags] trigger, caption` prefix; *style/timbre, not voice clone*; AR branch frozen); FS_Audio_Suite Artist Trainer (planner + decoder in one loop, KL trust region vs base model, chunked+checkpointed logits so whole songs fit, EMA, "pick rungs by ear, not by held-out CE"); vrgamegirl19 (playlist→dataset builder); YuE2gen-studio **identities** (a folder of one singer's songs → auto-separated vocals, key/tempo measured, lyrics drafted with Gemma's audio encoder, trigger-word captions exported).
5. **Robust instrumental mode** — official skill: keep the generated ABC, move `Vocal` notes to `Ins`, re-render. *Shipped in v0.2.0: the Pro score editor's Vocal→Ins rewrite; prompt injection remains the Lite fallback.* (YuE2UI even ships *baked instrumental-only* models.)

### F. Apple-Silicon performance & memory (beyond current MLX usage)

1. **8-bit AR quantization** — mlx-Yue: −40 % memory, +40 % tok/s (YuE2Mac already picks model variants; the numbers validate it).
2. **Steel SDPA / attention path choice** — mlx-Yue (363 → 187 s synthesis, bit-identical), tonywestonuk (MPS SDPA < 1 TFLOP/s → matmul attention 2.1×; MLX engine 2,643 → 1,080 s).
3. **Batched decode** — tonywestonuk (shared weight reads: 65 ms/step @1 → 62 ms/step @8 = 73 tok/s aggregate), engival SPEC_BATCH (decode N songs' AR in one `llama_decode`, "N × 52 s into ~52 s", N=4–8), YuE2-Turbo (vLLM + batched NAR across requests: 1.68× single, 3.31× concurrent, same quality on WildSongBench).
4. **Neural Engine** — tonywestonuk ANE route (2× GPU on short songs, per-length-bucket programs, ~6 min compile for the largest bucket, ~3.5 GiB address-window workaround, 387 ms/pass velocity corr 0.99974).
5. **Memory guard for 16–24 GB Macs** — mlx-Yue `measure.py` (footprint budget + swap detection), stavitian patches (tolerate *transient* pressure bursts during weight load; derive transcription budget from actual RAM), YuE2-Studio's 16 GB footprint table. YuE2Mac targets 16 GB machines — these are the exact failure modes to defend against.
6. **Tiled VAE decode** (`--vae-core-frames 128`) and **per-stage offload** (pytraveler: only the half of the model each stage needs → 4.4 GiB; Olm `offload_ar`).
7. **Residency & checkpoints** — yue2-mlx-swift stage-scoped residency, per-step synthesis checkpoints, **GPU gate** for backgrounding; YuE2Mac could checkpoint NAR steps to survive mid-song app events.
8. **No-Python runtimes as an alternative backend** — daig/yue2-mlx (C++20/Obj-C++ `lyra` CLI, native MLX + FP32 MPSGraph VAE, zero Python), ServeurpersoCom/engival yue2.cpp (GGML: backbone Q8_0 3.81 GB + VAE F32 530 MB; `yue-server /synth /job` job API, `yue-plan/yue-synth/yue-transcribe` stage tools, Vulkan/Metal). Long-term option to remove the Python venv from YuE2Mac's setup.

### G. Product & infrastructure patterns

1. **Local HTTP job API** (if YuE2Mac ever splits UI/engine): yue2-sidecar (`POST /generate → job_id`; `GET /jobs/{id}` returns **state/stage/progress/tokens/audio_seconds/truncated/timing**; `GET /jobs/{id}/score` for the ABC; `POST /unload` frees the model; formats flac/mp3/m4a); Yue2-runpod (create/cover/edit modes on one endpoint); yue-server (FIFO single-worker job system).
2. **MCP server for agent control** — krakenunbound: tools for status, generate, cancel, list/update/rate songs, playlists, **voice profiles**, sound effects; every invocation shown on an in-app MCP page; keys stay in a local vault. A native Mac app exposing MCP would let Claude/Cursor drive YuE2Mac.
3. **Watchdog self-healing** — Workbench: dual-process liveness with **90 s deep probe before killing** (inference-loaded `/health` is slow, not dead), "start-dead" circuit breaker (3 fast exits = config error, stop respawning), logs preserved on self-heal.
4. **Radio mode** — PasiKoodaa/YuE2-Radio: 8 genre stations w/ themes & lyrical motifs + Random + Custom; **Focused/Balanced/Experimental variety modes** avoiding recently used topics/motifs/tempos/timbres; queue-ahead of playback (1–5 songs), 0–8 s crossfades + per-song loudness correction, listener "requests" injected into upcoming songs, persistent playback recovery. Pairs naturally with on-device lyric writing for a zero-effort "infinite radio" pane.
5. **QA of generated songs via ASR** — giapnguyen74/yue2-server: Qwen3-ASR transcribes the *output*, computes **WER/CER + phoneme error rate against the intended lyrics** — an automatic "did it actually sing your lyrics?" score per song. (YuE2-Turbo uses the same trick for 2-candidate selection: keep the lower-PER take.) A lightweight quality badge in the library.
6. **Cover art generation** — krakenunbound `cover_art_renderer`; a native app could use Image Playground/AppKit instead.
7. **LAN access** — krakenunbound (explicit opt-in); Workbench's port whitelist + origin guards as the security checklist.
8. **Mastering / finishing** — smittyPNW (JUCE engine, Smart Master, 43 styles, 24-bit render, before/after A/B), timoncool/YuE2-Studio `audio-post` **Rust crates** (convolve, denoise, limiter, lifter, lowess smoothing, "naturalize", quality scoring, STFT, resample) — a smaller-scope "Finishing" pane (loudness normalize, EQ presets, limiter) is achievable in Swift/Core Audio.
9. **Setup robustness** — stavitian idempotent installer + `--check`; Whiskerwave resumable installer + pinned component revisions; Workbench `ports.json` single source of truth; Maestro's component-version matrix (python/torch/triton options in `setup_config.json`). YuE2Mac's one-button setup could gain a "verify install" + repair path.

---

## 3. Repos providing little or no analysis value (removed with the rest)

These were cloned, inspected, and found to contribute nothing beyond what other repos already cover — template-only READMEs, unmaintained forks, or Windows/CUDA-specific plumbing irrelevant to an Apple-Silicon Swift app:

| Repo | Reason |
|---|---|
| `arthurfarache/muvflow-yue` | 2 files (Dockerfile + api.py), no README |
| `yolanother/runpod-yuegp-serverless` | generic RunPod worker template, YuE-specific code is 1 handler |
| `usamireko/YuE-exllamav2-Colab` | single Colab notebook wrapping sgsdxzy |
| `aidec/YuE-exllamav2-GUI-easy` | minimal Tkinter wrapper for YuE-exllamav2 |
| `WrongProtocol/YuE-exllamav2-UI` | self-described "out of date sandbox", unmaintained |
| `Ladypoly/YuE2_WebUI` | near-identical fork of the official YuE repo (adds QUICKSTART.txt only) |
| `sdbds/YuE-for-windows`, `alisson-anjos/YuE-Interface`, `deepbeepmeep/YuEGP`, `sgsdxzy/YuE-exllamav2`, `alisson-anjos/YuE-exllamav2-UI` | YuE-1-era CUDA/Windows implementations; the one transferable idea (low-VRAM profiles / dual-track ICL) is documented above from better sources |
| `Cognito-Inc-451/Yue2-CUDA-Windows` | CUDA/Windows NAR speed patches (cuDNN forcing, prefill caching) — not applicable to MLX |
| `John-yg-Yim/LastAlbum-music-api` | YuE-1 FastAPI wrapper |
| `Blizaine/Maestro` | generic component-based AI workbench launcher (React template README); YuE2 is one plugin among many |
| `piscesbody/ComfyUI-YuE2` | upstream of ScryptHunter fork, superseded by it |
| `EmeraldApple-AI/ComfyUI-YuE2` | thin wrapper, all ideas covered by pytraveler/ScryptHunter |
| `T8mars/Comfyui-YuE2-T8` | Windows one-click bundle (exe + .bat installers); ideas covered elsewhere |
| `lee101/yue-cog`, `sruckh/Yue2-runpod` | cloud packaging; only the API contract was worth noting (§G.1) |
| `Mozer/YuE-extend` | YuE-1 continuation via dual-track ICL; superseded by YuE2's abc_open / semantic_keep approaches |
| `ace-step/ACE-Step`, `inikolax/remiqora`, `Joker56156/tio-music-studio` | competing model / multi-model studios — relevant only as "multi-engine" concept (§E/G) |

Everything else in the list contributed at least one concrete idea and is cited in §1–2 above. **All 63 clones were temporary and have been deleted** — re-clone any repo by name when implementing a specific feature from this document.

---

## 4. Roadmap for YuE2Mac

**Tier 1 — ✅ SHIPPED in v0.2.0** (all nine items; verified — see §0 for what landed):
output management + song library · queue with stage chips + honest stop states · saved
artifacts (song project, score, sidecar) · ABC edit → validate → re-render (+ Vocal→Ins) ·
draft(8) → finish(32) reusing the saved take · style preset catalog · advanced sampling ·
on-device lyric writing (FoundationModels, @Generable per-section guides) ·
references: ianiv, stavitian, tonywestonuk, smittyPNW, official editing.md/save_artifacts,
SongScribe, ds-yue-webui, FS_Audio_Suite.

**Tier 2 — bigger builds that need a second model or new UI surfaces:**
10. **Cover wizard** with SheetSage2 transcription (separate venv, CPU/GPU choice, warm-keep). *(official, ds-yue-webui, ianiv)*
11. **Hum-to-song** + continue-from-clip (`abc_open`). *(tonywestonuk, ianiv)*
12. Piano-roll score editor + syllable fit checker. *(FL-YuE2, mitnits)*
13. Karaoke **LRC/eLRC** export + word-highlight playback. *(Workbench)*
14. Long songs via chunked crossfade. *(cicalooo)*
15. **Variation families** (grouping retakes) + projects/albums. *(ianiv; retakes themselves shipped in v0.2.0)*
16. Local-LLM **writing room** (LM Studio/Ollama/OpenAI-compatible). *(pinokio, Whiskerwave, vrgamegirl19)*

**Tier 3 — ambitious differentiators:**
17. Persistent/batched worker or MLX batched AR decode. *(tonywestonuk, engival)*
18. **ANE synthesis** or yue2.cpp/no-Python backend. *(tonywestonuk, daig, ServeurpersoCom)*
19. **semantic_keep** ("keep the take to the cut, redo from there") and sample-accurate **Edit Track**. *(engival, pytraveler)*
20. LoRA/adapter loading incl. instrumental LoRA + concept sliders. *(ianiv, ScryptHunter, mikkel)*
21. **Radio mode** with variety control. *(PasiKoodaa)*
22. **MCP server** so agents can drive the studio. *(krakenunbound)*
23. iPhone companion as second engine. *(tonywestonuk)*
