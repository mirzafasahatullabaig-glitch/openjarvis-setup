# Launch OpenJarvis with the environment it needs on this machine, then pass
# through whatever args you give (e.g.  .\run-jarvis.ps1 chat --voice).
#
# Why this wrapper exists:
#  - faster-whisper (STT on CUDA) needs the venv's nvidia cublas/cudnn DLLs on
#    PATH *before* launch, or it fails with "cublas64_12.dll not found".
#  - JARVIS_NUM_CTX caps the Ollama context so models fit 8GB VRAM (GUI would
#    otherwise default to 16k and spill to CPU).
#  - npm engine-strict off so `jarvis gui` installs its frontend on Node 24.

$nv = "$HOME\AppData\Local\OpenJarvis\src\.venv\Lib\site-packages\nvidia"
$env:PATH = "$nv\cublas\bin;$nv\cudnn\bin;$nv\cuda_nvrtc\bin;" + $env:PATH
$env:JARVIS_NUM_CTX = "4096"
$env:npm_config_engine_strict = "false"

& "$HOME\AppData\Local\OpenJarvis\bin\jarvis.cmd" @args
