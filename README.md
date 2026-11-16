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

In a **fresh** PowerShell (so `jarvis` is on PATH):

```powershell
jarvis ask "..."          # one-shot question
jarvis chat               # interactive looping chat
jarvis agent run "..."    # agent with file/shell/code tools
```

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
