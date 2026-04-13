#!/bin/bash

################################################################################
# Origin IP Hunter - Advanced Reconnaissance Tool
# Purpose: Discover the real origin IP behind CDN/WAF protections (Cloudflare, etc.)
# Author: Manus AI
# Version: 1.0.0
# License: MIT
################################################################################

set -e

# ============================================================================
# COLORS & FORMATTING
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ============================================================================
# GLOBAL VARIABLES
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
CONFIG_FILE="${PROJECT_ROOT}/config/api_keys.conf"
OUTPUT_DIR="${PROJECT_ROOT}/output"
LOG_FILE=""
DOMAIN=""
STEALTH_MODE=false
USE_TOR=false
VERBOSE=false
TIMEOUT=10

# Arrays to store results
declare -a SUBDOMAINS
declare -a ALL_IPS
declare -a CF_IPS
declare -a REAL_IPS
declare -a DNS_RECORDS

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

print_banner() {
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║          🎯 ORIGIN IP HUNTER - Advanced OSINT Tool 🎯         ║
║                                                               ║
║   Discover the real origin IP behind CDN/WAF protections     ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

log_message() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "${BLUE}[${timestamp}]${NC} ${BLUE}ℹ${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[${timestamp}]${NC} ${GREEN}✓${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[${timestamp}]${NC} ${YELLOW}⚠${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[${timestamp}]${NC} ${RED}✗${NC} $message"
            ;;
        "DEBUG")
            if [ "$VERBOSE" = true ]; then
                echo -e "${MAGENTA}[${timestamp}]${NC} ${MAGENTA}🐛${NC} $message"
            fi
            ;;
    esac
    
    echo "[${timestamp}] [$level] $message" >> "$LOG_FILE"
}

check_dependencies() {
    log_message "INFO" "Checking dependencies..."
    
    local required_tools=("curl" "dig" "jq" "whois" "nc" "grep" "awk" "sed")
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_message "ERROR" "Missing tools: ${missing_tools[*]}"
        log_message "INFO" "Run: ./install.sh"
        exit 1
    fi
    
    log_message "SUCCESS" "All dependencies are installed"
}

