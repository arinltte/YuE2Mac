# YuE2Mac — Release Notes

## v0.1.0 — Initial Release (2025)

**YuE2Mac** brings the open **YuE2** music-generation model (ported to Apple MLX)
to your Apple Silicon Mac. Type lyrics, describe a style, and get a full **48 kHz
stereo song** — generated entirely on your Mac.

### ✨ Highlights

- 🎵 **Lyrics + Style → Song** — describe a sound, paste lyrics with structure tags, and render a complete song locally.
- 🧠 **One-button setup** — press **Download & Install** and the app automatically:
  - downloads the YuE2 engine and a model variant (`8bit` / `4bit` / `bf16`, recommended one pre-selected) straight from Hugging Face,
  - builds a private Python environment and installs the MLX stack (mlx, numpy, tiktoken),
  - verifies everything and drops you straight into the composer.
- 📦 **Self-contained & offline** — after the one-time download everything lives in `~/Library/Application Support/YuE2Mac`; no API keys, no cloud, no monthly fees.
- 🪗 **Planning (COT)** — *Full / Melody only / Off* modes with optional editable **ABC score** output.
- 🎚 **Quality controls** — refinement steps, CFG (style obedience), song length, and a reproducible seed.
- 🎹 **Instrumental mode** — one switch injects `instrumental, no vocals` and strips lyrics to structure tags.
- ⚡ **Smart memory handling** — the engine runs as a child process and unloads immediately when a song finishes.
- 🎨 **Ambient themes** — Studio / Stage / Vinyl animated backgrounds.
- 🌍 **Bilingual** — English and 简体中文.

### ⚙️ Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1/M2/M3/M4…) Mac
- Homebrew (provides the Python used to bootstrap the app's private environment)
- Internet on first launch (one-time ~4.2 GB model download for the default 8-bit build)

### 📥 Install

1. Build & run, or grab the latest `.app` from Releases.
2. On first launch press **Download & Install**.
3. Done — start composing.

### 🔒 Privacy

Fully local. No telemetry, no cloud APIs, no data leaves your Mac.

### 🧰 Known Notes

- Model weights (derived from `m-a-p/YuE2-3B`) are **CC BY-NC 4.0** (non-commercial).
- Like many local-LLM tools, un-notarized builds may be blocked by Gatekeeper:
  `xattr -rd com.apple.quarantine /Applications/YuE2Mac.app`

### 🎉 Thanks

- **YuE** model + research by the multimodal-art-projection team
- **Apple MLX** runtime
- The `YuE2-3B-MLX` conversion this app wraps