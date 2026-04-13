# BatCave - Privacy & Security Setup

Your privacy batcave on Windows 11.

## Quick Start

### 1. Lock Down Windows
See: `WINDOWS-PRIVACY-LOCKDOWN.md`
- Disable telemetry
- Remove Copilot
- Block Bing
- Block telemetry at hosts level

### 2. Set Up Tor Browser
See: `TOR-SETUP.md`
- Download from torproject.org
- Verify GPG signature
- Configure security level to "Safest"
- Use bridges if needed

### 3. Deploy WireGuard VPN
See: `WIREGUARD-SETUP.md`
- Linux server (Raspberry Pi or VPS)
- Windows client
- Port forward UDP 51820

### 4. Deploy BatCave VPN Application
See: `BATCAVE-VPN-SPEC.md` for technical architecture
Run: `BATCAVE-VPN-CLI.ps1` for CLI

## Recommended Setup Order

1. **Windows lockdown** → reduces OS telemetry
2. **WireGuard VPN** → controls your exit point
3. **Tor Browser** → provides anonymity

### For "Privacy from Bad Guys"
```
Your Windows → WireGuard VPN → Tor Browser → Internet
```
- ISP sees: VPN connection only
- Tor sees: Your VPN IP
- Destination sees: Tor exit node

## Files

| File | Purpose |
|------|---------|
| `WINDOWS-PRIVACY-LOCKDOWN.md` | Windows 11 telemetry disable |
| `TOR-SETUP.md` | Tor Browser configuration |
| `WIREGUARD-SETUP.md` | Self-hosted VPN setup |
| `BATCAVE-VPN-SPEC.md` | VPN application architecture |
| `BATCAVE-VPN-CLI.ps1` | VPN CLI application |

## Warp AI - Private Assistant

Private local AI agent in Warp terminal for BatCave setup/advice.

### Setup
1. Run `cd warp-ai && .\setup-ollama.ps1` (uses llama3 via Ollama)
2. Warp: Cmd+, → AI → Agents → Import `warp-ai/WarpAI-Agent.md`
3. Chat: Cmd+i

Focus: VPN troubleshooting, privacy hardening, threat intel.

## Key Rules

- Never log into personal accounts in Tor
- Use "New Identity" frequently
- Don't download/open files from Tor
- Close Tor when done
- Keep Windows updated