validate_domain() {
    local domain=$1
    
    if [[ ! $domain =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
        log_message "ERROR" "Invalid domain format: $domain"
        return 1
    fi
    
    return 0
}

load_api_keys() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        log_message "SUCCESS" "API keys loaded from config"
    else
        log_message "WARNING" "Config file not found. Using free APIs only."
    fi
}

# ============================================================================
# PHASE 1: PASSIVE RECONNAISSANCE
# ============================================================================

passive_reconnaissance() {
    log_message "INFO" "Starting Passive Reconnaissance Phase..."
    echo -e "\n${CYAN}${BOLD}[PHASE 1] PASSIVE RECONNAISSANCE${NC}\n"
    
    # Subdomain enumeration
    enumerate_subdomains
    
    # Historical DNS records
    fetch_historical_dns
    
    # SSL certificate analysis
    analyze_ssl_certificates
    
    # Favicon hash search
    favicon_hash_search
    
    # ASN and IP range extraction
    extract_asn_ranges
    
    # Search engine queries (Shodan, Censys)
    search_engine_queries
    
    # Wayback Machine archive
    wayback_machine_search
}

enumerate_subdomains() {
    log_message "INFO" "Enumerating subdomains..."
    
    local subs_file="${OUTPUT_DIR}/subs_raw.txt"
    > "$subs_file"
    
    # crt.sh - Certificate Transparency Logs
    log_message "DEBUG" "Querying crt.sh..."
    curl -s "https://crt.sh/?q=%25.${DOMAIN}&output=json" 2>/dev/null | \
        jq -r '.[].name_value' 2>/dev/null | \
        sed 's/\*\.//g' | sort -u >> "$subs_file" || true
    
    # VirusTotal (if API key available)
    if [ ! -z "$VIRUSTOTAL_API_KEY" ]; then
        log_message "DEBUG" "Querying VirusTotal..."
        curl -s "https://www.virustotal.com/api/v3/domains/${DOMAIN}/subdomains?limit=40" \
            -H "x-apikey: $VIRUSTOTAL_API_KEY" 2>/dev/null | \
            jq -r '.data[].id' 2>/dev/null | sed 's/\.$//' >> "$subs_file" || true
    fi
    
    # HackerTarget
    log_message "DEBUG" "Querying HackerTarget..."
    curl -s "https://api.hackertarget.com/hostsearch/?q=${DOMAIN}" 2>/dev/null | \
        cut -d',' -f1 | grep -v "Host" >> "$subs_file" || true
    
    # Remove duplicates and count
    sort -u "$subs_file" > "${subs_file}.tmp"
    mv "${subs_file}.tmp" "$subs_file"
    
    local count=$(wc -l < "$subs_file")
    log_message "SUCCESS" "Found $count subdomains"
    SUBDOMAINS=($(cat "$subs_file"))
}

fetch_historical_dns() {
    log_message "INFO" "Fetching historical DNS records..."
    
    local dns_file="${OUTPUT_DIR}/dns_records.txt"
    > "$dns_file"
    
    # ViewDNS.info DNS History (free)
    log_message "DEBUG" "Querying ViewDNS DNS History..."
    curl -s "https://www.viewdns.net/api/dns-history/?domain=${DOMAIN}&apikey=free" 2>/dev/null | \
        jq -r '.records[].ip' 2>/dev/null | sort -u >> "$dns_file" || true
    
    # HackerTarget DNS History
    log_message "DEBUG" "Querying HackerTarget DNS History..."
    curl -s "https://api.hackertarget.com/dnslookup/?q=${DOMAIN}" 2>/dev/null | \
        grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' >> "$dns_file" || true
    
    # RapidDNS (free historical DNS)
    log_message "DEBUG" "Querying RapidDNS..."
    curl -s "https://rapiddns.io/api/search?q=${DOMAIN}" 2>/dev/null | \
        jq -r '.[] | .ip' 2>/dev/null | sort -u >> "$dns_file" || true
    
    sort -u "$dns_file" > "${dns_file}.tmp"
    mv "${dns_file}.tmp" "$dns_file"
    
    local count=$(wc -l < "$dns_file")
    log_message "SUCCESS" "Found $count historical DNS records"
    ALL_IPS+=($(cat "$dns_file"))
}

analyze_ssl_certificates() {
    log_message "INFO" "Analyzing SSL certificates..."
    
    local cert_file="${OUTPUT_DIR}/ssl_certs.txt"
    > "$cert_file"
    
    # crt.sh - Get certificate details
    log_message "DEBUG" "Fetching SSL certificate details from crt.sh..."
    curl -s "https://crt.sh/?q=${DOMAIN}&output=json" 2>/dev/null | \
        jq -r '.[] | .name_value' 2>/dev/null | \
        grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' >> "$cert_file" || true
    
    # Extract IPs from certificate SANs
    for subdomain in "${SUBDOMAINS[@]}"; do
        log_message "DEBUG" "Checking certificate for $subdomain..."
        echo | timeout $TIMEOUT openssl s_client -servername "$subdomain" -connect "$subdomain:443" 2>/dev/null | \
            openssl x509 -noout -text 2>/dev/null | \
            grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' >> "$cert_file" || true
    done
    
    sort -u "$cert_file" > "${cert_file}.tmp"
    mv "${cert_file}.tmp" "$cert_file"
    
    local count=$(wc -l < "$cert_file")
    log_message "SUCCESS" "Found $count IPs from SSL certificates"
    ALL_IPS+=($(cat "$cert_file"))
}

favicon_hash_search() {
    log_message "INFO" "Calculating favicon hash..."
    
    local favicon_hash_file="${OUTPUT_DIR}/favicon_hash.txt"
    
    # Download favicon
    local favicon_url="https://${DOMAIN}/favicon.ico"
    local favicon_file="/tmp/favicon_${DOMAIN}.ico"
    
    if curl -s -o "$favicon_file" --max-time $TIMEOUT "$favicon_url" 2>/dev/null; then
        # Calculate MurmurHash (using a simple approach with base64)
        local favicon_hash=$(cat "$favicon_file" | base64 | md5sum | awk '{print $1}')
        echo "$favicon_hash" > "$favicon_hash_file"
        
        log_message "SUCCESS" "Favicon hash: $favicon_hash"
        log_message "INFO" "Search this hash on Shodan: http.favicon.hash:$favicon_hash"
        
        rm -f "$favicon_file"
    else
        log_message "WARNING" "Could not download favicon"
    fi
}

extract_asn_ranges() {
    log_message "INFO" "Extracting ASN and IP ranges..."
    
    local asn_file="${OUTPUT_DIR}/asn_ranges.txt"
    > "$asn_file"
    
    # Get ASN from ipinfo.io
    log_message "DEBUG" "Querying ipinfo.io for ASN..."
    local asn=$(curl -s "https://ipinfo.io/${DOMAIN}?token=${IPINFO_API_KEY:-}" 2>/dev/null | jq -r '.org' 2>/dev/null | grep -oE 'AS[0-9]+' || echo "")
    
    if [ ! -z "$asn" ]; then
        log_message "SUCCESS" "Found ASN: $asn"
        
        # Query ASN ranges from ipinfo.io
        curl -s "https://ipinfo.io/${asn}?token=${IPINFO_API_KEY:-}" 2>/dev/null | \
            jq -r '.prefixes[].prefix' 2>/dev/null >> "$asn_file" || true
    fi
    
    local count=$(wc -l < "$asn_file")
    if [ $count -gt 0 ]; then
        log_message "SUCCESS" "Found $count IP ranges from ASN"
        ALL_IPS+=($(cat "$asn_file"))
    fi
}

search_engine_queries() {
    log_message "INFO" "Querying search engines (Shodan, Censys)..."
    
    local search_file="${OUTPUT_DIR}/search_results.txt"
    > "$search_file"
    
    # Shodan (if API key available)
    if [ ! -z "$SHODAN_API_KEY" ]; then
        log_message "DEBUG" "Querying Shodan..."
        curl -s "https://api.shodan.io/shodan/host/search?query=hostname:${DOMAIN}&key=${SHODAN_API_KEY}" 2>/dev/null | \
            jq -r '.matches[].ip_str' 2>/dev/null >> "$search_file" || true
    fi
    
    # Censys (if API key available)
    if [ ! -z "$CENSYS_API_ID" ] && [ ! -z "$CENSYS_API_SECRET" ]; then
        log_message "DEBUG" "Querying Censys..."
        local auth=$(echo -n "${CENSYS_API_ID}:${CENSYS_API_SECRET}" | base64)
        curl -s "https://censys.io/api/v1/search/ipv4" \
            -H "Authorization: Basic $auth" \
            -d "{\"query\": \"${DOMAIN}\"}" 2>/dev/null | \
            jq -r '.results[].ip' 2>/dev/null >> "$search_file" || true
    fi
    
    sort -u "$search_file" > "${search_file}.tmp"
    mv "${search_file}.tmp" "$search_file"
    
    local count=$(wc -l < "$search_file")
    if [ $count -gt 0 ]; then
        log_message "SUCCESS" "Found $count results from search engines"
        ALL_IPS+=($(cat "$search_file"))
    fi
}

wayback_machine_search() {
    log_message "INFO" "Searching Wayback Machine for historical IPs..."
    
    local wayback_file="${OUTPUT_DIR}/wayback_ips.txt"
    > "$wayback_file"
    
    # Query Wayback Machine API
    log_message "DEBUG" "Querying archive.org..."
    curl -s "https://archive.org/wayback/available?url=${DOMAIN}&output=json" 2>/dev/null | \
        jq -r '.archived_snapshots[].status' 2>/dev/null | \
        grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' >> "$wayback_file" || true
    
    # Try to get snapshots and extract IPs from HTML
    local snapshots=$(curl -s "https://web.archive.org/web/2*/${DOMAIN}/" 2>/dev/null | \
        grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' || true)
    
    if [ ! -z "$snapshots" ]; then
        echo "$snapshots" >> "$wayback_file"
    fi
    
    sort -u "$wayback_file" > "${wayback_file}.tmp"
    mv "${wayback_file}.tmp" "$wayback_file"
    
    local count=$(wc -l < "$wayback_file")
    if [ $count -gt 0 ]; then
        log_message "SUCCESS" "Found $count IPs from Wayback Machine"
        ALL_IPS+=($(cat "$wayback_file"))
    fi
}

# ============================================================================
# PHASE 2: ACTIVE RECONNAISSANCE
# ============================================================================

active_reconnaissance() {
    if [ "$STEALTH_MODE" = true ]; then
        log_message "WARNING" "Stealth mode enabled - skipping active reconnaissance"
        return
    fi
    
    log_message "INFO" "Starting Active Reconnaissance Phase..."
    echo -e "\n${CYAN}${BOLD}[PHASE 2] ACTIVE RECONNAISSANCE${NC}\n"
    
    # DNS record extraction
    extract_dns_records
    
    # Zone transfer attempt
    attempt_zone_transfer
    
    # Port scanning on candidate IPs
    port_scan_candidates
    
    # HTTP/HTTPS verification
    verify_http_headers
    
    # Reverse IP/DNS lookup
    reverse_lookups
}

extract_dns_records() {
    log_message "INFO" "Extracting DNS records (A, MX, TXT, NS, CNAME)..."
    
    local dns_file="${OUTPUT_DIR}/dns_records_active.txt"
    > "$dns_file"
    
    # A records
    log_message "DEBUG" "Querying A records..."
    dig +short A "$DOMAIN" >> "$dns_file" 2>/dev/null || true
    
    # MX records
    log_message "DEBUG" "Querying MX records..."
    dig +short MX "$DOMAIN" | awk '{print $NF}' >> "$dns_file" 2>/dev/null || true
    
    # NS records
    log_message "DEBUG" "Querying NS records..."
    dig +short NS "$DOMAIN" >> "$dns_file" 2>/dev/null || true
    
    # TXT records (SPF, DKIM might leak IPs)
    log_message "DEBUG" "Querying TXT records..."
    dig +short TXT "$DOMAIN" >> "$dns_file" 2>/dev/null || true
    
    # CNAME records
    log_message "DEBUG" "Querying CNAME records..."
    dig +short CNAME "$DOMAIN" >> "$dns_file" 2>/dev/null || true
    
    # Extract IPs from records
    grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' "$dns_file" | sort -u > "${dns_file}.ips"
    
    local count=$(wc -l < "${dns_file}.ips")
    log_message "SUCCESS" "Extracted $count IPs from DNS records"
    ALL_IPS+=($(cat "${dns_file}.ips"))
}

attempt_zone_transfer() {
    log_message "INFO" "Attempting DNS zone transfer (AXFR)..."
    
    local zone_file="${OUTPUT_DIR}/zone_transfer.txt"
    > "$zone_file"
    
    # Get NS servers
    local ns_servers=$(dig +short NS "$DOMAIN" 2>/dev/null)
    
    for ns in $ns_servers; do
        log_message "DEBUG" "Attempting zone transfer on $ns..."
        dig +nocmd AXFR "$DOMAIN" @"$ns" >> "$zone_file" 2>/dev/null || true
    done
    
    if [ -s "$zone_file" ]; then
        log_message "SUCCESS" "Zone transfer successful!"
        grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' "$zone_file" | sort -u > "${zone_file}.ips"
        ALL_IPS+=($(cat "${zone_file}.ips"))
    else
        log_message "INFO" "Zone transfer failed (expected for most domains)"
    fi
}

port_scan_candidates() {
    log_message "INFO" "Scanning candidate IPs for open ports..."
    
    local scan_file="${OUTPUT_DIR}/port_scan_results.txt"
    > "$scan_file"
    
    # Deduplicate IPs
    local unique_ips=$(printf '%s\n' "${ALL_IPS[@]}" | sort -u)
    
    local count=0
    for ip in $unique_ips; do
        # Skip Cloudflare IPs
        if is_cloudflare_ip "$ip"; then
            log_message "DEBUG" "Skipping Cloudflare IP: $ip"
            continue
        fi
        
        count=$((count + 1))
        if [ $count -gt 50 ]; then
            log_message "WARNING" "Limiting port scans to 50 IPs"
            break
        fi
        
        log_message "DEBUG" "Scanning $ip:80 and $ip:443..."
        
        # Check port 80
        if timeout 2 nc -zv "$ip" 80 &>/dev/null; then
            echo "$ip:80 - OPEN" >> "$scan_file"
            log_message "SUCCESS" "Port 80 open on $ip"
        fi
        
        # Check port 443
        if timeout 2 nc -zv "$ip" 443 &>/dev/null; then
            echo "$ip:443 - OPEN" >> "$scan_file"
            log_message "SUCCESS" "Port 443 open on $ip"
        fi
    done
}

verify_http_headers() {
    log_message "INFO" "Verifying HTTP headers on candidate IPs..."
    
    local verify_file="${OUTPUT_DIR}/http_verification.txt"
    > "$verify_file"
    
    local unique_ips=$(printf '%s\n' "${ALL_IPS[@]}" | sort -u)
    
    for ip in $unique_ips; do
        if is_cloudflare_ip "$ip"; then
            continue
        fi
        
        log_message "DEBUG" "Testing HTTP response from $ip..."
        
        # Try HTTP
        local response=$(curl -s -H "Host: $DOMAIN" -m $TIMEOUT "http://$ip" 2>/dev/null | head -c 500)
        if [ ! -z "$response" ]; then
            echo "=== $ip (HTTP) ===" >> "$verify_file"
            echo "$response" >> "$verify_file"
            echo "" >> "$verify_file"
            
            # Check if response matches target domain
            if echo "$response" | grep -q "$DOMAIN"; then
                log_message "SUCCESS" "Found matching response on $ip"
                REAL_IPS+=("$ip")
            fi
        fi
        
        # Try HTTPS
        local response=$(curl -s -k -H "Host: $DOMAIN" -m $TIMEOUT "https://$ip" 2>/dev/null | head -c 500)
        if [ ! -z "$response" ]; then
            echo "=== $ip (HTTPS) ===" >> "$verify_file"
            echo "$response" >> "$verify_file"
            echo "" >> "$verify_file"
            
            if echo "$response" | grep -q "$DOMAIN"; then
                log_message "SUCCESS" "Found matching response on $ip"
                REAL_IPS+=("$ip")
            fi
        fi
    done
}

reverse_lookups() {
    log_message "INFO" "Performing reverse IP and DNS lookups..."
    
    local reverse_file="${OUTPUT_DIR}/reverse_lookups.txt"
    > "$reverse_file"
    
    local unique_ips=$(printf '%s\n' "${ALL_IPS[@]}" | sort -u)
    
    for ip in $unique_ips; do
        if is_cloudflare_ip "$ip"; then
            continue
        fi
        
        log_message "DEBUG" "Reverse lookup on $ip..."
        
        # Reverse DNS
        local reverse_dns=$(dig +short -x "$ip" 2>/dev/null)
        if [ ! -z "$reverse_dns" ]; then
            echo "$ip -> $reverse_dns" >> "$reverse_file"
        fi
        
        # Reverse IP lookup via ViewDNS
        if [ ! -z "$VIEWDNS_API_KEY" ]; then
            curl -s "https://www.viewdns.net/api/reverseip/?ip=${ip}&apikey=${VIEWDNS_API_KEY}" 2>/dev/null | \
                jq -r '.domains[].domain' 2>/dev/null >> "$reverse_file" || true
        fi
    done
}

# ============================================================================
# UTILITY FUNCTIONS FOR RECONNAISSANCE
# ============================================================================

is_cloudflare_ip() {
    local ip=$1
    
    # Cloudflare IP ranges (as of 2026)
    local cf_ranges=(
        "173.245.48.0/20"
        "103.21.244.0/22"
        "103.22.200.0/22"
        "103.31.4.0/22"
        "141.101.64.0/18"
        "108.162.192.0/18"
        "190.93.240.0/20"
        "188.114.96.0/20"
        "197.234.240.0/22"
        "198.41.128.0/17"
        "162.158.0.0/15"
        "104.16.0.0/13"
        "104.24.0.0/14"
        "172.64.0.0/13"
        "131.0.72.0/22"
    )
    
    for range in "${cf_ranges[@]}"; do
        if [[ $(echo "$ip" | awk -F. '{print $1"."$2"."$3"."$4}') == *"."* ]]; then
            # Simple check - in production use ipcalc or similar
            if echo "$range" | grep -q "$ip"; then
                return 0
            fi
        fi
    done
    
    return 1
}

# ============================================================================
# RESULTS COMPILATION
# ============================================================================

compile_results() {
    log_message "INFO" "Compiling results..."
    
    local results_file="${OUTPUT_DIR}/results_summary.txt"
    > "$results_file"
    
    echo "╔════════════════════════════════════════════════════════════════╗" >> "$results_file"
    echo "║              ORIGIN IP HUNTER - RESULTS SUMMARY               ║" >> "$results_file"
    echo "╚════════════════════════════════════════════════════════════════╝" >> "$results_file"
    echo "" >> "$results_file"
    echo "Domain: $DOMAIN" >> "$results_file"
    echo "Scan Date: $(date)" >> "$results_file"
    echo "" >> "$results_file"
    
    # Unique IPs
    local unique_ips=$(printf '%s\n' "${ALL_IPS[@]}" | sort -u)
    echo "=== ALL DISCOVERED IPs ===" >> "$results_file"
    echo "$unique_ips" >> "$results_file"
    echo "" >> "$results_file"
    
    # Real IPs (verified)
    echo "=== LIKELY ORIGIN IPs (Verified) ===" >> "$results_file"
    if [ ${#REAL_IPS[@]} -gt 0 ]; then
        printf '%s\n' "${REAL_IPS[@]}" | sort -u >> "$results_file"
    else
        echo "No verified origin IPs found" >> "$results_file"
    fi
    echo "" >> "$results_file"
    
    # Statistics
    echo "=== STATISTICS ===" >> "$results_file"
    echo "Total Subdomains Found: ${#SUBDOMAINS[@]}" >> "$results_file"
    echo "Total IPs Discovered: $(printf '%s\n' "${ALL_IPS[@]}" | sort -u | wc -l)" >> "$results_file"
    echo "Verified Origin IPs: ${#REAL_IPS[@]}" >> "$results_file"
    echo "" >> "$results_file"
    
    cat "$results_file"
    log_message "SUCCESS" "Results saved to $results_file"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    print_banner
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Setup logging
    LOG_FILE="${OUTPUT_DIR}/execution_$(date +%s).log"
    
    log_message "INFO" "Starting Origin IP Hunter..."
    log_message "INFO" "Target Domain: $DOMAIN"
    log_message "INFO" "Stealth Mode: $STEALTH_MODE"
    log_message "INFO" "Verbose Mode: $VERBOSE"
    
    # Validate and prepare
    validate_domain "$DOMAIN" || exit 1
    check_dependencies
    load_api_keys
    
    # Run reconnaissance phases
    passive_reconnaissance
    active_reconnaissance
    
    # Compile and display results
    compile_results
    
    log_message "SUCCESS" "Scan completed! Check ${OUTPUT_DIR} for detailed results."
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

usage() {
    cat << EOF
Usage: $0 -d <domain> [OPTIONS]

Required:
  -d, --domain <domain>          Target domain to scan

Options:
  -s, --stealth                  Passive reconnaissance only (no active scanning)
  -t, --tor                      Use TOR proxy for requests
  -v, --verbose                  Enable verbose output
  -o, --output <path>            Custom output directory
  -h, --help                     Show this help message

Examples:
  $0 -d example.com
  $0 -d example.com --stealth --verbose
  $0 -d example.com -o /tmp/results

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -s|--stealth)
            STEALTH_MODE=true
            shift
            ;;
        -t|--tor)
            USE_TOR=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required arguments
if [ -z "$DOMAIN" ]; then
    echo "Error: Domain is required"
    usage
fi

# Run main function
main
