#!/usr/bin/env python3
"""YuE2Mac Pro engine add-on — a thin superset over the stock generate.py.

Extends the upstream engine (downloaded from Hugging Face during setup, never
modified) with what YuE2Mac's Pro mode needs:

  * sampling overrides: temperature / top-p / top-k / repetition penalty
  * a saved "song project" (`<out>.tokens.json`: prefix + codec + seed + settings)
    — the semantic tokens the upstream pipeline already computes before NAR
  * `finish`: re-render an 8-step draft at full quality from the saved tokens,
    reusing the same seed so the composition itself is preserved
  * an explicit `[load]` stage so the UI can show model loading

stderr protocol is unchanged from generate.py:
  [load] … [plan] … [semantic] N tokens, X tok/s … [nar] step i/n … [vae] … [done]
plus one addition: [error] <message> for clean failure reporting.

Usage:
  python yue2_pro.py generate --model DIR --style S --lyrics L --cot full \
      --seed N --cfg-scale F --steps N --max-semantic-tokens N \
      [--temperature F] [--top-p F] [--top-k N] [--rep-penalty F] \
      [--abc-file FILE] --out song.wav
  python yue2_pro.py finish --model DIR --project song.tokens.json \
      --steps 32 --out song-full.wav
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

import numpy as np

from generate import SAMPLE_RATE, Sampling, Yue2Pipeline, synthesize, write_wav

PROJECT_VERSION = 1


def log(msg: str) -> None:
    print(msg, file=sys.stderr, flush=True)


def build_sampling(pipe: Yue2Pipeline, args) -> Sampling:
    """The stock CLI only exposes --max-semantic-tokens; we expose the rest."""
    base = dict(pipe.semantic_sampling.__dict__)
    base["max_tokens"] = args.max_semantic_tokens
    base["min_tokens"] = min(base["min_tokens"], args.max_semantic_tokens)
    if args.temperature is not None:
        base["temperature"] = args.temperature
    if args.top_p is not None:
        base["top_p"] = args.top_p
    if args.top_k is not None:
        base["top_k"] = args.top_k
    if args.rep_penalty is not None:
        base["repetition_penalty"] = args.rep_penalty
    return Sampling(**base)


def project_path(out: Path) -> Path:
    return out.with_name(out.stem + ".tokens.json")


def latents_path(out: Path) -> Path:
    return out.with_name(out.stem + ".latents.npy")


def save_project(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data))


def load_model(args):
    log("[load] loading model")
    return Yue2Pipeline(args.model, log=log)


def cmd_generate(args) -> int:
    started = time.perf_counter()
    pipe = load_model(args)
    sampling = build_sampling(pipe, args)
    abc = Path(args.abc_file).read_text() if args.abc_file else None

    def on_latents(z):
        np.save(latents_path(args.out), np.array(z))

    audio, info = pipe(
        args.style, args.lyrics, cot=args.cot, seed=args.seed, abc=abc,
        cfg_scale=args.cfg_scale, semantic_sampling=sampling, steps=args.steps,
        on_latents=on_latents,
    )
    write_wav(args.out, audio)
    if info["abc"] is not None:
        args.out.with_name(args.out.stem + ".abc").write_text(info["abc"])
    save_project(project_path(args.out), {
        "version": PROJECT_VERSION,
        "kind": "generate",
        "style": args.style,
        "lyrics": args.lyrics,
        "cot": args.cot,
        "seed": args.seed,
        "cfg_scale": args.cfg_scale,
        "steps": args.steps,
        "sampling": {k: v for k, v in sampling.__dict__.items()},
        "abc": info["abc"],
        "prefix": info["prefix"],
        "codec": info["codec"],
    })
    elapsed = time.perf_counter() - started
    log(f"[done] {args.out} {audio.shape[0] / SAMPLE_RATE:.1f}s in {elapsed:.0f}s")
    return 0


def cmd_finish(args) -> int:
    """Re-run NAR + VAE from a saved project: same tokens, same seed, more steps."""
    started = time.perf_counter()
    project = json.loads(Path(args.project).read_text())
    codec, prefix, seed = project["codec"], project["prefix"], project["seed"]
    if not codec:
        log("[error] project has no codec tokens")
        return 1
    pipe = load_model(args)
    log(f"[nar] finishing {len(codec)} frames with {args.steps} steps "
        f"(seed {seed}, tokens reused — same composition)")
    latents = synthesize(
        pipe.model, prefix, codec, seed, steps=args.steps,
        on_progress=lambda i, n: i % 8 == 0 and log(f"[nar] step {i}/{n}"),
    )
    np.save(latents_path(args.out), np.array(latents))
    log("[vae] decoding")
    audio = pipe.decode(latents)
    write_wav(args.out, audio)
    finished = dict(project)
    finished["kind"] = "finish"
    finished["steps"] = args.steps
    save_project(project_path(args.out), finished)
    elapsed = time.perf_counter() - started
    log(f"[done] {args.out} {audio.shape[0] / SAMPLE_RATE:.1f}s in {elapsed:.0f}s")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="YuE2Mac Pro engine add-on")
    sub = parser.add_subparsers(dest="command", required=True)

    gen = sub.add_parser("generate", help="full pipeline; saves the song project")
    gen.add_argument("--model", type=Path, required=True)
    gen.add_argument("--style", required=True)
    gen.add_argument("--lyrics", required=True)
    gen.add_argument("--cot", default="full", choices=["off", "melody", "full"])
    gen.add_argument("--abc-file", type=Path)
    gen.add_argument("--seed", type=int, default=831001)
    gen.add_argument("--cfg-scale", type=float)
    gen.add_argument("--steps", type=int)
    gen.add_argument("--max-semantic-tokens", type=int, required=True)
    gen.add_argument("--temperature", type=float)
    gen.add_argument("--top-p", type=float)
    gen.add_argument("--top-k", type=int)
    gen.add_argument("--rep-penalty", type=float)
    gen.add_argument("--out", type=Path, required=True)
    gen.set_defaults(func=cmd_generate)

    fin = sub.add_parser("finish", help="re-render a saved project at new quality")
    fin.add_argument("--model", type=Path, required=True)
    fin.add_argument("--project", type=Path, required=True)
    fin.add_argument("--steps", type=int, default=32)
    fin.add_argument("--out", type=Path, required=True)
    fin.set_defaults(func=cmd_finish)

    args = parser.parse_args()
    try:
        return args.func(args)
    except KeyboardInterrupt:
        log("[error] interrupted")
        return 130
    except Exception as e:  # surface a clean, single-line failure to the UI
        log(f"[error] {type(e).__name__}: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
