# Windows 11 Privacy Lockdown - BatCave

## Step 1: Core Privacy Settings (Do First)

### Open Settings → Privacy & Security

| Setting | Action |
|---------|--------|
| **Diagnostics & feedback** | Set to "Required only" |
| **Tailored experiences** | OFF |
| **Advertising ID** | OFF |
| **Let apps access advertising ID** | OFF |
| **Improve Start & search results** | OFF |
| **Show search highlights** | OFF |

### Disable Location, Camera, Mic for Apps
- Review each app under Privacy & Security
- Disable location/camera/mic for apps that don't need it

---

## Step 2: Disable Copilot

```powershell
# Run as Administrator in PowerShell
Get-AppxPackage -Name Microsoft.Copilot* | Remove-AppxPackage
```

Or via Registry:
```
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
```
Set `SkipCopilot` = 1 (DWORD)

---

## Step 3: Disable Bing in Search

```reg
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search]
"BingSearchEnabled"=dword:0
"CortanaConsent"=dword:0
```

---

## Step 4: Disable Telemetry (Group Policy)

Press `Win + R` → type `gpedit.msc`

Navigate to:
```
Computer Configuration → Administrative Templates → Windows Components → Data Collection and Preview Builds
```

Set **Allow Diagnostic Data** = Disabled

---

## Step 5: Block Telemetry at Network Level

Edit `C:\Windows\System32\drivers\etc\hosts` as Administrator:

```hosts
127.0.0.1 vortex.data.microsoft.com
127.0.0.1 vortex-win.data.microsoft.com
127.0.0.1 telecommand.telemetry.microsoft.com
127.0.0.1 oa.telemetry.microsoft.com
127.0.0.1 settings-win.data.microsoft.com
127.0.0.1 compatexchange1.trafficmanager.net
127.0.0.1 watson.telemetry.microsoft.com
127.0.0.1 ceuswatcab02.blob.core.windows.net
127.0.0.1 ceuswatcab01.blob.core.windows.net
```

---

## Step 6: Disable Services (Advanced)

Press `Win + R` → `services.msc`

Set these to **Disabled**:

| Service | Description |
|---------|-------------|
| Connected User Experiences and Telemetry | Telemetry |
| DiagTrack | Diagnostics tracking |
| WAP Push Service | Push notifications |
| Windows Search | Indexing |

⚠️ **Warning**: Disabling Windows Search may break Start menu search.

---

## Step 7: Recommended Tool - O&O ShutUp10++

Download: https://www.oo-software.com/shutup10

- Run as Administrator
- Select "Apply recommended settings"
- No installation needed (portable)

---

## Verification

After lockdown, run:

```powershell
# Check telemetry connections
netstat -an | findstr ":443" | findstr "ESTABLISHED"

# Check for data being sent
powershell -Command "Get-NetTCPConnection -State Established | Where-Object {$_.RemotePort -eq 443}"
```

---

## Post-Update Checklist

After Windows feature updates, re-verify:
- [ ] Recall still disabled
- [ ] Telemetry settings intact
- [ ] Copilot removed
- [ ] Bing search disabled