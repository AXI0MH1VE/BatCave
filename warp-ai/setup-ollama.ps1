# BatCave Warp AI - Ollama Setup
# Ensures local LLM backend for private Warp AI agent

Write-Host "Setting up Ollama for Warp AI (llama3 model)..."

# Check if Ollama installed/running (AppData/Local/Ollama exists)
if (Test-Path "$env:LOCALAPPDATA\Ollama") {
    Write-Host "Ollama detected."
} else {
    Write-Host "Ollama not found. Download from ollama.com (manual step for privacy)."
    return
}

# Start Ollama service if not running
& ollama serve 2>$null

Start-Sleep 3

# Pull llama3 model (8B, good balance speed/privacy)
ollama pull llama3

Write-Host "Ollama/llama3 ready for Warp AI."
Write-Host "Import warp-ai/WarpAI-Agent.md in Warp settings."

