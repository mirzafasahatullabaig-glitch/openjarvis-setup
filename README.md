# openjarvis-setup

Reproducible setup for running [OpenJarvis](https://github.com/open-jarvis/openjarvis)
locally on this Windows machine, wired to **Ollama + qwen2.5:14b** (no cloud inference).

OpenJarvis itself installs into `%LOCALAPPDATA%\OpenJarvis` (its own cloned repo).
This repo holds only **our** pieces: the config and a setup script that captures
the install gotchas, so a reinstall is one command instead of a day of debugging.

## Install / reinstall

Run in an **elevated** PowerShell (the Build Tools step needs UAC):

```powershell
.\setup.ps1
```

It provisions Python 3.13, MSVC Build Tools, and Rust; runs the official
OpenJarvis installer with all three on PATH; copies `config.toml` to
`~/.openjarvis/`; and verifies with `jarvis doctor`.

## Run

Use the wrapper `run-jarvis.ps1` — it sets the whisper CUDA DLL path, the
context cap, and the npm flag, then passes your args through:

```powershell
.\run-jarvis.ps1 ask "..."        # one-shot question
.\run-jarvis.ps1 chat             # interactive looping chat
.\run-jarvis.ps1 chat --voice     # voice: mic (STT, GPU) + spoken reply (TTS)
.\run-jarvis.ps1 gui              # web UI at http://127.0.0.1:5173
.\run-jarvis.ps1 agent run "..."  # agent with file/shell/code tools
```

(Plain `jarvis <cmd>` also works from a fresh shell, but STT-on-GPU needs the
DLL path the wrapper sets, or it falls back with a cublas DLL error.)

**Voice:** STT = faster-whisper on **CUDA/NVIDIA** (needs `nvidia-cublas-cu12` +
`nvidia-cudnn-cu12` in the venv and their bin dirs on PATH — `run-jarvis.ps1`
handles the PATH; `setup.ps1` installs the libs). TTS = kokoro (CPU, `bm_george`).

**GPU:** LLM runs on the NVIDIA RTX 5050 via Ollama/CUDA. Default is `qwen2.5:7b`
(4.8GB, 100% GPU). `qwen2.5:14b` is 10GB so it spills ~38% to CPU on 8GB VRAM —
pick it only when you want max quality: `-m qwen2.5:14b`. The Intel UHD drives the
display (normal laptop hybrid-graphics); it is not used for inference.

**Safety:** confirm-before-each-action is the default — tools that run shell
commands, write files, or execute code prompt `[y/N]` (default No). Press `y`
to allow. `--auto-approve` disables prompts (not recommended).

## Gotchas this setup solves

Hit on the first install (2026-11-16), all encoded in `setup.ps1` / `config.toml`:

| Problem | Fix |
|---|---|
| Installer rejects Python 3.14 | Uses 3.13 (installer auto-pulls it) |
| MSVC `link.exe` not found | Install VS 2022 Build Tools (VCTools workload); run installer under `vcvars64` |
| Bundled Rust installer corrupts its download | Install real `rustup`; pre-pin toolchain `1.89` |
| Router uses NVIDIA NIM **cloud** (404) | `[intelligence] preferred_engine = "ollama"` |
| Ollama shows "Unreachable" though it's running | `[engine.ollama] host` defaults to `""` — set it explicitly |

## Model choice

`qwen2.5:14b` (Q4, ~9 GB, fits the RTX 5050 8 GB) — it beat a 2-bit 40B model
in a bake-off on this hardware (faster, more reliable). See the benchmark memory note.
