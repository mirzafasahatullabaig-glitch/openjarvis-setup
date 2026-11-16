# OpenJarvis reproducible setup for this Windows machine.
# Captures every gotcha hit during the first install (2026-11-16) so a
# reinstall doesn't repeat the debugging. Run in an ELEVATED PowerShell
# for the Build Tools step (UAC prompt).
#
# Prereqs the OpenJarvis installer needs but doesn't reliably self-provision
# on this box: Python 3.10-3.13 (NOT 3.14), MSVC Build Tools, a real Rust
# toolchain. We provision them first, then run their installer with all three
# on PATH.

$ErrorActionPreference = "Stop"
$PY313 = "C:\Users\mirza\AppData\Local\Programs\Python\Python313"
$CARGO = "C:\Users\mirza\.cargo\bin"
$VCVARS = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

Write-Host "[1/5] MSVC Build Tools (needed to compile the mandatory Rust extension)..."
if (-not (Test-Path $VCVARS)) {
    winget install --id Microsoft.VisualStudio.2022.BuildTools `
        --override "--wait --quiet --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
} else { Write-Host "  already present" }

Write-Host "[2/5] Rust toolchain (bundled puccinialin auto-installer corrupts its download; use real rustup)..."
if (-not (Test-Path "$CARGO\cargo.exe")) {
    $init = "$env:TEMP\rustup-init.exe"
    Invoke-WebRequest "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe" -OutFile $init
    & $init -y --default-toolchain stable --profile default
} else { Write-Host "  rustup already present" }

Write-Host "[3/5] Pin the crate's required Rust toolchain (1.89) so maturin doesn't re-download it..."
& "$CARGO\rustup.exe" toolchain install 1.89-x86_64-pc-windows-msvc

Write-Host "[4/5] Run the OpenJarvis installer with Python 3.13 + MSVC + Rust all on PATH..."
# vcvars64 sets MSVC env; we prepend Python 3.13 and cargo so the installer's
# checks pass and the real cargo is used (not the broken temp one).
& cmd /c "set `"PATH=$PY313;$PY313\Scripts;$CARGO;%PATH%`" && `"$VCVARS`" >nul && powershell -NoProfile -Command `"irm https://open-jarvis.github.io/OpenJarvis/install.ps1 | iex`""

Write-Host "[5/5] Install our config, then verify..."
$cfgDir = "$HOME\.openjarvis"
if (-not (Test-Path $cfgDir)) { New-Item -ItemType Directory $cfgDir | Out-Null }
Copy-Item "$PSScriptRoot\config.toml" "$cfgDir\config.toml" -Force

$jarvis = "$HOME\AppData\Local\OpenJarvis\bin\jarvis.cmd"
# self-check: config must parse and the ollama engine must be reachable
$doctor = & $jarvis doctor 2>&1 | Out-String
if ($doctor -match "Config loaded successfully" -and $doctor -match "Engine: ollama\s*\│\s*Reachable") {
    Write-Host "`nOK — OpenJarvis ready. Try:  jarvis chat" -ForegroundColor Green
} else {
    Write-Warning "Verification failed. Run '$jarvis doctor' and check Config/Ollama rows."
    exit 1
}
