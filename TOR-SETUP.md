# Tor Browser Setup - BatCave

## Download & Verify

1. Go to: **torproject.org/download**
2. Download the Windows installer
3. **Verify GPG signature** before running

### Verify Signature (PowerShell)
```powershell
# Install GPG if needed
winget install GnuPG.GnuPG

# Verify the .exe
gpg --verify torbrowser-install-win64-*.exe.asc torbrowser-install-win64-*.exe
```

---

## Initial Configuration

### Security Level
Tor Browser → Settings → Privacy & Security → Security Level

| Level | What It Does |
|-------|-------------|
| Standard | JS enabled, some fonts |
| Safer | JS disabled on HTTP sites |
| Safest | JS disabled globally, minimal features |

**Recommendation**: Use **Safest** for sensitive browsing.

---

## Critical Settings (about:config)

Type `about:config` in address bar, press Enter, then set:

| Setting | Value | Why |
|---------|-------|-----|
| `javascript.enabled` | false | Prevent fingerprinting |
| `media.peerconnection.enabled` | false | Blocks WebRTC (leaks IP) |
| `network.proxy.socks_remote_dns` | true | DNS through Tor |
| `webgl.disabled` | true | Block WebGL fingerprinting |

### Enable HTTPS Only Mode
Settings → Privacy & Security → HTTPS-Only Mode → **Enable** (forces HTTPS)

---

## Privacy Settings

### Browser Settings
- [ ] Never remember history
- [ ] Delete cookies and site data when Tor Browser closes
- [ ] Clear history on close (set in Privacy & Security)

### New Identity
Use "New Identity" button frequently to:
- Clear cookies
- Clear cache
- Reset browsing sessions

---

## Behavioral Rules

| ✅ Do | ❌ Don't |
|-------|----------|
| Use DuckDuckGo (onion) | Log into personal email |
| Close browser when done | Download files to open |
| Use new pseudonym each session | Provide real name/info |
| Enable "New Identity" between tasks | Maximize window (fingerprint) |
| Check for onion icon (🔒) | Use HTTP sites |

---

## Network Obfuscation (Bridges)

If Tor is blocked in your area:

1. Click Configure Connections
2. Select "Tor is censored in my country"
3. Choose a bridge type:
   - **obfs4** - Most common
   - **meek-azure** - Works in heavy censorship
   - **snowflake** - Good for bypass

---

## Testing Your Tor Connection

1. Visit: **check.torproject.org**
2. Should show "Tor is ready"
3. Verify your IP is different from real IP
4. Check for DNS leaks: **dnsleaktest.com**

---

## Recommended Addons (Minimal)

**Do NOT install extra extensions** - they break Tor's fingerprinting protection.

Only use what's bundled:
- NoScript (built-in)
- HTTPS Everywhere (built-in)

---

## For VPN + Tor Ordering

### VPN → Tor (Recommended for ISP hiding)
```
Your Device → Your WireGuard VPN → Tor → Internet
```

This hides Tor usage from your ISP.

### Configuration
1. Connect WireGuard VPN first
2. Open Tor Browser
3. Test at check.torproject.org