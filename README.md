<p align="center">
  <img src="img/logo.jpg" alt="YuE2Mac Logo" width="64" />
  <br />
  <h1 align="center">YuE2Mac</h1>
  <p align="center">Local AI Songwriting Studio for Apple Silicon — Lyrics + Style → A Full Song.</p>
  <p align="center">
    <a href="https://github.com/arinltte/YuE2Mac/releases/latest"><img src="https://img.shields.io/github/v/release/arinltte/YuE2Mac?style=flat-square&color=blue" alt="Latest Release" /></a>
    <a href="https://github.com/arinltte/YuE2Mac/blob/main/LICENSE.txt"><img src="https://img.shields.io/github/license/arinltte/YuE2Mac?style=flat-square&color=green" alt="License" /></a>
    <img src="https://img.shields.io/badge/macOS-14.0%2B-blue?style=flat-square" alt="macOS" />
    <img src="https://img.shields.io/badge/100%25-Offline-brightgreen?style=flat-square" alt="Offline" />
  </p>
</p>

<p align="center">
  <a href="./README.md">English</a> | <a href="./README-ZH.md">中文文档</a>
</p>

## Introduction

YuE2Mac is a native macOS desktop application that brings the open [**YuE2**](https://github.com/multimodal-art-projection/YuE) music-generation model — ported to **Apple MLX** — directly to your Apple Silicon Mac. Type some lyrics, pick a style, and the app plans the arrangement, composes the melody, refines the sound, and renders a full **48 kHz stereo song** — completely offline.

Powered by YuE2 (a Mixture-of-Transformers model) running at 8-bit on the Apple GPU, YuE2Mac requires no internet connection, no API keys, and nothing leaves your machine. Your lyrics and your songs stay on your Mac.

> **Original models & research:** [YuE project page](https://map-yue2.github.io) · [YuE on GitHub](https://github.com/multimodal-art-projection/YuE) · [MERT](https://arxiv.org/abs/2306.00107)

## ✨ Top Features

*   🌸 **Lyrics + Style → Song:** Write your own lyrics or load a built-in sample set, describe the sound, and get a full song.
*   🎲 **Style Shuffle (non-AI):** Press the ↻ arrow next to **Style prompt** to cycle through a bundled list of ready-made style starters — no AI, just ideas.
*   🧠 **Model Version Choice:** The installer pre-selects a model (**8-bit / 4-bit / bf16**) based on your Mac's RAM and spec, then downloads exactly that one.
*   🪗 **Planning (COT):** *Full* writes a chord-annotated chart, *Melody only* writes a melody outline, *Off* goes straight to audio for speed.
*   🎚 **Quality Controls:** Refinement steps, CFG (how strictly it follows your style), song length, and a reproducible seed.
*   🎼 **ABC Score:** When planning is on, the generated ABC notation is saved alongside the song and can be opened with one click.
*   🎹 **Instrumental Mode:** One switch injects *instrumental, no vocals* and strips lyrics to structure tags — taming the model's vocal bias.
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

1.  **Style:** Describe the mood/instruments, or press the **↻ arrow** to shuffle a ready-made starter.
2.  **Lyrics:** Type your lyrics with structure tags (`[Verse]`, `[Chorus]`…), use the tag buttons, or press **Samples** to load a built-in set.
3.  **Planning & Quality:** pick *Full / Melody / Off*, then set steps, CFG, length, and (optionally) a seed for reproducible takes.
4.  **Generate:** press **Generate Song**. Watch friendly progress in the bottom-left panel; the big button becomes **Stop** while it works.
5.  **Enjoy:** play the result inline, open the **ABC score**, or **Show in Finder**.

## 🧠 Feature explanations

*   **Style shuffle (↻):** cycles through a `Presets.swift` list of ~10 starter styles. It doesn't call AI — it's a rotating list so you never stare at a blank box.
*   **Help icons (❓):** each slider/switch shows a tooltip on hover and a short explainer card on click.
*   **Samples (lyrics):** loads ready-made lyric sets, including an **Instrumental only** template.
*   **Instrumental:** adds `instrumental, no vocals` to the prompt and keeps only the structural tags from your lyrics.
*   **Planning (COT):** *Full* = plans chords + melody, *Melody only* = melody outline, *Off* = straight to audio (fastest, may lose the beat).
*   **CFG:** how strictly the model follows your style prompt. Higher = more obedient, possibly less creative.
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
| `~/Library/Application Support/YuE2Mac/Scripts` | `generate.py` + the model modules, downloaded from Hugging Face. |
| `~/Library/Application Support/YuE2Mac/Models` | The chosen model weights (8-bit/4-bit/bf16), downloaded from Hugging Face. |
| `~/Library/Application Support/YuE2Mac/Output` | Your generated songs (`song.wav`). |

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

## 📄 License & Acknowledgements

The YuE2Mac application source is licensed under the [MIT License](./LICENSE.txt).

*   **Base model:** [**YuE**](https://github.com/multimodal-art-projection/YuE) — an open foundation model family for long-form music generation, and its research project [map-yue2.github.io](https://map-yue2.github.io). Please cite it:
    ```bibtex
    @article{li2023mert,
      title = {{MERT}: Acoustic Music Understanding Model with Large-Scale Self-supervised Training},
      author = {Li, Yizhi and Yuan, Ruibin and Zhang, Ge and Ma, Yinghao and Chen, Xingran and Yin, Hanzhi and Xiao, Chenghao and Lin, Chenghua and Ragni, Anton and Benetos, Emmanouil and Gyenge, Norbert and Dannenberg, Roger and Liu, Ruibo and Chen, Wenhu and Xia, Gus and Shi, Yemin and Huang, Wenhao and Wang, Zili and Guo, Yike and Fu, Jie},
      journal = {arXiv preprint arXiv:2306.00107},
      year = {2023},
      eprint = {2306.00107},
      archivePrefix = {arXiv},
      url = {https://arxiv.org/abs/2306.00107}
    }

    @article{yuan2025yue,
      title = {{YuE}: Scaling Open Foundation Models for Long-Form Music Generation},
      author = {Yuan, Ruibin and Lin, Hanfeng and Guo, Shuyue and Zhang, Ge and Pan, Jiahao and Zang, Yongyi and Liu, Haohe and Liang, Yiming and Ma, Wenye and Du, Xingjian and Du, Xinrun and Ye, Zhen and Zheng, Tianyu and Jiang, Zhengxuan and Ma, Yinghao and Liu, Minghao and Tian, Zeyue and Zhou, Ziya and Xue, Liumeng and Qu, Xingwei and Li, Yizhi and Wu, Shangda and Shen, Tianhao and Ma, Ziyang and Zhan, Jun and Wang, Chunhui and Wang, Yatian and Chi, Xiaowei and Zhang, Xinyue and Yang, Zhenzhu and Wang, Xiangzhou and Liu, Shansong and Mei, Lingrui and Li, Peng and Wang, Junjie and Yu, Jianwei and Pang, Guojian and Li, Xu and Wang, Zihao and Zhou, Xiaohuan and Yu, Lijun and Benetos, Emmanouil and Chen, Yong and Lin, Chenghua and Chen, Xie and Xia, Gus and Zhang, Zhaoxiang and Zhang, Chao and Chen, Wenhu and Zhou, Xinyu and Qiu, Xipeng and Dannenberg, Roger and Liu, Jiaheng and Yang, Jian and Huang, Wenhao and Xue, Wei and Tan, Xu and Guo, Yike},
      journal = {arXiv preprint arXiv:2503.08638},
      year = {2025},
      eprint = {2503.08638},
      archivePrefix = {arXiv},
      url = {https://arxiv.org/abs/2503.08638}
    }
    ```
*   **MLX engine port:** the `YuE2-3B-MLX` conversion (`generate.py`, model modules) that this app wraps.
*   **CPU/GPU runtime:** [Apple MLX](https://github.com/ml-explore/mlx).

We're grateful to the open-source AI community for making local music generation possible.