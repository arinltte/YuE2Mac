<p align="center">
  <img src="img/logo.png" alt="YuE2Mac Logo" width="64" />
  <br />
  <h1 align="center">YuE2Mac</h1>
  <p align="center">Local AI Songwriting Studio for Apple Silicon — Lyrics + Style → A Full Song.</p>
  <p align="center">
    <a href="https://github.com/arinltte/YuE2Mac/releases/latest"><img src="https://img.shields.io/github/v/release/arinltte/YuE2Mac?style=flat-square&color=blue" alt="Latest Release" /></a>
    <a href="https://github.com/arinltte/YuE2Mac/blob/main/LICENSE.txt"><img src="https://img.shields.io/github/license/arinltte/YuE2Mac?style=flat-square&color=green" alt="License" /></a>
    <img src="https://img.shields.io/badge/macOS-14.0%2B-blue?style=flat-square" alt="macOS" />
    <img src="https://img.shields.io/badge/100%25-Offline-brightgreen?style=flat-square" alt="Offline" />
    <a href="https://github.com/RevolutionLA/awesome-YuE"><img src="https://img.shields.io/badge/awesome--YuE-listed-9b59b6?style=flat-square" alt="Listed in awesome-YuE" /></a>
  </p>
</p>

<p align="center">
  <a href="./README.md">English</a> | <a href="./README-ZH.md">中文文档</a>
</p>

## Introduction

