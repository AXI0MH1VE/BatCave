# BatCave Privacy VPN - Technical Specification

## 1. System Architecture

### 1.1 High-Level Design

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────────┐
│   Client   │────▶│  Filtering │────▶│  WireGuard │────▶│    Tor     │
│  Device   │     │   Server   │     │   VPN     │     │   Network  │
│ (Windows) │     │ (Local)    │     │  (Tunnel) │     │  (SOCKS5)  │
└─────────────┘     └──────────────┘     └─────────────┘     └──────────────┘
       │                   │                   │                   │
       │                   │                   ▼                   │
       │                   │            ┌──────────────┐
       │                   │            │  Internet   │
       │                   │            │ (Final Exit) │
       └─────────────────┴────────────┴──────────────┘
```

### 1.2 Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      CLIENT APPLICATION                        │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │
│  │   UI/CLI   │  │  Config     │  │  Monitoring    │ │
│  │  Module   │  │  Manager   │  │  Dashboard    │ │
│  └─────────────┘  └─────────────┘  └─────────────────┘ │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────┐   │
│  │           FILTERING SERVER (Local)               │   │
│  │  - PII Stripping Engine                      │   │
│  │  - DNS Sanitizer                            │   │
│  │  - Metadata Scrubber                       │   │
│  │  - Packet Normalizer                      │   │
│  └─────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────┐   │
│  │           ROUTING LAYER                    │   │
│  │  - WireGuard Tunnel (UDP/51820)             │   │
│  │  - Tor SOCKS5 Bridge (9050/9051)           │   │
│  │  - Failover Manager                        │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 Node Types

| Node Type | Role | Requirements |
|----------|------|-------------|
| **Entry Node** | Client connection point | WireGuard server |
| **Filtering Node** | PII stripping | Local or close to client |
| **Bridge Node** | Tor + SOCKS5 | Dedicated server |
| **Exit Node** | Final internet gateway | Tor exit relay |

---

## 2. Encryption Standards

### 2.1 WireGuard (Layer 1)

| Parameter | Value | Standard |
|-----------|-------|----------|
| **Cipher** | ChaCha20-Poly1305 | RFC 8439 |
| **Key Exchange** | Curve25519 | RFC 7748 |
| **Hash** | BLAKE2s | RFC 7693 |
| **DH Groups** | X25519 | RFC 7748 |

```wireguard
# WireGuard Server Config
[Interface]
PrivateKey = <server-private-key>
Address = 10.8.0.1/24
ListenPort = 51820

# Modern cipher suite
PostUp = wg set wg0 peer <peer-key> preshared-key <additional-preshared-key>
```

### 2.2 Tor Encryption (Layer 2)

| Parameter | Value | Standard |
|-----------|-------|----------|
| **Cell Encryption** | AES-256-CTR | Tor spec |
| **Link Handshake** | TLS 1.3 | RFC 8446 |
| **Circuit Keys** | TAP/Tor negotiation | Tor spec |

### 2.3 Local Filtering

```python
# PII Stripping Rules
PII_PATTERNS = {
    'email': r'[\w.-]+@[\w.-]+\.\w+',
    'phone': r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b',
    'ssn': r'\b\d{3}-\d{2}-\d{4}\b',
    'ip': r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b',
    'mac': r'([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})'
}
```

---

## 3. Authentication Methods

### 3.1 Client Authentication

| Method | Use Case | Security Level |
|--------|---------|--------------|
| **WireGuard Key Pair** | Primary | High |
| **QR Code** | Mobile setup | High |
| **TOTP** | 2FA backup | Very High |
| **Password + Certificate** | Legacy fallback | Medium |

### 3.2 Config Schema

```yaml
# config.yaml
authentication:
  primary:
    type: wireguard_keypair
    key_file: ~/.batcave/keys/client.key
    
  two_factor:
    enabled: true
    type: totp
    secret_file: ~/.batcave/keys/totp.secret
    
  certificate:
    enabled: false
    ca: ~/.batcave/certs/ca.crt
```

---

## 4. Filtering Server Specification

### 4.1 PII Stripping Engine

```python
class PIIStrippingEngine:
    def __init__(self):
        self.patterns = PII_PATTERNS
        self.replacements = {
            'email': '[EMAIL_REDACTED]',
            'phone': '[PHONE_REDACTED]',
            'ssn': '[SSN_REDACTED]',
            'ip': '[IP_REDACTED]',
            'mac': '[MAC_REDACTED]'
        }
        
    def process_packet(self, packet):
        """Strip PII from packet payload"""
        for pattern, replacement in self.replacements.items():
            packet.payload = re.sub(
                self.patterns[pattern],
                replacement,
                packet.payload
            )
        return packet
    
    def process_dns(self, query):
        """Sanitize DNS queries"""
        # Remove unique identifiers
        query.id = 0x0000  # Reset DNS transaction ID
        return query
