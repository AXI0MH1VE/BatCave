# WireGuard VPN Setup - BatCave

## Overview

WireGuard is a modern, fast VPN protocol. You'll need:
- A Linux server (VPS or home Raspberry Pi)
- Windows 11 client

---

## Part 1: Linux VPN Server

### Option A: Raspberry Pi (Recommended for Home)

```bash
# On Raspberry Pi (or any Linux)
curl -L https://install.pivpn.io | bash
```

Follow prompts:
- Choose **WireGuard**
- Set static IP
- Use UDP port **51820**

### Option B: Manual WireGuard

```bash
# Install
sudo apt install wireguard -y

# Generate keys
umask 077
wg genkey | tee private.key | wg pubkey > public.key
```

Create `/etc/wireguard/wg0.conf`:

```ini
[Interface]
PrivateKey = <paste-server-private-key>
Address = 10.8.0.1/24
ListenPort = 51820

# NAT - allows VPN clients to use server's internet
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
# Windows client - generated public key
PublicKey = <paste-windows-client-public-key>
AllowedIPs = 10.8.0.2/32
PersistentKeepalive = 25
```

Enable and start:
```bash
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
```

---

## Part 2: Windows Client

### 1. Install WireGuard
- Download: **wireguard.com** (official Windows installer)
- Install the application

### 2. Generate Client Keys
```powershell
# In PowerShell or Command Prompt (or use WireGuard app)
wg genkey | tee client-private.key | wg pubkey > client-public.key
```

### 3. Create Client Config

Create file `windows-client.conf`:

```ini
[Interface]
PrivateKey = <paste-your-client-private-key>
Address = 10.8.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = <paste-server-public-key>
Endpoint = your-ddns-address.ddns.net:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

### 4. Import Config
1. Open WireGuard app
2. Click "Import tunnel from file"
3. Select your `.conf` file
4. Click "Activate"

---

## Part 3: Router Setup

### Port Forwarding
Forward **UDP 51820** → to your Linux server's internal IP

Example (typical router):
- External Port: 51820
- Protocol: UDP
- Internal IP: 192.168.1.50 (your Linux server)
- Internal Port: 51820

### Dynamic DNS (If No Static IP)
Use **DuckDNS** (free):
1. Go to duckdns.org
2. Sign in with GitHub/Google
3. Create subdomain (e.g., `mybatcave.duckdns.org`)
4. Install DDNS updater on your Linux server

---

## Part 4: Testing

### Check Connection
```bash
# On server
sudo wg show
```

Should show connected peer with latest handshake.

### Verify IP Change
On Windows, visit **whatismyip.com** - should show your VPN server's IP.

### Test Kill Switch
1. Disconnect internet momentarily
2. Reconnect - VPN should auto-reconnect

---

## Security Hardening

### Firewall on Server
```bash
# Allow only VPN port
sudo ufw allow 51820/udp
sudo ufw enable
```

### Rate Limiting (Optional)
```bash
# Block UDP port scans
sudo iptables -A INPUT -p udp --dport 51820 -m state --state NEW -m limit --limit 5/min --limit-burst 10 -j ACCEPT
```

---

## VPN + Tor Integration

### VPN → Tor (Hide from ISP)
```
[Interface]
PrivateKey = <client-key>
Address = 10.8.0.2/24

[Peer]
PublicKey = <server-key>
Endpoint = your-server.duckdns.org:51820
AllowedIPs = 0.0.0.0/0  # ALL traffic through VPN
```

Then open Tor Browser - Tor sees VPN IP, not your home IP.

### VPN Only (No Tor)
Same config, just don't open Tor Browser.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Can't connect | Check router port forward (UDP 51820) |
| No internet | Verify `PostUp` NAT rules in server config |
| Slow speed | Your upload speed is the limit |
| Connection drops | Add `PersistentKeepalive = 25` |