YuE2Mac is a native macOS desktop application that brings the open [**YuE2**](https://github.com/multimodal-art-projection/YuE) music-generation model — ported to **Apple MLX** — directly to your Apple Silicon Mac. Type some lyrics, pick a style, and the app plans the arrangement, composes the melody, refines the sound, and renders a full **48 kHz stereo song** — completely offline.

Powered by YuE2 (a Mixture-of-Transformers model) running at 8-bit on the Apple GPU, YuE2Mac requires no internet connection, no API keys, and nothing leaves your machine. Your lyrics and your songs stay on your Mac.

> **Original models & research:** [YuE project page](https://map-yue2.github.io) · [YuE on GitHub](https://github.com/multimodal-art-projection/YuE) · [MERT](https://arxiv.org/abs/2306.00107)

Listed in [awesome-YuE](https://github.com/RevolutionLA/awesome-YuE) — the curated directory of the YuE / YuE2 ecosystem.

## 🆕 What's new in v0.2.0

The whole studio was rebuilt around two modes, and every Tier-1 idea from the [ecosystem analysis](./ECOSYSTEM_ANALYSIS.md) landed, plus a layout polish pass:

*   **Two modes** — *Lite* (two steps and a big button) and *Pro* (the full studio), switched from the toolbar; your work follows you between modes.
*   **Queue** — line up as many songs as you like; one renders at a time, with live stage chips (Load → Plan → Compose → Refine → Render → Save) and a tokens/s readout.
*   **Draft → Finish** — render a fast 8-step preview, then press *Finish at full quality* to re-render **the same take** (saved tokens + seed) at 32 steps.
*   **Song Library** — every song lands in its own timestamped folder with its score, seed and settings; search, replay, export M4A, take a new variation, or delete.
*   **ABC Score Studio** — edit the score YuE2 planned for you, validate your edits, rewrite vocals to instrumental (the official recipe), and re-render with the same seed.
*   **Advanced sampling** — temperature, top-p, top-k, repetition penalty, with one-click reset.
*   **Write with AI** — on-device lyric drafting via Apple FoundationModels on Apple-Intelligence Macs (macOS 26+). Nothing downloads, nothing leaves your Mac.
*   **Style catalog** — ~40 categorized style starters, chips in Lite and a browser in Pro, plus “Surprise me”.
*   **Help everywhere** — every control explains itself: hover the ❓ for a tooltip, click it for a short card.
*   **Resizable split** — drag the divider between the writing canvas and the controls column; each mode remembers your width, double-click resets it.
*   **Tidier chrome** — the Lite/Pro switch sits on the left of the toolbar, everything else (library, appearance, about, settings) on the right; appearance now lives only in the toolbar.

## ✨ Top Features

*   🎚 **Two Modes, One Click:** A toolbar switch flips the whole studio between **Lite** (two steps and a big button — perfect for a first song) and **Pro** (queue, sampling controls, score editing, library tools). Your work follows you between modes.
*   🌸 **Lyrics + Style → Song:** Write your own lyrics or load a built-in sample set, describe the sound, and get a full song. On Apple-Intelligence Macs (macOS 26+), a **Write with AI** button drafts a full lyric sheet on-device — nothing leaves your Mac.
*   🎛 **Style Catalog:** A curated, categorized set of style starters (chips in Lite, a browser in Pro) — from Bossa Nova to Synthwave, with “Surprise me”.
*   🌹 **Draft → Finish:** Generate a fast 8-step preview, then press **Finish at full quality** — it reuses the exact same take (saved song tokens + seed) and only refines it at 32 steps.
*   📚 **Song Library:** Every song lands in its own timestamped folder with its seed, settings and score. Search, replay, export **M4A**, take a **new variation**, or delete — plus your old loose `.wav` files are still listed.
*   ⏳ **Queue:** Queue as many songs as you like; one renders at a time with live stage chips (Load → Plan → Compose → Refine → Render → Save) and tokens/s readout. Queued jobs cancel instantly; stops are honestly labelled.
*   🎼 **ABC Score Studio:** The score YuE2 writes is saved next to every song. Edit it, validate it, **make the song instrumental** (the official Vocal→Ins recipe), or re-render with the same seed — all inside the app.
*   🧠 **Model Version Choice:** The installer pre-selects a model (**8-bit / 4-bit / bf16**) based on your Mac's RAM and spec, then downloads exactly that one.
*   🪗 **Planning (COT):** *Full* writes a chord-annotated chart, *Melody only* writes a melody outline, *Off* goes straight to audio for speed.
*   🎚 **Advanced Sampling (Pro):** Temperature, top-p, top-k and repetition penalty — mirroring the engine's generation config, with one-click reset.
*   🎹 **Instrumental Mode:** One switch injects *instrumental, no vocals* and strips lyrics to structure tags — taming the model's vocal bias. In Pro, the score editor can do the robust Vocal→Ins rewrite instead.
*   ❓ **Help Icons:** Every control has an explanation icon (hover for a tooltip, click for a quick card).
*   🎨 **Ambient Themes:** Studio / Stage / Vinyl — animated ambient backgrounds that adapt with the UI.
*   ⚡ **Smart Resource Handling:** The engine runs as a child process and is unloaded from memory the moment a song finishes, keeping your Mac responsive.
*   📦 **Self-Contained, One-Button Setup:** One press downloads the engine + model from Hugging Face, builds a private Python environment, and installs it all in the app's own folder — you never pick files or folders.

## ⚙️ Requirements

The app sets up its own Python environment and dependencies automatically. Beforehand you need:

*   **macOS 14.0 (Sonoma)** or later.
*   **Apple Silicon (M1/M2/M3/M4/M4 Pro…)** Mac.
*   **[Homebrew](https://brew.sh/):** Provides the Python ABI used to bootstrap the app's private virtual environment. (If missing, the setup screen gives you the exact command.)
*   **Internet Connection:** Only on first launch, to download the engine code, the MLX/numpy/tiktoken packages, and the model weights once. After that the app works fully offline.

## 📥 Installation

1.  Build & run (see [Building](#building-and-running)), or download the latest `.app` from the [Releases page](https://github.com/arinltte/YuE2Mac/releases/latest).
2.  On first launch, the **Setup screen** shows your Mac's spec (chip + RAM) and pre-selects a **model version**:
    *   **8-bit** — best quality/size balance, recommended for 16 GB+.
    *   **4-bit** — smallest, better for 8–12 GB Macs.
    *   **bf16** — highest fidelity, needs 28 GB+.
3.  Press **“Download & Install”** — that's it. YuE2Mac automatically:
    *   builds a private Python virtual environment (`~/Library/Application Support/YuE2Mac/Python`) and installs `mlx`, `numpy`, `tiktoken`;
    *   downloads the YuE2 engine code and your chosen model weights from Hugging Face (`Models/<variant>/`);
    *   verifies everything, then switches you straight to the composer.
4.  Done — fully offline from then on.

> **First download size:** the engine code is tiny, but the model weights are large — about **4.2 GB** for the default 8-bit model (3.4 GB 4-bit, 7 GB bf16). It only downloads once.

> **Notarization note:** like many local-LLM tools, the app may be blocked by Gatekeeper. If so, run:
> `xattr -rd com.apple.quarantine /Applications/YuE2Mac.app`

## 🚀 Getting Started

The toolbar switch at the top picks your mode:

*   **Lite** — pick a vibe from the chips (or let **Surprise me** choose), write lyrics (or press **Write with AI** on supported Macs), and hit the big **Generate Song** button. Optionally flip on **Quick preview** for a fast draft you can *finish* later at full quality.
*   **Pro** — everything above, plus: **queue** several songs at once (they run one at a time, each with live stage chips), **model/planning** pickers, **quality** (steps + draft toggle), **advanced sampling** (temperature / top-p / top-k / repetition penalty), **song length**, and a **seed** field.

After generating, every song lives in its own folder in the **library** (`Output/<date> <title>/`) with its WAV, ABC score, saved song project, and a `song.json` sidecar of settings. From the result panel or the library you can **replay**, **finish a draft at full quality** (same take, 32 steps), **edit the ABC score and re-render**, **take a new variation**, **export M4A**, or **delete**.

## 🧠 Feature explanations

*   **Draft → Finish:** *Quick preview* renders with 8 steps (≈4× faster). The take's semantic tokens and seed are saved, so **Finish at full quality** re-renders the *same* composition at 32 steps — no re-composing, no surprises.
*   **Queue:** songs render one at a time; a queued job cancels instantly, a running one stops at the next step and is honestly labelled *Stopped* (never *Failed*).
*   **Style catalog:** a curated, categorized set of ~40 starters (chips in Lite, full browser in Pro) — no AI, just ideas.
*   **Write with AI (macOS 26+ with Apple Intelligence):** drafts a structured lyric sheet on-device via Apple's **FoundationModels** — the system model that ships with macOS as part of Apple Intelligence. **No model is downloaded for this and no network is used** — it is a different model from the song engine, which *does* download once from Hugging Face. Each section (verse / chorus / bridge / outro) is generated with its own guide so the small on-device model keeps sections distinct instead of repeating one hook. The button hides automatically on Macs without Apple Intelligence.
*   **Help icons (❓):** each slider/switch shows a tooltip on hover and a short explainer card on click.
*   **Samples (lyrics):** loads ready-made lyric sets, including an **Instrumental only** template.
*   **Instrumental:** adds `instrumental, no vocals` to the prompt and keeps only the structural tags from your lyrics. In Pro, the score editor can instead rewrite the ABC directly (Vocal → Ins) — the official, most robust YuE2 recipe.
*   **Score editing (Pro):** every planned song saves its ABC score. The editor validates your edits (notes/bars/voices), warns when the structure changed a lot, and re-renders with the same seed — or a fresh one.
*   **Planning (COT):** *Full* = plans chords + melody, *Melody only* = melody outline, *Off* = straight to audio (fastest, may lose the beat).
*   **CFG:** how strictly the model follows your style prompt. Higher = more obedient, possibly less creative.
*   **Sampling (Pro):** temperature (wildness), top-p/top-k (candidate cut-offs), repetition penalty (stops the model replaying a memorized song). Defaults mirror the engine's own config.
*   **Seed:** same lyrics + same seed = the same song. Leave blank for a random take.

## 🔬 Tested Generation (M4 · 16 GB · 8-bit)

A real run was benchmarked on a base **M4 MacBook Pro with 16 GB RAM** using the **8-bit** engine with this input:

> **Style:** `English, soft rock, 70s feel, smooth bass, electric piano, brushed drums`

> **Lyrics:**
> ```
> [Verse]
> I took my time, I took the slow lane
> Learned to love the quiet rain
>
> [Chorus]
> I bloomed when nobody was watching
> Good things come late, and that's okay
>
> [Verse]
> All my once-upons grew roots at last
> I stopped replaying failed takes from the past
>
> [Chorus]
> I bloomed when nobody was watching
> Good things come late, and that's okay
> ```

| Metric | Result |
| :--- | :--- |
| Model | YuE2-3B, 8-bit MLX |
| Memory used during generation | **~11.4 GB** of the 16 GB system |
| Device | Apple M4 · 16 GB unified memory |
| Output | 48 kHz stereo WAV |

Because the engine runs as its own child process, all ~11.4 GB is **released the moment the song finishes** — nothing stays pinned in RAM, so your Mac doesn't stay laggy after a session.

## 🔒 Data & Privacy

All generation happens locally on your GPU. No telemetry, no cloud APIs.

| Location | Contents |
| :--- | :--- |
| `~/Library/Application Support/YuE2Mac/Python` | Isolated Python venv + pip packages (mlx, numpy, tiktoken). |
| `~/Library/Application Support/YuE2Mac/Scripts` | `generate.py` + the model modules from Hugging Face, plus the app's bundled `yue2_pro.py` add-on (draft/finish, sampling, saved takes). |
| `~/Library/Application Support/YuE2Mac/Models` | The chosen model weights (8-bit/4-bit/bf16), downloaded from Hugging Face. |
| `~/Library/Application Support/YuE2Mac/Output` | Your songs — one timestamped folder each (`song.wav`, `song.abc`, `song.tokens.json`, `song.json`). |

## Uninstallation

```bash
rm -rf /Applications/YuE2Mac.app
rm -rf ~/Library/Application\ Support/YuE2Mac
```

## Building and Running

```bash
open YuE2Mac.xcodeproj        # in Xcode, hit Run

# or build & launch directly (no Xcode debugger, lower memory):
bash scripts/run_app.sh
```

## 🤝 Contributing

Contributions are welcome. To contribute: fork the repo, make a branch, commit with a clear message, and open a pull request. For bugs or feature requests, open an [issue](https://github.com/arinltte/YuE2Mac/issues) and include your macOS version and reproduction steps.

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

<p align="center">
  <i>Logo by GUMO · https://www.instagram.com/gumoooo._/</i>
</p>

<p align="center">
  <i>Developed by arinltte · arinltte00@gmail.com</i>
</p>