```

### 4.2 Metadata Scrubber

| Field | Action |
|-------|-------|
| **X-Forwarded-For** | Remove or obfuscate |
| **User-Agent** | Generic or remove |
| **Referer** | Strip path, keep domain |
| **Via headers** | Remove |
| **Client-IP in headers** | Remove |
| **Geo-location** | Remove |

### 4.3 Packet Normalizer

```python
class PacketNormalizer:
    def __init__(self):
        self.target_mtu = 1400
        self.target_ttl = 64
        
    def normalize(self, packet):
        """Standardize packet characteristics"""
        # Fixed packet size
        packet.size = self._pad_to_multiple(packet.size, 128)
        
        # Standard TTL
        packet.ttl = self.target_ttl
        
        # Remove timing information
        packet.timestamp = 0
        
        return packet
```

---

## 5. Latency & Bandwidth Optimization

### 5.1 Latency Optimization

| Technique | Expected Gain |
|-----------|------------|
| **WireGuard kernel module** | 2-5ms reduction vs OpenVPN |
| **Congestion control: BBR** | 10-30% faster |
| **MTU optimization** | Reduced fragmentation |
| **Connection keepalive** | Maintain warm pipes |
| **Pre-resolve Tor circuits** | Faster reconnection |

### 5.2 Bandwidth Optimization

| Technique | Expected Gain |
|-----------|------------|
| **Compression (optional)** | 30-60% on compressible data |
| **Packet batching** | 10-20% overhead reduction |
| **Buffer tuning** | Reduced packet loss |

### 5.3 Config Optimizations

```yaml
# Network optimization config
network:
  wireguard:
    listen_port: 51820
    firewall_mark: 0x10000
    mtu: 1400
    
  tor:
    socks_port: 9050
    control_port: 9051
    circuit_build_timeout: 60
    num_entry_guards: 8
    
  optimization:
    tcp_congestion_control: bbr
    enable_keepalive: true
    keepalive_interval: 25
    buffer_sizes:
      send: 262144
      recv: 262144
```

---

## 6. Failover Mechanisms

### 6.1 Failure Detection

```python
class FailoverManager:
    def __init__(self):
        self.health_checks = {
            'wireguard': self._check_wireguard,
            'tor': self._check_tor,
            'internet': self._check_internet
        }
        self.thresholds = {
            'latency_ms': 5000,
            'packet_loss': 10,
            'timeout_seconds': 30
        }
        
    def _check_wireguard(self):
        """Verify WireGuard tunnel is active"""
        result = subprocess.run(
            ['wg', 'show'],
            capture_output=True
        )
        return result.returncode == 0
        
    def _check_tor(self):
        """Verify Tor circuit exists"""
        # Try to fetch from Tor network
        try:
            response = requests.get(
                'https://check.torproject.org',
                proxies={
                    'http': 'socks5://127.0.0.1:9050',
                    'https': 'socks5://127.0.0.1:9050'
                },
                timeout=30
            )
            return 'IP' in response.text
        except:
            return False
```

### 6.2 Failover Paths

| Primary | Backup 1 | Backup 2 |
|--------|----------|----------|
| WireGuard → Tor | Direct Tor | OBFS4 Bridge → Tor |
| Main VPN | Alternate VPN | No VPN (Tor only) |

### 6.3 Auto-Failover Config

```yaml
failover:
  enabled: true
  check_interval: 10
  retry_attempts: 3
  circuit_breaker:
    latency_threshold_ms: 5000
    error_threshold: 5
    
  paths:
    - name: full_stack
      path: wireguard -> tor -> internet
      enabled: true
      
    - name: tor_only  
      path: tor -> internet
      enabled: true
      
    - name: tor_bridge
      path: obfs4 -> tor -> internet
      enabled: true
```

---

## 7. User Interface

### 7.1 CLI Interface

```bash
# BatCave VPN CLI
$ batcave status
Status: Connected
- WireGuard: Active (10.8.0.2)
- Tor: Active (SOCKS5 9050)
- Exit: us-east-1-exit
- PII Filter: Active

$ batcave connect --full-stack
Connecting to BatCave VPN...
✓ WireGuard connected
✓ PII Filter started
✓ Tor circuit built
✓ Full stack active

