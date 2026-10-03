<div align="center">

# 🎵 Awesome YuE

**A curated list of YuE ecosystem resources: integrations, tools, UIs, models, tutorials and best practices.**

[![GitHub Repo stars](https://img.shields.io/github/stars/RevolutionLA/awesome-YuE?style=social)](https://github.com/RevolutionLA/awesome-YuE/stargazers)
[![License: CC0-1.0](https://img.shields.io/badge/License-CC0_1.0-lightgrey.svg)](LICENSE)
[![Powered by YuE](https://img.shields.io/badge/Powered%20by-YuE-8A2BE2)](https://github.com/multimodal-art-projection/YuE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

[简体中文](README.md) | English

</div>

---

YuE (乐) is an open-source full-song music generation foundation model by the [m-a-p](https://github.com/multimodal-art-projection) team (lyrics2song) — often called "open-source Suno". Since its release in January 2025 the community has built a rich ecosystem of UIs, quantized runtimes, ComfyUI nodes, local ports and music-production workflows. This repo curates the best of the **YuE / YuE2 ecosystem**.

> 📊 **70+ projects listed** · Last updated 2026-09-26 · Link health checked quarterly
> 📌 See [CONTRIBUTING.md](CONTRIBUTING.md) for inclusion criteria. Categories are loosely ordered by popularity/activity.

---

## 📑 Contents

- [Quick Picks](#-quick-picks)
- [Official Resources](#️-official-resources)
- [GUIs](#-guis)
- [Quantization & Acceleration](#-quantization--acceleration)
- [Platform & Local Ports](#-platform--local-ports)
- [ComfyUI Integrations](#-comfyui-integrations)
- [Music Production Toolchain](#️-music-production-toolchain)
- [Cloud & Serving](#️-cloud--serving)
- [Tutorials & Best Practices](#-tutorials--best-practices)
- [Related Projects](#-related-projects)
- [Community](#-community)
- [Contributing](#-contributing)

---

## 🚀 Quick Picks

> Not sure where to start? Match your hardware and goal to a row.

| Your situation | Go to |
|---|---|
| Just want to hear it first | [NOIZ online demo](https://yue.noizai.net/) — free in the browser, no setup |
| Windows, want it working out of the box (100% offline) | [RevolutionLA/YuE2-Music-Workbench](https://github.com/RevolutionLA/YuE2-Music-Workbench) — songwriting + covers + RVC + LRC lyrics + batch queue |
| 24GB+ VRAM, best quality | [Official YuE2 BF16](https://github.com/multimodal-art-projection/YuE) + [official Skill](https://github.com/multimodal-art-projection/YuE/tree/main/skills/yue2-music) |
| 16GB VRAM | [exl2 / INT8 quantized weights](#-quantization--acceleration) |
| 8GB VRAM | [deepbeepmeep/YuEGP](https://github.com/deepbeepmeep/YuEGP) or [YuE-UI quantized mode](https://github.com/joeljuvel/YuE-UI) |
| Mac (Apple Silicon) | [vanch007/mlx-Yue](https://github.com/vanch007/mlx-Yue) or [tonywestonuk/YuE-Studio](https://github.com/tonywestonuk/YuE-Studio) |
| Want to use it in ComfyUI | ComfyUI native `YuE2GenerateMusic` node, see [ComfyUI Integrations](#-comfyui-integrations) |
| Want to edit the score / keep melody, swap lyrics | [timoncool/YuE2-Studio](https://github.com/timoncool/YuE2-Studio) (staff) · [FL-YuE2](https://github.com/filliptm/ComfyUI-FL-YuE2) (piano roll) |
| Need cloud / an API | [sruckh/Yue2-runpod](https://github.com/sruckh/Yue2-runpod) · [yue2-sidecar](https://github.com/Sparaa/yue2-sidecar) (FastAPI) |
| Don't want a Python env | [yue2.cpp](https://github.com/engival/yue2.cpp) — a single C++ executable |

> Short on VRAM? Jump to [Quantization & Acceleration](#-quantization--acceleration). Want the prompt recipes? See [Tutorials & Best Practices](#-tutorials--best-practices).

---

## 🏛️ Official Resources

<!-- markdownlint-disable MD034 -->

| Project | Description | Notes |
|---|---|---|
| [multimodal-art-projection/YuE](https://github.com/multimodal-art-projection/YuE) | Official YuE / YuE2 repo. YuE2 adds symbolic planning (editable ABC scores), zero-shot covers and agentic music editing — quality rivaling Suno v5 | Apache-2.0 |
| [YuE2 website](https://map-yue2.github.io/) | YuE2 project page with online demo | — |
| [NOIZ online demo](https://yue.noizai.net/) | Try YuE2 free in the browser, no install (recommended in official README) | Online service |
| [Blizaine/Maestro](https://github.com/Blizaine/Maestro) | Local song generation, composition planning and covers, powered by YuE2 (official README) | — |
| [YuE1 demo page](https://map-yue.github.io/) | First-generation YuE demo | — |
| [arXiv:2503.08638](https://arxiv.org/abs/2503.08638) | Paper: *YuE: Scaling Open Foundation Models for Long-Form Music Generation* | 2025.03 |
| [m-a-p on Hugging Face](https://huggingface.co/m-a-p) | All official weights: YuE-s1-7B (en/zh/jp-kr × cot/icl), YuE-s2-1B, YuE2-3B, YuE2-Vae, YuE-upsampler, etc. | — |
| [Comfy-Org/YuE2](https://huggingface.co/Comfy-Org/YuE2) | All-in-one checkpoint built with the ComfyUI team (`yue2_3b_bf16.safetensors`, ~7.8 GB) | ComfyUI-specific |
| [Official docs: docs/generation.md](https://github.com/multimodal-art-projection/YuE/blob/main/docs/generation.md) | YuE2 generation guide: `SongRequest` / `GenerationConfig` / symbolic score editing / reproducibility | — |
| [Official built-in Skill: yue2-music](https://github.com/multimodal-art-projection/YuE/tree/main/skills/yue2-music) | Official Agent Skill shipped with the repo (ABC editing reference + `run_yue2.py` script) | — |

> **YuE2 architecture at a glance**: a 2.2B AR language model plans the song and semantic tokens (`full`/`melody`/`off` CoT modes) → a 1.5B NAR flow-matching branch generates 64-channel VAE latents → a 48 kHz stereo VAE decodes the output; supports vLLM acceleration, CUDA Graph and weight offload.

## 🖥️ GUIs

> Graphical interfaces — generate songs with one click, low barrier to entry.

| Project | Description | Platform | Notes |
|---|---|---|---|
| ⭐ [RevolutionLA/YuE2-Music-Workbench](https://github.com/RevolutionLA/YuE2-Music-Workbench) | Local AI music workstation: YuE2 songwriting + AI covers + RVC voice conversion + LRC synced lyrics + batch queue — 100% offline, ready out of the box | Windows | Featured |
| [timoncool/YuE2-Studio](https://github.com/timoncool/YuE2-Studio) | Local AI song generator with an editable score (staff notation) | Windows/Linux | MIT |
| [deepbeepmeep/YuEGP](https://github.com/deepbeepmeep/YuEGP) | YuEGP: optimized for "GPU poor" users, MMGP memory management | Linux/Win | Recommended in official README |
| [joeljuvel/YuE-UI](https://github.com/joeljuvel/YuE-UI) | Gradio UI: batch generation, timeline visualization, incremental continuation, session save/load — runs on 8GB VRAM (quantized models) | Cross-platform | Recommended in official README |
| [sgsdxzy/YuE-exllamav2](https://github.com/sgsdxzy/YuE-exllamav2) | ExLlamaV2 accelerated implementation (with GUI) — one of the most efficient YuE1-era inference setups | Linux/Win | Apache-2.0 |
| [alisson-anjos/YuE-exllamav2-UI](https://github.com/alisson-anjos/YuE-exllamav2-UI) | Gradio UI on top of YuE-exllamav2 — 5.45× end-to-end speedup measured on RTX 4090; Docker image available | Linux/Win/Docker | Apache-2.0 |
| [alisson-anjos/YuE-Interface](https://github.com/alisson-anjos/YuE-Interface) | Dockerized Gradio UI — one env var pulls all official/quantized models; deploy locally or on RunPod | Docker/RunPod | — |
| [WrongProtocol/YuE-exllamav2-UI](https://github.com/WrongProtocol/YuE-exllamav2-UI) | The original Gradio UI for YuE-exllamav2 (official README) | Linux/Win | — |
| [vrgamegirl19/Yue2_Studio](https://github.com/vrgamegirl19/Yue2_Studio) | YuE2 desktop music studio | Windows | Apache-2.0 |
| [krakenunbound/yue2-studio](https://github.com/krakenunbound/yue2-studio) | Native Windows music studio: local model download, lyrics/cover editing | Windows | — |
| [Ladypoly/YuE2_WebUI](https://github.com/Ladypoly/YuE2_WebUI) | YuE2 WebUI | — | Apache-2.0 |
| [dynamohum/YuE2gen-studio](https://github.com/dynamohum/YuE2gen-studio) | Web UI for cover recording / prompt-based songwriting / editing | — | Apache-2.0 |
| [Mozer/YuE-extend](https://github.com/Mozer/YuE-extend) | YuE1 music continuation (mp3 extend) + GUI, with a Colab version | Cross-platform | Apache-2.0 |
| [CodeCat04/Whiskerwave-Studio](https://github.com/CodeCat04/Whiskerwave-Studio) | Local-first YuE2 generation GUI + Ollama-assisted lyric writing | — | — |
| [DocShotgun/ds-yue-webui](https://github.com/DocShotgun/ds-yue-webui) | YuE2 WebUI: generate / cover / edit | — | — |
| [aidec/YuE-exllamav2-GUI-easy](https://github.com/aidec/YuE-exllamav2-GUI-easy) | Easy-setup GUI for YuE-exllamav2 (Traditional Chinese interface) | Windows | — |
| [LeeAeron/YuE2UI](https://github.com/LeeAeron/YuE2UI) | YuE2 desktop app | — | Apache-2.0 |

## ⚡ Quantization & Acceleration

> Quantized weights and throughput optimizations when VRAM is tight.

| Project | Description | Notes |
|---|---|---|
| [NoizAI/YuE2-Turbo](https://github.com/NoizAI/YuE2-Turbo) | YuE2 high-concurrency inference & serving toolkit: same model, same recipe — 1.68× per-song speedup, 3.31× concurrency | Apache-2.0 |
| [Alissonerdx exl2 weights](https://huggingface.co/collections/Alissonerdx/yue-models-exllamav2-67a539be76b5225ebda95323) | Full ExLlamaV2 quantization range for YuE-s1-7B (3.0–8.0 bpw) | HF Collection |
| [Doctor-Shotgun/YuE-s1-7B-anneal-en-cot-exl2](https://huggingface.co/Doctor-Shotgun/YuE-s1-7B-anneal-en-cot-exl2) | exl2 quantized weights (Q8/Q6 etc.) | HF |
| [Alissonerdx/YuE-s1-7B-anneal-en-cot-int8](https://huggingface.co/Alissonerdx/YuE-s1-7B-anneal-en-cot-int8) | bitsandbytes INT8 quantized weights | HF |
| [ServeurpersoCom/yue2.cpp](https://github.com/ServeurpersoCom/yue2.cpp) | GGML C++17 portable implementation: text + lyrics in, 48kHz stereo out | MIT |
| [engival/yue2.cpp](https://github.com/engival/yue2.cpp) | ggml/Vulkan implementation of YuE2: a single C++ executable, no Python needed | MIT |

## 📦 Platform & Local Ports

> Native running and one-click installs on Mac (MLX / Core ML) and Windows / Linux, grouped by platform.

| Project | Description | Notes |
|---|---|---|
| [tonywestonuk/YuE-Studio](https://github.com/tonywestonuk/YuE-Studio) | Native Mac app tuned for Apple Silicon (GPU + Neural Engine) | Apache-2.0 |
| [vanch007/mlx-Yue](https://github.com/vanch007/mlx-Yue) | Apple Silicon MLX native port of YuE2-3B (with audio transcription) | Apache-2.0 |
| [ianiv/YuE2](https://github.com/ianiv/YuE2) | YuE2 Studio: local web app on Apple Silicon (MLX) | MIT |
| [VincentGourbin/yue2-mlx-swift](https://github.com/VincentGourbin/yue2-mlx-swift) | Swift/MLX port: lyrics + style → full song | MIT |
| [daig/yue2-mlx](https://github.com/daig/yue2-mlx) | BF16-first MLX/MPS experiments, auto-tracking upstream | Apache-2.0 |
| [arinltte/YuE2Mac](https://github.com/arinltte/YuE2Mac) | Local AI songwriting studio (Mac) | MIT |
| [smittyPNW/YuE-Studio](https://github.com/smittyPNW/YuE-Studio) | Apple Silicon local creation/editing/mastering, full-quality YuE2 generation and reversible audio processing | Apache-2.0 |
| [stavitian/yue2-studio](https://github.com/stavitian/yue2-studio) | macOS app + installer: YuE2-3B generation/cover/transcription (with 24 GB Mac fixes) | — |
| [sdbds/YuE-for-windows](https://github.com/sdbds/YuE-for-windows) | YuE1 native Windows support (Gradio + Docker) | Apache-2.0 |
| [Cognito-Inc-451/Yue2-CUDA-Windows](https://github.com/Cognito-Inc-451/Yue2-CUDA-Windows) | YuE2 CUDA Windows adaptation | — |
| [siliconsense/yue2-studio-pc](https://github.com/siliconsense/yue2-studio-pc) | One-click batch to run YuE2 on NVIDIA GPUs (songs + covers) | — |
| [Rdx-ai-art/yue2-mlx.pinokio](https://github.com/Rdx-ai-art/yue2-mlx.pinokio) | Pinokio one-click installer for YuE2-3B (Mac MLX) | — |
| [deadjoe/yue2_groove](https://github.com/deadjoe/yue2_groove) | Unofficial YuE2 web UI (Apple Silicon first, Linux/CUDA also works), plus a [Pinokio version](https://github.com/deadjoe/yue2-groove-pinokio) | Apache-2.0 |
| [PasiKoodaa/YuE2-Radio](https://github.com/PasiKoodaa/YuE2-Radio) | Local AI radio (continuous YuE2 playback) | MIT |
| [Joker56156/tio-music-studio](https://github.com/Joker56156/tio-music-studio) | Local AI music studio: ACE-Step 1.5 / YuE / DiffRhythm integration | — |

## 🧩 ComfyUI Integrations

> ComfyUI natively supports YuE2 (PR #16250, `yue2` branch). Below are community node packs and related workflows.

| Project | Description | Notes |
|---|---|---|
| ComfyUI native support | Built-in nodes in ComfyUI core (`YuE2GenerateABC` / `YuE2GenerateMusic` etc., in `comfy_extras/nodes_yue2.py`), using the [Comfy-Org/YuE2](https://huggingface.co/Comfy-Org/YuE2) all-in-one checkpoint | Official native |
| [smthemex/ComfyUI_YuE](https://github.com/smthemex/ComfyUI_YuE) | The most popular community ComfyUI node of the YuE1 era (Stage A/B loaders, exl2/INT8 quantization support) | Apache-2.0 |
| [filliptm/ComfyUI-FL-YuE2](https://github.com/filliptm/ComfyUI-FL-YuE2) | YuE2 music generation + editable piano roll | Apache-2.0 |
| [T8mars/Comfyui-YuE2-T8](https://github.com/T8mars/Comfyui-YuE2-T8) | YuE2 ComfyUI node pack | — |
| [Starnodes2024/ComfyUI-YuE2-Trainer](https://github.com/Starnodes2024/ComfyUI-YuE2-Trainer) | YuE2 LoRA trainer: train a style LoRA on your own tracks (NAR branch, 24GB VRAM recommended), native ComfyUI format output | — |
| [ScryptHunter/ComfyUI-YuE2](https://github.com/ScryptHunter/ComfyUI-YuE2) | Compatibility fork with isolated dependencies, adapted for newer ComfyUI and Transformers | Apache-2.0 |
| [pytraveler/YuE2-ComfyUI](https://github.com/pytraveler/YuE2-ComfyUI) | YuE2 nodes with a piano-roll score editor, Edit Track (retake, cut, move or extend parts of a finished song), covers from audio or MIDI, a lyrics writer and LoRA support | Apache-2.0 |
| [KytraScript/ComfyUI-FS_Audio_Suite](https://github.com/KytraScript/ComfyUI-FS_Audio_Suite) | Modular YuE2 audio generation nodes + mastering/denoise workflows (cover generation included) | — |
| [o-l-l-i/ComfyUI-Olm-YuE2](https://github.com/o-l-l-i/ComfyUI-Olm-YuE2) | Style + lyrics → song, optional score view/edit | — |
| [nvmax/ComfyUI-YuE2](https://github.com/nvmax/ComfyUI-YuE2) | YuE2 ComfyUI nodes | Apache-2.0 |
| [piscesbody/ComfyUI-YuE2](https://github.com/piscesbody/ComfyUI-YuE2) | YuE2 ComfyUI nodes (upstream of the ScryptHunter fork) | Apache-2.0 |
| [EmeraldApple-AI/ComfyUI-YuE2](https://github.com/EmeraldApple-AI/ComfyUI-YuE2) | YuE2-3B lyrics-to-song custom node | — |
| [TheLocalLab/ComfyUI-SongScribe](https://github.com/TheLocalLab/ComfyUI-SongScribe) | AI music prompt nodes: 73 style presets + song analysis (supports YuE2) | MIT |
| [UnlimitedEditing/ComfyUI-YuE2Fast](https://github.com/UnlimitedEditing/ComfyUI-YuE2Fast) | Fast nodes running the official YuE2 runtime (CUDA Graph decoding) | — |
| [cicalooo/ComfyUI-YuE2-LongSong](https://github.com/cicalooo/ComfyUI-YuE2-LongSong) | YuE2 long-song generation workflow | MIT |
| [mitnits/yue2-same-music-new-lyrics](https://github.com/mitnits/yue2-same-music-new-lyrics) | Keep the melody, sing new lyrics: Gradio UI + ComfyUI nodes (YuE2 + SheetSage2) | Apache-2.0 |

## 🎛️ Music Production Toolchain

> Connecting YuE2 to DAWs, score editing and audio post-production.

| Project | Description | Notes |
|---|---|---|
| [mikkel/yue2-concept-sliders](https://github.com/mikkel/yue2-concept-sliders) | 16 YuE2 music concept sliders, ComfyUI-ready | MIT |
| [nheegen/yue2-session-bridge](https://github.com/nheegen/yue2-session-bridge) | Ableton Max for Live device: Session MIDI harmony → ABC → YuE2 | MIT |
| [o-l-l-i workflow collection](https://github.com/o-l-l-i/ComfyUI-Olm-YuE2) | Complete ComfyUI workflow examples with score view/edit + cover mode | — |

## ☁️ Cloud & Serving

| Project | Description | Notes |
|---|---|---|
| [yolanother/runpod-yuegp-serverless](https://github.com/yolanother/runpod-yuegp-serverless) | YuEGP worker on RunPod Serverless | — |
| [lee101/yue-cog](https://github.com/lee101/yue-cog) | Cog packaging for YuE2 + RunPod serverless adapter | — |
| [sruckh/Yue2-runpod](https://github.com/sruckh/Yue2-runpod) | YuE2 RunPod Serverless worker (style + lyrics → full song) | — |
| [Sparaa/yue2-sidecar](https://github.com/Sparaa/yue2-sidecar) | FastAPI task API (built on yue2-infer, ABC covers and long songs) | Apache-2.0 |
| [arthurfarache/muvflow-yue](https://github.com/arthurfarache/muvflow-yue) | YuE music generation API (SaladCloud) | — |
| [giapnguyen74/yue2-server](https://github.com/giapnguyen74/yue2-server) | YuE2 model server | — |
| [John-yg-Yim/LastAlbum-music-api](https://github.com/John-yg-Yim/LastAlbum-music-api) | FastAPI song generation service based on YuE (LastAlbum backend) | — |
| [usamireko/YuE-exllamav2-Colab](https://github.com/usamireko/YuE-exllamav2-Colab) | One-click YuE-exllamav2 on Google Colab | Apache-2.0 |

## 📚 Tutorials & Best Practices

- **Official prompt engineering guide**: [how to write genre.txt / lyrics.txt](https://github.com/multimodal-art-projection/YuE#prompt-engineering) — song section tags (`[Verse]`/`[Chorus]`), style tag ordering, etc.
- **Official sample workflow videos**: Fahd's [YuE quick-start video](https://github.com/multimodal-art-projection/YuE#quick-start).
- **YuE2 prompt structure**: put genre/instruments/vocals/language/tempo in `style`, tagged lyrics in `lyrics`; see [examples/song.json](https://github.com/multimodal-art-projection/YuE/blob/main/examples/song.json).
- **ICL cover best practices** (excerpt from the official README):
  1. Dual-track ICL (vocal + accompaniment) gives the best musicality and prompt adherence;
  2. A chorus excerpt works better as reference audio;
  3. About 30 seconds of reference audio is ideal;
  4. Separate stems with [python-audio-separator](https://github.com/nomadkaraoke/python-audio-separator) or UVR;
  5. Providing reference audio reduces diversity — pure CoT mode yields more varied output.
- **ComfyUI Wiki: YuE2-3B intro and native support**: [comfyui-wiki.com/en/news/2026-09-11-yue2-3b](https://comfyui-wiki.com/en/news/2026-09-11-yue2-3b) — includes ComfyUI dependency conflict notes (PyTorch/Transformers version pins).
- **DeepWiki: YuE code walkthrough**: [deepwiki.com/multimodal-art-projection/YuE](https://deepwiki.com/multimodal-art-projection/YuE) — visualized docs for `YuE2Pipeline` architecture, AR/NAR/VAE modules and backend acceleration.
- **VRAM cheat sheet (community experience)**: 24GB+ → official BF16; 16GB → exl2/INT8 quantization; 8GB → YuE-UI quantized mode / YuEGP MMGP; Mac → MLX ports.

## 🔗 Related Projects

| Project | Description |
|---|---|
| [ace-step/ACE-Step](https://github.com/ace-step/ACE-Step) | Another open-source music generation foundation model, often compared / combined with YuE2 (remiqora integrates both in one UI) |
| [inikolax/remiqora](https://github.com/inikolax/remiqora) | Local AI music studio unifying ACE-Step 1.5 and YuE2-3B (Vue) |
| [m-a-p/MERT](https://huggingface.co/m-a-p/MERT-v1-95M) | Music understanding model used in YuE2 evaluation (MERT2) |
| [SheetSage2](https://huggingface.co/m-a-p) | Lyrics-aligned score model used in YuE2 evaluation |

## 👥 Community

- [GitHub Issues / Discussions](https://github.com/multimodal-art-projection/YuE/issues) — official repo issues and roadmap (vLLM/sglang, llama.cpp, stemgen, etc.).
- [Hugging Face m-a-p org](https://huggingface.co/m-a-p) — weight releases and model cards.
- [map-yue2.github.io](https://map-yue2.github.io/) — online listening demo.

## 🤝 Contributing

PRs welcome! Read [CONTRIBUTING.md](CONTRIBUTING.md) for inclusion criteria, formatting rules and submission steps. Both English and Chinese submissions are accepted; English is preferred here.

## ⚖️ License

This list is released under [CC0 1.0](LICENSE). Listed projects retain their own licenses — check each project's page before use.

---

<div align="center">

**[⬆ Back to top](#-awesome-yue)**

Made with ❤️ by the YuE community · Inspired by [awesome-deepseek-integration](https://github.com/deepseek-ai/awesome-deepseek-integration) & [sindresorhus/awesome](https://github.com/sindresorhus/awesome)

</div>
