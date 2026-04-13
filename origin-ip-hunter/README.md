# Origin IP Hunter 🎯

**Advanced OSINT Reconnaissance Tool for Discovering Origin IPs Behind CDN/WAF Protections**

A professional-grade Bash script designed to uncover the real origin IP address of websites protected by Cloudflare, Akamai, AWS CloudFront, and other Content Delivery Networks (CDNs) and Web Application Firewalls (WAFs). This tool combines passive OSINT techniques with active reconnaissance methods to provide comprehensive intelligence gathering capabilities.

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Reconnaissance Phases](#reconnaissance-phases)
- [Configuration](#configuration)
- [Examples](#examples)
- [Output Structure](#output-structure)
- [API Keys & Data Sources](#api-keys--data-sources)
- [Troubleshooting](#troubleshooting)
- [Legal & Ethical Considerations](#legal--ethical-considerations)
- [Contributing](#contributing)
- [License](#license)

---

## Features

### 🔍 Passive Reconnaissance (OSINT)

The tool employs multiple passive reconnaissance techniques to gather information without directly interacting with the target:

**Subdomain Enumeration:** Leverages Certificate Transparency logs via `crt.sh`, VirusTotal, ThreatCrowd, and AlienVault OTX to discover all subdomains associated with the target domain. This is crucial because subdomains often reveal infrastructure details and may not be protected by the same CDN.

**Historical DNS Records:** Queries SecurityTrails, ViewDNS, HackerTarget, and RapidDNS to retrieve historical A, MX, NS, and CNAME records. If a website was hosted on a direct IP before migrating to Cloudflare, this historical data may contain the origin IP.

**SSL/TLS Certificate Analysis:** Examines certificate transparency logs and Subject Alternative Names (SANs) to extract IP addresses that may have been included in certificates issued to the origin server.

**Favicon Hash Search:** Calculates the MurmurHash of the website's favicon and searches for it on Shodan and Censys. This technique identifies other servers hosting identical favicons, which often includes the origin server.

**Search Engine Queries:** Integrates with Shodan, Censys, and Zoomeye to search for unique identifiers associated with the target, such as specific headers, SSL certificate serial numbers, or HTML content snippets.

**Wayback Machine Analysis:** Retrieves archived versions of the website from Archive.org to extract historical IP addresses and DNS configurations.

**ASN and IP Range Extraction:** Determines the Autonomous System Number (ASN) and retrieves all IP ranges associated with it, creating a pool of candidate IPs for further investigation.

### ⚔️ Active Reconnaissance

Once passive reconnaissance identifies candidate IPs, the tool performs active verification:

**DNS Record Extraction:** Retrieves all DNS records (A, MX, TXT, NS, CNAME) which may contain clues about the origin server, particularly MX records that often point to non-CDN infrastructure.

**Zone Transfer Attempts:** Tests for DNS zone transfer vulnerabilities (AXFR) on discovered nameservers, which could reveal the complete DNS configuration including the origin IP.

**Port Scanning:** Scans candidate IPs for open ports (80, 443) to identify active web services.

**HTTP/HTTPS Header Verification:** Sends requests to candidate IPs with the target domain in the Host header and analyzes responses to identify which IP serves the actual website content.

**Reverse IP/DNS Lookups:** Performs reverse DNS lookups and reverse IP searches to discover other domains hosted on the same IP, helping confirm the origin server.

**WAF/CDN Detection:** Analyzes server responses to identify and exclude known CDN IPs (Cloudflare, AWS, Akamai, etc.).

### 🛡️ Security & Privacy Features

**Stealth Mode:** Operates entirely passively without sending any direct requests to the target, minimizing detection risk.

**TOR Support:** Optional integration with TOR proxy for anonymized requests.

**Comprehensive Logging:** Detailed execution logs for audit trails and troubleshooting.

**Organized Output:** Results are organized into separate files for easy analysis and integration with other tools.

---

## Installation

### Prerequisites

- Bash 4.0 or higher
- Internet connection
- Linux, macOS, or WSL environment

### Automated Installation

```bash
# Clone the repository
git clone https://github.com/jsnsns205-cell/tool.git
cd tool/origin-ip-hunter

# Run the installation script
./install.sh
```

The installation script will:
- Detect your operating system
- Install all required dependencies
- Create necessary directories
- Generate configuration templates
- Verify the installation

### Manual Installation

If the automated script fails, install dependencies manually:

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y curl dnsutils whois netcat-openbsd jq git parallel openssl
```

**macOS:**
```bash
brew install curl bind whois netcat jq git parallel openssl
```

**Fedora/RHEL:**
```bash
sudo dnf install -y curl bind-utils whois ncat jq git parallel openssl
```

---

## Quick Start

### Basic Usage

```bash
# Scan a domain with default settings
./src/origin_ip_hunter.sh -d example.com

# Run in stealth mode (passive only)
./src/origin_ip_hunter.sh -d example.com --stealth

# Enable verbose output
./src/origin_ip_hunter.sh -d example.com --verbose

# Use custom output directory
./src/origin_ip_hunter.sh -d example.com -o /tmp/results
```

### Using the Symlink

After installation, you can run the tool from anywhere:

```bash
origin-ip-hunter -d example.com
```

---

## Usage

### Command-Line Options

```
Usage: origin_ip_hunter.sh -d <domain> [OPTIONS]

Required:
  -d, --domain <domain>          Target domain to scan

Options:
  -s, --stealth                  Passive reconnaissance only (no active scanning)
  -t, --tor                      Use TOR proxy for requests
  -v, --verbose                  Enable verbose output
  -o, --output <path>            Custom output directory
  -h, --help                     Show help message
```

### Examples

**Standard reconnaissance:**
```bash
./src/origin_ip_hunter.sh -d cloudflare-protected-site.com
```

**Stealth mode (OSINT only):**
```bash
./src/origin_ip_hunter.sh -d target.com --stealth
```

**Verbose mode with custom output:**
```bash
./src/origin_ip_hunter.sh -d target.com -v -o ./my_results
```

**Using TOR for anonymity:**
```bash
./src/origin_ip_hunter.sh -d target.com --tor
```

---

## Reconnaissance Phases

### Phase 1: Passive Reconnaissance

This phase gathers information exclusively from public sources without directly contacting the target:

1. **Subdomain Discovery** - Identifies all known subdomains
2. **Historical DNS Lookup** - Retrieves past DNS records
3. **SSL Certificate Analysis** - Extracts IPs from certificate logs
4. **Favicon Hashing** - Searches for servers with identical favicons
5. **Search Engine Queries** - Leverages Shodan, Censys, and other databases
6. **Wayback Machine Archive** - Retrieves historical snapshots
7. **ASN Extraction** - Identifies IP ranges associated with the target

### Phase 2: Active Reconnaissance

Once passive phase completes, active reconnaissance verifies candidate IPs:

1. **DNS Record Extraction** - Retrieves all DNS records
2. **Zone Transfer Attempts** - Tests for AXFR vulnerabilities
3. **Port Scanning** - Identifies open ports on candidate IPs
4. **HTTP/HTTPS Verification** - Tests which IP serves the website
5. **Reverse Lookups** - Discovers other domains on the same IP
6. **WAF/CDN Detection** - Identifies and excludes known CDN IPs

---

## Configuration

### API Keys Setup

To maximize the tool's effectiveness, add your API keys to the configuration file:

```bash
# Copy the example configuration
cp config/api_keys.conf.example config/api_keys.conf

# Edit with your API keys
nano config/api_keys.conf
```

### Supported APIs

| Service | Purpose | Free Tier | Link |
|---------|---------|-----------|------|
| crt.sh | Certificate Transparency | Yes | https://crt.sh |
| VirusTotal | Domain intelligence | Yes (limited) | https://www.virustotal.com |
| Shodan | Internet search engine | Yes (limited) | https://www.shodan.io |
| Censys | Internet devices database | Yes (limited) | https://censys.com |
| SecurityTrails | Historical DNS | No | https://securitytrails.com |
| ViewDNS | DNS history & reverse IP | Yes (limited) | https://www.viewdns.net |
| ipinfo.io | IP information & ASN | Yes (limited) | https://ipinfo.io |
| HackerTarget | DNS & host search | Yes | https://hackertarget.com |
| Archive.org | Wayback Machine | Yes | https://archive.org |

---

## Examples

### Example 1: Basic Domain Scan

```bash
./src/origin_ip_hunter.sh -d example.com
```

**Output:**
```
╔═══════════════════════════════════════════════════════════════╗
║          🎯 ORIGIN IP HUNTER - Advanced OSINT Tool 🎯         ║
╚═══════════════════════════════════════════════════════════════╝

[2026-04-13 12:50:15] ℹ Starting Origin IP Hunter...
[2026-04-13 12:50:15] ℹ Target Domain: example.com
[2026-04-13 12:50:16] ✓ All dependencies are installed
[2026-04-13 12:50:17] ✓ Found 24 subdomains
[2026-04-13 12:50:18] ✓ Found 8 historical DNS records
[2026-04-13 12:50:19] ✓ Found 3 IPs from SSL certificates
...
[2026-04-13 12:50:45] ✓ Scan completed!
```

### Example 2: Stealth Mode (OSINT Only)

```bash
./src/origin_ip_hunter.sh -d sensitive-target.com --stealth
```

This runs only passive reconnaissance, making it undetectable to the target.

### Example 3: Verbose Output with Custom Directory

```bash
./src/origin_ip_hunter.sh -d target.com -v -o /tmp/target_scan
```

---

## Output Structure

The tool creates a timestamped directory containing:

```
output/
├── subs_raw.txt              # Discovered subdomains
├── all_ips.txt               # All discovered IP addresses
├── dns_records.txt           # Historical DNS records
├── dns_records_active.txt    # Active DNS records
├── ssl_certs.txt             # IPs from SSL certificates
├── asn_ranges.txt            # IP ranges from ASN
├── favicon_hash.txt          # Favicon hash value
├── search_results.txt        # Results from search engines
├── wayback_ips.txt           # IPs from Wayback Machine
├── port_scan_results.txt     # Open ports found
├── http_verification.txt     # HTTP response analysis
├── reverse_lookups.txt       # Reverse DNS/IP results
├── zone_transfer.txt         # Zone transfer results
├── results_summary.txt       # Final summary report
└── execution_*.log           # Detailed execution log
```

### Results Summary Format

```
╔════════════════════════════════════════════════════════════════╗
║              ORIGIN IP HUNTER - RESULTS SUMMARY               ║
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

---

## API Keys & Data Sources

### Free Data Sources (No API Key Required)

- **crt.sh** - Certificate Transparency logs
- **HackerTarget** - DNS lookups and host search
- **Archive.org** - Wayback Machine snapshots
- **VirusTotal** - Limited free tier
- **Shodan** - Limited free tier
- **Censys** - Limited free tier

### Premium Data Sources (API Key Required)

- **SecurityTrails** - Comprehensive historical DNS
- **Shodan** - Unlimited searches
- **Censys** - Full database access
- **ipinfo.io** - Detailed IP information
- **ViewDNS** - Advanced DNS history

### Obtaining API Keys

1. **Shodan:** Visit https://www.shodan.io/ and create an account
2. **VirusTotal:** Go to https://www.virustotal.com/ and register
3. **Censys:** Create account at https://censys.com/
4. **SecurityTrails:** Sign up at https://securitytrails.com/
5. **ipinfo.io:** Register at https://ipinfo.io/

---

## Troubleshooting

### Issue: "Command not found" for dependencies

**Solution:** Run the installation script again or install dependencies manually:
```bash
./install.sh
```

### Issue: API rate limiting

**Solution:** Add API keys to increase rate limits, or wait before running another scan.

### Issue: No results found

**Solution:** 
- Verify the domain name is correct
- Try running with `--verbose` flag to see detailed output
- Check your internet connection
- Ensure API keys are valid (if configured)

### Issue: Permission denied when creating symlink

**Solution:** The symlink creation failed due to permissions. You can still run the tool directly:
```bash
./src/origin_ip_hunter.sh -d example.com
```

### Issue: TOR connection failed

**Solution:** Ensure TOR is running:
```bash
# Start TOR service
sudo service tor start

# Or on macOS
brew services start tor
```

---

## Legal & Ethical Considerations

**Important:** This tool is designed for authorized security testing and reconnaissance only. Users are responsible for ensuring they have proper authorization before scanning any domain.

### Legal Usage

- **Authorized Security Testing:** Use this tool only on systems you own or have explicit written permission to test
- **Bug Bounty Programs:** Many bug bounty platforms allow reconnaissance as part of their scope
- **Penetration Testing:** Use with signed contracts and clear scope definitions
- **Educational Purposes:** Learn security concepts in controlled lab environments

### Prohibited Usage

- Unauthorized access to computer systems
- Scanning domains without permission
- Using results for malicious purposes
- Violating local laws and regulations
- Circumventing security controls illegally

### Disclaimer

The authors and contributors of this tool are not responsible for any misuse or damage caused by this tool. Users must comply with all applicable laws and regulations in their jurisdiction.

---

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Areas for Contribution

- Additional data sources and APIs
- Performance optimizations
- New reconnaissance techniques
- Documentation improvements
- Bug fixes and error handling

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## Support & Contact

For issues, questions, or suggestions:

- **GitHub Issues:** Report bugs and request features
- **Documentation:** Check the docs/ directory for detailed guides
- **Community:** Join discussions and share your findings

---

## Changelog

### Version 1.0.0 (2026-04-13)

- Initial release
- Comprehensive passive reconnaissance phase
- Active reconnaissance capabilities
- Multiple API integrations
- Stealth mode support
- Detailed logging and reporting

---

## Acknowledgments

This tool was built using techniques and methodologies from the cybersecurity research community. Special thanks to:

- The Certificate Transparency community
- Security researchers who shared their methodologies
- Open-source intelligence (OSINT) practitioners
- The bug bounty community

---

**Disclaimer:** This tool is provided for educational and authorized security testing purposes only. Users are responsible for ensuring they have proper authorization and comply with all applicable laws and regulations.

**Happy Hunting! 🎯**
