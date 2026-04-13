# Origin IP Hunter - Enhanced Edition v2.0

**Professional-Grade OSINT Reconnaissance Tool with Advanced Features**

This is the enhanced version of Origin IP Hunter, featuring integration with cutting-edge OSINT tools and multiple advanced data sources for maximum effectiveness in discovering origin IPs behind CDN/WAF protections.

---

## 🚀 What's New in v2.0

### Enhanced Passive Reconnaissance

**theHarvester Integration:** Comprehensive OSINT gathering from 40+ sources including search engines, certificate logs, and threat intelligence platforms. Automatically extracts emails, subdomains, and IP addresses.

**Advanced Subdomain Enumeration:** Integrates multiple tools:
- **Amass:** Deep subdomain discovery with DNS enumeration
- **Assetfinder:** Fast subdomain discovery from multiple sources
- **Subfinder:** ProjectDiscovery's powerful subdomain finder
- **altdns:** Pattern-based subdomain discovery for dev/staging/test environments

**Multiple Passive DNS Sources:**
- ViewDNS.info - Historical DNS records
- HackerTarget - DNS history and host search
- RapidDNS - Quick DNS history lookup
- CIRCL - Passive DNS database
- SecurityTrails - Comprehensive historical DNS (premium)

**JARM Fingerprinting:** TLS fingerprinting for identifying similar servers and finding origin IPs through Shodan searches.

**Advanced ASN Extraction:**
- ipinfo.io - ASN information and IP ranges
- asnmap - ProjectDiscovery's ASN mapping tool
- Automatic CIDR range extraction

### Enhanced Active Reconnaissance

**Subdomain Takeover Detection:** Identifies vulnerable subdomains pointing to unclaimed services using the can-i-take-over-xyz database.

**Advanced Port Scanning:**
- httpx - Fast HTTP/HTTPS service detection
- dnsx - Rapid DNS resolution and validation
- Parallel scanning for improved performance

**Response Analysis:** Detailed comparison of HTTP headers, body content, and response sizes to accurately identify origin servers.

**Reverse IP/DNS Lookups:** Comprehensive reverse lookups to discover other domains on the same IP.

### New Features

**JSON & CSV Export:** Export results in structured formats for integration with other tools and analysis platforms.

**Random Delays & User Agents:** Enhanced stealth mode with randomized delays and user agents to avoid detection.

**TOR Integration:** Full support for routing traffic through TOR network for anonymity.

**Advanced Stealth Mode:** Deep stealth capabilities with torify integration and traffic obfuscation.

---

## 📦 Installation

### Quick Start (Standard Version)

```bash
git clone https://github.com/jsnsns205-cell/tool.git
cd tool/origin-ip-hunter
./install.sh
./src/origin_ip_hunter.sh -d example.com
```

### Advanced Installation (With All Tools)

```bash
git clone https://github.com/jsnsns205-cell/tool.git
cd tool/origin-ip-hunter
./install_advanced.sh
./src/origin_ip_hunter_enhanced.sh -d example.com
```

The advanced installation script will:
- Install all base dependencies
- Install Go (if needed)
- Install advanced OSINT tools (theHarvester, Amass, Subfinder, etc.)
- Configure the environment
- Set up symlinks for easy access

---

## 💻 Usage

### Standard Version

```bash
# Basic scan
./src/origin_ip_hunter.sh -d example.com

# Stealth mode
./src/origin_ip_hunter.sh -d example.com --stealth

# Verbose output
./src/origin_ip_hunter.sh -d example.com -v
```

### Enhanced Version

```bash
# Basic scan with advanced tools
./src/origin_ip_hunter_enhanced.sh -d example.com

# Stealth mode with random delays and user agents
./src/origin_ip_hunter_enhanced.sh -d example.com --stealth -rd -rua

# Export results as JSON
./src/origin_ip_hunter_enhanced.sh -d example.com -f json

# Export results as CSV
./src/origin_ip_hunter_enhanced.sh -d example.com -f csv

# Using TOR for anonymity
./src/origin_ip_hunter_enhanced.sh -d example.com --tor

# Verbose mode with custom output
./src/origin_ip_hunter_enhanced.sh -d example.com -v -o /tmp/results
```