$ batcave disconnect
Disconnecting...
✓ Disconnected
```

### 7.2 Dashboard Components

| Component | Function |
|----------|----------|
| **Connection Status** | Active/inactive indicator |
| **Server Selection** | Choose exit node |
| **Bandwidth Graph** | Real-time throughput |
| **Latency Display** | Connection latency |
| **Circuit Info** | Current Tor nodes |
| **Kill Switch** | Emergency disconnect |
| **Statistics** | Session data |

### 7.3 Configuration UI

```python
# GUI config structure (tkinter/web)
class BatCaveGUI:
    def __init__(self):
        self.window = tk.Window("BatCave Privacy VPN")
        self.setup_ui()
        
    def setup_ui(self):
        # Connection panel
        self.status_label = tk.Label(text="Disconnected")
        self.connect_button = tk.Button(
            text="Connect",
            command=self.toggle_connection
        )
        
        # Server selection
        self.server_var = tk.StringVar()
        self.server_dropdown = ttk.Combobox(
            values=['Full Stack', 'Tor Only', 'Bridge'],
            textvariable=self.server_var
        )
        
        # Stats panel
        self.bandwidth_label = tk.Label(text="↑ 0 KB/s ↓ 0 KB/s")
        self.latency_label = tk.Label(text="Latency: -- ms")
        
        # Kill switch toggle
        self.kill_switch_var = tk.BooleanVar()
        self.kill_switch = tk.Checkbutton(
            text="Kill Switch",
            variable=self.kill_switch_var
        )
```

---

## 8. Cross-Platform Compatibility

### 8.1 Supported Platforms

| Platform | Support Level |
|----------|--------------|
| **Windows 10/11** | Full |
| **macOS** | Full |
| **Linux** | Full |
| **iOS** | Partial (UI only) |
| **Android** | Partial (UI only) |

### 8.2 Platform-Specific Notes

| Platform | Considerations |
|----------|-------------|
| **Windows** | WireGuard Wintun adapter, Windows Firewall rules |
| **macOS** | WireGuard kernel extension, System Extensions |
| **Linux** | WireGuard in-kernel, iptables/nftables |
| **Mobile** | No local filtering, relies on server |

### 8.3 Build Targets

```yaml
# Build configuration
build:
  targets:
    - name: windows
      arch: amd64
      output: batcave-windows-x64.exe
      
    - name: macos
      arch: arm64,amd64
      output: batcave-macos
      
    - name: linux
      arch: amd64,arm64
      output: batcave-linux
      
  dependencies:
    - wireguard-windows (wintun)
    - tor (embedded or system)
    - golang.org/x/crypto
```

---

## 9. Open-Source Licensing

### 9.1 License Selection

**Recommended: GPL v3**

- Copyleft license
- Requires source disclosure
- Compatible with Tor (LGPL compatible)
- Industry standard for privacy tools

### 9.2 Components & Licenses

| Component | License | Notes |
|----------|---------|-------|
| **BatCave Core** | GPL v3 | Your code |
| **WireGuard** | GPL v2 | Kernel module |
| **Tor** | BSD/LGPL | Built-in |
| **Go stdlib** | BSD | Runtime |

### 9.3 Repository Structure

```
batcave-vpn/
├── LICENSE                 # GPL v3
├── README.md
├── cmd/
│   ├── batcave-cli        # CLI application
│   ├── batcave-gui       # GUI application
│   └── batcave-service   # System service
├── pkg/
│   ├── filtering        # PII stripping
│   ├── routing          # WireGuard + Tor
│   ├── failover        # Failover logic
│   └── config          # Configuration
├── ui/
│   ├── cli              # CLI views
│   └── web             # Web dashboard
└── docs/
    ├── ARCHITECTURE.md
    ├── SECURITY.md
    └── COMPLIANCE.md
```

---

## 10. Privacy Compliance

### 10.1 GDPR (EU)

| Requirement | Implementation |
|-------------|---------------|
| **Data minimization** | PII filtering strips personal data |
| **Purpose limitation** | Traffic only, no logging |
| **Storage limitation** | No persistent logs |
| **Right to erasure** | All data in RAM only |
| **Data protection** | Encryption at rest and in transit |

### 10.2 CCPA (California)

| Requirement | Implementation |
|-------------|---------------|
| **Right to know** | No personal data collected |
| **Right to delete** | All data ephemeral |
| **Right to opt-out** | No data sold |

### 10.3 Compliance Checklist

```yaml
# Compliance configuration
compliance:
  gdpr:
    data_minimization: true
    encryption_at_rest: true
    no_persistent_logs: true
    right_to_erasure: automatic
    
  ccpa:
    no_sale_of_data: true
    opt_out_supported: true
    
  logging:
    level: none  # No logs by default
    in_memory: true
    no_disk_write: true
```

---

## 11. Implementation Priority

### Phase 1: Core VPN
- [ ] WireGuard tunnel
- [ ] Basic Tor integration
- [ ] CLI interface

### Phase 2: Filtering
- [ ] PII stripping engine
- [ ] Metadata scrubber
- [ ] DNS sanitizer

### Phase 3: Resilience
- [ ] Failover system
- [ ] Health checks
- [ ] Auto-recovery

### Phase 4: UI
- [ ] Dashboard
- [ ] Monitoring
- [ ] Configuration

### Phase 5: Compliance
- [ ] Audit logging
- [ ] GDPR controls
- [ ] Documentation