### Command-Line Options (Enhanced Version)

```
-d, --domain <domain>           Target domain to scan (required)
-s, --stealth                   Passive reconnaissance only
-t, --tor                       Use TOR proxy for requests
-v, --verbose                   Enable verbose output
-rd, --random-delay             Add random delays between requests
-rua, --random-user-agent       Use random user agents
-o, --output <path>             Custom output directory
-f, --format <format>           Output format: text, json, csv
-h, --help                       Show help message
```

---

## 🔍 Advanced Features Explained

### theHarvester Integration

theHarvester is a comprehensive OSINT tool that searches across 40+ sources including:
- Google, Bing, Yahoo, Baidu
- LinkedIn, Twitter
- Hunter.io
- Shodan
- Certificate transparency logs

**Usage:** Automatically runs during passive reconnaissance to gather emails, subdomains, and IP addresses.

### Subdomain Enumeration Tools

| Tool | Strength | Speed |
|------|----------|-------|
| Amass | Deep DNS enumeration | Medium |
| Assetfinder | Multiple sources | Fast |
| Subfinder | ProjectDiscovery quality | Very Fast |
| altdns | Pattern matching | Fast |

### Passive DNS Sources

Each source provides different historical perspectives:
- **ViewDNS:** User-friendly, good coverage
- **HackerTarget:** Free, reliable
- **RapidDNS:** Fast API
- **CIRCL:** Academic database
- **SecurityTrails:** Most comprehensive (premium)

### JARM Fingerprinting

JARM creates a unique fingerprint of TLS servers. By searching for this fingerprint on Shodan, you can find other servers with identical configurations, often including the origin server.

### asnmap & ASN Extraction

Converts domain/IP to ASN, then extracts all IP ranges for that ASN. This creates a pool of candidate IPs that likely belong to the same organization.

---

## 📊 Output Formats

### Text Format (Default)

```
╔════════════════════════════════════════════════════════════════╗
║         ORIGIN IP HUNTER v2.0 - RESULTS SUMMARY               ║
╚════════════════════════════════════════════════════════════════╝

Domain: example.com
Scan Date: Sun Apr 13 12:50:45 UTC 2026

=== ALL DISCOVERED IPs ===
192.0.2.1
192.0.2.5
203.0.113.42
...

=== LIKELY ORIGIN IPs (Verified) ===
192.0.2.1
192.0.2.5

=== STATISTICS ===
Total Subdomains Found: 24
Total IPs Discovered: 47
Verified Origin IPs: 2
```

### JSON Format

```json
{
  "scan_info": {
    "domain": "example.com",
    "timestamp": "2026-04-13T12:50:45Z",
    "version": "2.0.0"
  },
  "subdomains": [
    "www.example.com",
    "api.example.com",
    ...
  ],
  "all_ips": [
    "192.0.2.1",
    "192.0.2.5",
    ...
  ],
  "real_ips": [
    "192.0.2.1",
    "192.0.2.5"
  ],
  "statistics": {
    "subdomains_found": 24,
    "total_ips_discovered": 47,
    "verified_origin_ips": 2
  }
}
```

### CSV Format

```csv
Type,Value,Source
Subdomain,www.example.com,Enumeration
Subdomain,api.example.com,Enumeration
IP,192.0.2.1,Discovery
IP,192.0.2.5,Discovery
Origin IP,192.0.2.1,Verified
Origin IP,192.0.2.5,Verified
```

---

## 🛡️ Advanced Stealth Features

### Random Delays (`--random-delay`)

Adds random delays (1-5 seconds) between requests to avoid detection by rate-limiting systems.

### Random User Agents (`--random-user-agent`)

Rotates through realistic user agents to avoid fingerprinting:
- Windows Chrome
- macOS Safari
- Linux Firefox
- Mobile Chrome
- Mobile Firefox

### TOR Integration (`--tor`)

Routes all traffic through TOR network for complete anonymity. Requires TOR to be running:

```bash
# Start TOR
sudo service tor start

# Run with TOR
./src/origin_ip_hunter_enhanced.sh -d example.com --tor
```

### Complete Stealth Mode

Combine all stealth features:

```bash
./src/origin_ip_hunter_enhanced.sh -d example.com \
  --stealth \
  --tor \
  --random-delay \
  --random-user-agent
```

---

## 🔧 Configuration

### API Keys Setup

```bash
cp config/api_keys.conf.example config/api_keys.conf
nano config/api_keys.conf
```

Add your API keys for enhanced results:

```bash
SHODAN_API_KEY="your_key_here"
VIRUSTOTAL_API_KEY="your_key_here"
CENSYS_API_ID="your_id_here"
CENSYS_API_SECRET="your_secret_here"
SECURITYTRAILS_API_KEY="your_key_here"
IPINFO_API_KEY="your_key_here"
VIEWDNS_API_KEY="your_key_here"
```

---

## 📋 Output Files

The enhanced version generates all standard files plus:

| File | Purpose |
|------|---------|
| `theharvester_results.txt` | theHarvester output |
| `emails.txt` | Extracted email addresses |
| `jarm_fingerprints.txt` | TLS fingerprints |
| `subdomain_takeover.txt` | Vulnerable subdomains |
| `results.json` | JSON format results |
| `results.csv` | CSV format results |

---

## 🎯 Use Cases

### Bug Bounty Hunting

```bash
./src/origin_ip_hunter_enhanced.sh -d target.com -f json -o ./results
```

### Penetration Testing

```bash
./src/origin_ip_hunter_enhanced.sh -d target.com --stealth -v
```

### Security Research

```bash
./src/origin_ip_hunter_enhanced.sh -d target.com -f csv
# Import CSV into analysis tools
```

### Competitive Analysis

```bash
./src/origin_ip_hunter_enhanced.sh -d competitor.com -f json
```

---

## 🐛 Troubleshooting

### Advanced Tools Not Found

Some tools are optional. If not installed, the script will continue with available tools.

**To install missing tools:**

```bash
# Install Go first (required for ProjectDiscovery tools)
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Then run advanced installation
./install_advanced.sh
```

### TOR Connection Failed

Ensure TOR is running:

```bash
# Linux
sudo service tor start

# macOS
brew services start tor

# Docker
docker run -d -p 9050:9050 dperson/torproxy
```

### API Rate Limiting

Add API keys to `config/api_keys.conf` to increase rate limits on services like Shodan and Censys.

---

## 📚 Advanced Techniques

### Subdomain Takeover Detection

The tool checks for subdomains pointing to unclaimed services:

```bash
# Vulnerable subdomain example
api.example.com -> api.heroku.com (unclaimed)
```

### JARM Fingerprinting

Search for servers with identical TLS configurations:

```bash
# On Shodan
http.jarm:fingerprint_value
```

### ASN-Based IP Discovery

Discover all IPs in the same autonomous system:

```bash
# Example: ASN12345 might contain 1000+ IPs
# Tool automatically extracts and tests candidate IPs
```

---

## 🔐 Security Considerations

- **Stealth Mode:** Use for sensitive targets to avoid detection
- **TOR:** Provides anonymity but may be slower
- **Random Delays:** Helps avoid rate limiting
- **Local Storage:** All results stored locally, never uploaded
- **API Keys:** Store securely in config file (chmod 600)

---

## 📞 Support

- **GitHub Issues:** Report bugs and request features
- **Documentation:** Comprehensive README included
- **Examples:** Multiple usage examples provided
- **Logging:** Detailed logs for debugging

---

## 📝 Version History

### v2.0.0 (2026-04-13)

- Added theHarvester integration
- Integrated Amass, Subfinder, Assetfinder
- Added JARM fingerprinting
- Implemented JSON/CSV export
- Enhanced stealth mode with random delays and user agents
- Added TOR support
- Integrated dnsx and httpx for faster scanning
- Added asnmap for ASN extraction
- Subdomain takeover detection

### v1.0.0 (2026-04-13)

- Initial release
- Basic passive and active reconnaissance
- Multiple API integrations

---

## ⚖️ Legal Disclaimer

This tool is for authorized security testing only. Unauthorized access to computer systems is illegal. Users are responsible for ensuring they have proper authorization before scanning any domain.

---

**Happy Hunting! 🎯**

For more information, see the main README.md file.
