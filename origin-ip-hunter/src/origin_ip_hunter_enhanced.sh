#!/bin/bash

################################################################################
# Origin IP Hunter - Advanced Reconnaissance Tool (Enhanced Edition)
# Purpose: Discover the real origin IP behind CDN/WAF protections
# Author: Manus AI
# Version: 2.0.0 (Enhanced with advanced tools and sources)
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
NC='\033[0m'
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
OUTPUT_FORMAT="text"  # text, json, csv
RANDOM_DELAY=false
RANDOM_USER_AGENT=false

# Arrays to store results
declare -a SUBDOMAINS
declare -a ALL_IPS
declare -a CF_IPS
declare -a REAL_IPS
declare -a DNS_RECORDS
declare -a EMAILS

# User agents for randomization
USER_AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
    "Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15"
    "Mozilla/5.0 (Android 11; Mobile; rv:89.0) Gecko/89.0 Firefox/89.0"
)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

print_banner() {
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   🎯 ORIGIN IP HUNTER - Advanced OSINT Tool v2.0 🎯           ║
║                                                               ║
║   Discover the real origin IP behind CDN/WAF protections     ║
║   Enhanced with advanced tools and multiple data sources     ║
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

get_random_user_agent() {
    local index=$((RANDOM % ${#USER_AGENTS[@]}))
    echo "${USER_AGENTS[$index]}"
}

add_random_delay() {
    if [ "$RANDOM_DELAY" = true ]; then
        local delay=$((RANDOM % 5 + 1))
        sleep "$delay"
    fi
}

curl_with_options() {
    local url=$1
    local user_agent=""
    
    if [ "$RANDOM_USER_AGENT" = true ]; then
        user_agent=$(get_random_user_agent)
    else
        user_agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
    fi
    
    if [ "$USE_TOR" = true ]; then
        curl -s -x socks5://127.0.0.1:9050 -A "$user_agent" -m $TIMEOUT "$url" 2>/dev/null || true
    else
        curl -s -A "$user_agent" -m $TIMEOUT "$url" 2>/dev/null || true
    fi
    
    add_random_delay
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

check_advanced_tools() {
    log_message "INFO" "Checking for advanced tools..."
    
    local advanced_tools=("theHarvester" "dnsx" "httpx" "amass" "assetfinder" "altdns" "asnmap")
    
    for tool in "${advanced_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_message "SUCCESS" "$tool is available"
        else
            log_message "DEBUG" "$tool not found (optional)"
        fi
    done
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
# PHASE 1: PASSIVE RECONNAISSANCE (ENHANCED)
# ============================================================================

passive_reconnaissance() {
    log_message "INFO" "Starting Enhanced Passive Reconnaissance Phase..."
    echo -e "\n${CYAN}${BOLD}[PHASE 1] ENHANCED PASSIVE RECONNAISSANCE${NC}\n"
    
    # theHarvester integration
    use_the_harvester
    
    # Subdomain enumeration with multiple tools
    enumerate_subdomains_advanced
    
    # Historical DNS records from multiple sources
    fetch_historical_dns_advanced
    
    # SSL certificate analysis
    analyze_ssl_certificates
    
    # Favicon hash search
    favicon_hash_search
    
    # JARM fingerprinting
    jarm_fingerprinting
    
    # ASN and IP range extraction
    extract_asn_ranges_advanced
    
    # Search engine queries
    search_engine_queries
    
    # Wayback Machine archive
    wayback_machine_search
}

use_the_harvester() {
    log_message "INFO" "Running theHarvester for comprehensive OSINT..."
    
    if ! command -v theHarvester &> /dev/null; then
        log_message "DEBUG" "theHarvester not installed, skipping"
        return
    fi
    
    local harvester_file="${OUTPUT_DIR}/theharvester_results.txt"
    
    # Run theHarvester with multiple sources
    theHarvester -d "$DOMAIN" -b bing,google,yahoo,linkedin,twitter,baidu,hunter,shodan 2>/dev/null | tee "$harvester_file" || true
    
    # Extract emails
    grep -oE '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b' "$harvester_file" | sort -u > "${OUTPUT_DIR}/emails.txt" || true
    
    # Extract IPs
    grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' "$harvester_file" | sort -u >> "${OUTPUT_DIR}/all_ips.txt" || true
    
    log_message "SUCCESS" "theHarvester scan completed"
}

enumerate_subdomains_advanced() {
    log_message "INFO" "Enumerating subdomains with advanced tools..."
    
    local subs_file="${OUTPUT_DIR}/subs_raw.txt"
    > "$subs_file"
    
    # crt.sh
    log_message "DEBUG" "Querying crt.sh..."
    curl_with_options "https://crt.sh/?q=%25.${DOMAIN}&output=json" 2>/dev/null | \
        jq -r '.[].name_value' 2>/dev/null | \
        sed 's/\*\.//g' | sort -u >> "$subs_file" || true
    
    # VirusTotal
    if [ ! -z "$VIRUSTOTAL_API_KEY" ]; then
        log_message "DEBUG" "Querying VirusTotal..."
        curl_with_options "https://www.virustotal.com/api/v3/domains/${DOMAIN}/subdomains?limit=40" \
            -H "x-apikey: $VIRUSTOTAL_API_KEY" 2>/dev/null | \
            jq -r '.data[].id' 2>/dev/null | sed 's/\.$//' >> "$subs_file" || true
    fi
    
    # HackerTarget
    log_message "DEBUG" "Querying HackerTarget..."
    curl_with_options "https://api.hackertarget.com/hostsearch/?q=${DOMAIN}" 2>/dev/null | \
        cut -d',' -f1 | grep -v "Host" >> "$subs_file" || true
    
    # Amass (if available)
    if command -v amass &> /dev/null; then
        log_message "DEBUG" "Running Amass enumeration..."
        amass enum -d "$DOMAIN" -passive 2>/dev/null | grep -oE '[a-zA-Z0-9.-]+\.'${DOMAIN} >> "$subs_file" || true
    fi
    
    # Assetfinder (if available)
    if command -v assetfinder &> /dev/null; then
        log_message "DEBUG" "Running Assetfinder..."
        assetfinder --subs-only "$DOMAIN" 2>/dev/null >> "$subs_file" || true
    fi
    
    # Remove duplicates
    sort -u "$subs_file" > "${subs_file}.tmp"
    mv "${subs_file}.tmp" "$subs_file"
    
    local count=$(wc -l < "$subs_file")
    log_message "SUCCESS" "Found $count subdomains"
    SUBDOMAINS=($(cat "$subs_file"))
}

fetch_historical_dns_advanced() {
    log_message "INFO" "Fetching historical DNS records from multiple sources..."
    
    local dns_file="${OUTPUT_DIR}/dns_records.txt"
    > "$dns_file"
    
    # ViewDNS.info
    log_message "DEBUG" "Querying ViewDNS..."
    curl_with_options "https://www.viewdns.net/api/dns-history/?domain=${DOMAIN}&apikey=free" 2>/dev/null | \
        jq -r '.records[].ip' 2>/dev/null | sort -u >> "$dns_file" || true
    
    # HackerTarget
    log_message "DEBUG" "Querying HackerTarget DNS..."
    curl_with_options "https://api.hackertarget.com/dnslookup/?q=${DOMAIN}" 2>/dev/null | \
        grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' >> "$dns_file" || true
    
    # RapidDNS
    log_message "DEBUG" "Querying RapidDNS..."
    curl_with_options "https://rapiddns.io/api/search?q=${DOMAIN}" 2>/dev/null | \
        jq -r '.[] | .ip' 2>/dev/null | sort -u >> "$dns_file" || true
    
    # CIRCL (if available)
    log_message "DEBUG" "Querying CIRCL Passive DNS..."
    curl_with_options "https://www.circl.lu/api/v1/pdns/forward/${DOMAIN}" 2>/dev/null | \
        jq -r '.rrsets[].rdata[]' 2>/dev/null | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' >> "$dns_file" || true
    
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
    
    # crt.sh
    log_message "DEBUG" "Fetching SSL certificate details..."
    curl_with_options "https://crt.sh/?q=${DOMAIN}&output=json" 2>/dev/null | \
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

jarm_fingerprinting() {
    log_message "INFO" "Performing JARM fingerprinting..."
    
    local jarm_file="${OUTPUT_DIR}/jarm_fingerprints.txt"
    > "$jarm_file"
    
    # JARM is a TLS fingerprinting technique
    # For now, we'll extract SSL info that can be used for searching
    log_message "DEBUG" "Extracting SSL fingerprints for Shodan search..."
    
    if [ ! -z "$SHODAN_API_KEY" ]; then
        # Get SSL certificate info and search on Shodan
        for subdomain in "${SUBDOMAINS[@]:0:5}"; do
            local cert_hash=$(echo | timeout $TIMEOUT openssl s_client -servername "$subdomain" -connect "$subdomain:443" 2>/dev/null | \
                openssl x509 -noout -fingerprint 2>/dev/null | cut -d'=' -f2)
            
            if [ ! -z "$cert_hash" ]; then
                echo "$subdomain: $cert_hash" >> "$jarm_file"
                log_message "DEBUG" "JARM hash for $subdomain: $cert_hash"
            fi
        done
    fi
}

favicon_hash_search() {
    log_message "INFO" "Calculating favicon hash..."
    
    local favicon_hash_file="${OUTPUT_DIR}/favicon_hash.txt"
    
    local favicon_url="https://${DOMAIN}/favicon.ico"
    local favicon_file="/tmp/favicon_${DOMAIN}.ico"
    
    if curl_with_options -o "$favicon_file" "$favicon_url" 2>/dev/null; then
        local favicon_hash=$(cat "$favicon_file" | base64 | md5sum | awk '{print $1}')
        echo "$favicon_hash" > "$favicon_hash_file"
        
        log_message "SUCCESS" "Favicon hash: $favicon_hash"
        log_message "INFO" "Search on Shodan: http.favicon.hash:$favicon_hash"
        
        rm -f "$favicon_file"
    else
        log_message "WARNING" "Could not download favicon"
    fi
}

extract_asn_ranges_advanced() {
    log_message "INFO" "Extracting ASN and IP ranges..."
    
    local asn_file="${OUTPUT_DIR}/asn_ranges.txt"
    > "$asn_file"
    
    # Get ASN from ipinfo.io
    log_message "DEBUG" "Querying ipinfo.io for ASN..."
    local asn=$(curl_with_options "https://ipinfo.io/${DOMAIN}?token=${IPINFO_API_KEY:-}" 2>/dev/null | \
        jq -r '.org' 2>/dev/null | grep -oE 'AS[0-9]+' || echo "")
    
    if [ ! -z "$asn" ]; then
        log_message "SUCCESS" "Found ASN: $asn"
        
        # Query ASN ranges
        curl_with_options "https://ipinfo.io/${asn}?token=${IPINFO_API_KEY:-}" 2>/dev/null | \
            jq -r '.prefixes[].prefix' 2>/dev/null >> "$asn_file" || true
    fi
    
    # Use asnmap if available
    if command -v asnmap &> /dev/null; then
        log_message "DEBUG" "Running asnmap..."
        asnmap -d "$DOMAIN" 2>/dev/null | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]+\b' >> "$asn_file" || true
    fi
    
    local count=$(wc -l < "$asn_file")
    if [ $count -gt 0 ]; then
        log_message "SUCCESS" "Found $count IP ranges from ASN"
        ALL_IPS+=($(cat "$asn_file"))
    fi
}

search_engine_queries() {
    log_message "INFO" "Querying search engines..."
    
    local search_file="${OUTPUT_DIR}/search_results.txt"
    > "$search_file"
    
    # Shodan
    if [ ! -z "$SHODAN_API_KEY" ]; then
        log_message "DEBUG" "Querying Shodan..."
        curl_with_options "https://api.shodan.io/shodan/host/search?query=hostname:${DOMAIN}&key=${SHODAN_API_KEY}" 2>/dev/null | \
            jq -r '.matches[].ip_str' 2>/dev/null >> "$search_file" || true
    fi
    
    # Censys
    if [ ! -z "$CENSYS_API_ID" ] && [ ! -z "$CENSYS_API_SECRET" ]; then
        log_message "DEBUG" "Querying Censys..."
        local auth=$(echo -n "${CENSYS_API_ID}:${CENSYS_API_SECRET}" | base64)
        curl_with_options "https://censys.io/api/v1/search/ipv4" \
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
    log_message "INFO" "Searching Wayback Machine..."
    
    local wayback_file="${OUTPUT_DIR}/wayback_ips.txt"
    > "$wayback_file"
    
    log_message "DEBUG" "Querying archive.org..."
    curl_with_options "https://archive.org/wayback/available?url=${DOMAIN}&output=json" 2>/dev/null | \
        jq -r '.archived_snapshots[].status' 2>/dev/null | \
        grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' >> "$wayback_file" || true
    
    sort -u "$wayback_file" > "${wayback_file}.tmp"
    mv "${wayback_file}.tmp" "$wayback_file"
    
    local count=$(wc -l < "$wayback_file")
    if [ $count -gt 0 ]; then
        log_message "SUCCESS" "Found $count IPs from Wayback Machine"
        ALL_IPS+=($(cat "$wayback_file"))
    fi
}

# ============================================================================
# PHASE 2: ACTIVE RECONNAISSANCE (ENHANCED)
# ============================================================================

active_reconnaissance() {
    if [ "$STEALTH_MODE" = true ]; then
        log_message "WARNING" "Stealth mode enabled - skipping active reconnaissance"
        return
    fi
    
    log_message "INFO" "Starting Enhanced Active Reconnaissance Phase..."
    echo -e "\n${CYAN}${BOLD}[PHASE 2] ENHANCED ACTIVE RECONNAISSANCE${NC}\n"
    
    # DNS record extraction
    extract_dns_records_advanced
    
    # Zone transfer attempt
    attempt_zone_transfer
    
    # Subdomain takeover check
    check_subdomain_takeover
    
    # Port scanning
    port_scan_candidates
    
    # HTTP/HTTPS verification
    verify_http_headers
    
    # Reverse lookups
    reverse_lookups
}

extract_dns_records_advanced() {
    log_message "INFO" "Extracting DNS records..."
    
    local dns_file="${OUTPUT_DIR}/dns_records_active.txt"
    > "$dns_file"
    
    # A records
    log_message "DEBUG" "Querying A records..."
    dig +short A "$DOMAIN" >> "$dns_file" 2>/dev/null || true
    
    # MX records (often not behind CDN)
    log_message "DEBUG" "Querying MX records..."
    dig +short MX "$DOMAIN" | awk '{print $NF}' >> "$dns_file" 2>/dev/null || true
    
    # NS records
    log_message "DEBUG" "Querying NS records..."
    dig +short NS "$DOMAIN" >> "$dns_file" 2>/dev/null || true
    
    # TXT records
    log_message "DEBUG" "Querying TXT records..."
    dig +short TXT "$DOMAIN" >> "$dns_file" 2>/dev/null || true
    
    # CNAME records
    log_message "DEBUG" "Querying CNAME records..."
    dig +short CNAME "$DOMAIN" >> "$dns_file" 2>/dev/null || true
    
    # Extract IPs
    grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' "$dns_file" | sort -u > "${dns_file}.ips"
    
    local count=$(wc -l < "${dns_file}.ips")
    log_message "SUCCESS" "Extracted $count IPs from DNS records"
    ALL_IPS+=($(cat "${dns_file}.ips"))
}

attempt_zone_transfer() {
    log_message "INFO" "Attempting DNS zone transfer..."
    
    local zone_file="${OUTPUT_DIR}/zone_transfer.txt"
    > "$zone_file"
    
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

check_subdomain_takeover() {
    log_message "INFO" "Checking for subdomain takeover vulnerabilities..."
    
    local takeover_file="${OUTPUT_DIR}/subdomain_takeover.txt"
    > "$takeover_file"
    
    # Check a sample of subdomains for CNAME records pointing to unclaimed services
    local count=0
    for subdomain in "${SUBDOMAINS[@]}"; do
        count=$((count + 1))
        if [ $count -gt 20 ]; then
            break
        fi
        
        local cname=$(dig +short CNAME "$subdomain" 2>/dev/null | head -1)
        if [ ! -z "$cname" ]; then
            # Check if CNAME points to a known service
            if echo "$cname" | grep -qE "(github|heroku|s3|cloudfront|azurewebsites|wordpress)"; then
                log_message "WARNING" "Potential takeover: $subdomain -> $cname"
                echo "$subdomain -> $cname" >> "$takeover_file"
            fi
        fi
    done
}

port_scan_candidates() {
    log_message "INFO" "Scanning candidate IPs for open ports..."
    
    local scan_file="${OUTPUT_DIR}/port_scan_results.txt"
    > "$scan_file"
    
    local unique_ips=$(printf '%s\n' "${ALL_IPS[@]}" | sort -u)
    
    local count=0
    for ip in $unique_ips; do
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
        
        # Use httpx if available for faster scanning
        if command -v httpx &> /dev/null; then
            httpx -u "http://$ip" -H "Host: $DOMAIN" -silent 2>/dev/null | tee -a "$scan_file" || true
            httpx -u "https://$ip" -H "Host: $DOMAIN" -silent 2>/dev/null | tee -a "$scan_file" || true
        else
            # Fallback to netcat
            if timeout 2 nc -zv "$ip" 80 &>/dev/null; then
                echo "$ip:80 - OPEN" >> "$scan_file"
                log_message "SUCCESS" "Port 80 open on $ip"
            fi
            
            if timeout 2 nc -zv "$ip" 443 &>/dev/null; then
                echo "$ip:443 - OPEN" >> "$scan_file"
                log_message "SUCCESS" "Port 443 open on $ip"
            fi
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
        
        # Use dnsx and httpx if available
        if command -v dnsx &> /dev/null && command -v httpx &> /dev/null; then
            local response=$(echo "$DOMAIN" | dnsx -a -resp-only 2>/dev/null | head -1)
            if [ "$response" = "$ip" ]; then
                log_message "SUCCESS" "Found matching DNS response on $ip"
                echo "DNS Match: $ip" >> "$verify_file"
                REAL_IPS+=("$ip")
            fi
        fi
        
        # Try HTTP
        local response=$(curl_with_options -H "Host: $DOMAIN" -m $TIMEOUT "http://$ip" 2>/dev/null | head -c 500)
        if [ ! -z "$response" ]; then
            echo "=== $ip (HTTP) ===" >> "$verify_file"
            echo "$response" >> "$verify_file"
            echo "" >> "$verify_file"
            
            if echo "$response" | grep -q "$DOMAIN"; then
                log_message "SUCCESS" "Found matching response on $ip"
                REAL_IPS+=("$ip")
            fi
        fi
        
        # Try HTTPS
        local response=$(curl_with_options -k -H "Host: $DOMAIN" -m $TIMEOUT "https://$ip" 2>/dev/null | head -c 500)
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
            curl_with_options "https://www.viewdns.net/api/reverseip/?ip=${ip}&apikey=${VIEWDNS_API_KEY}" 2>/dev/null | \
                jq -r '.domains[].domain' 2>/dev/null >> "$reverse_file" || true
        fi
    done
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

is_cloudflare_ip() {
    local ip=$1
    
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
            if echo "$range" | grep -q "$ip"; then
                return 0
            fi
        fi
    done
    
    return 1
}

# ============================================================================
# OUTPUT FUNCTIONS (JSON, CSV, TEXT)
# ============================================================================

export_results_json() {
    local json_file="${OUTPUT_DIR}/results.json"
    
    log_message "INFO" "Exporting results to JSON..."
    
    cat > "$json_file" << EOF
{
  "scan_info": {
    "domain": "$DOMAIN",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "version": "2.0.0"
  },
  "subdomains": [
    $(printf '"%s",' "${SUBDOMAINS[@]}" | sed '$ s/,$//')
  ],
  "all_ips": [
    $(printf '"%s",' $(printf '%s\n' "${ALL_IPS[@]}" | sort -u) | sed '$ s/,$//')
  ],
  "real_ips": [
    $(printf '"%s",' "${REAL_IPS[@]}" | sed '$ s/,$//')
  ],
  "statistics": {
    "subdomains_found": ${#SUBDOMAINS[@]},
    "total_ips_discovered": $(printf '%s\n' "${ALL_IPS[@]}" | sort -u | wc -l),
    "verified_origin_ips": ${#REAL_IPS[@]}
  }
}
EOF
    
    log_message "SUCCESS" "Results exported to $json_file"
}

export_results_csv() {
    local csv_file="${OUTPUT_DIR}/results.csv"
    
    log_message "INFO" "Exporting results to CSV..."
    
    {
        echo "Type,Value,Source"
        
        for subdomain in "${SUBDOMAINS[@]}"; do
            echo "Subdomain,$subdomain,Enumeration"
        done
        
        for ip in $(printf '%s\n' "${ALL_IPS[@]}" | sort -u); do
            echo "IP,$ip,Discovery"
        done
        
        for ip in "${REAL_IPS[@]}"; do
            echo "Origin IP,$ip,Verified"
        done
    } > "$csv_file"
    
    log_message "SUCCESS" "Results exported to $csv_file"
}

# ============================================================================
# RESULTS COMPILATION
# ============================================================================

compile_results() {
    log_message "INFO" "Compiling results..."
    
    local results_file="${OUTPUT_DIR}/results_summary.txt"
    > "$results_file"
    
    echo "╔════════════════════════════════════════════════════════════════╗" >> "$results_file"
    echo "║         ORIGIN IP HUNTER v2.0 - RESULTS SUMMARY               ║" >> "$results_file"
    echo "╚════════════════════════════════════════════════════════════════╝" >> "$results_file"
    echo "" >> "$results_file"
    echo "Domain: $DOMAIN" >> "$results_file"
    echo "Scan Date: $(date)" >> "$results_file"
    echo "Output Format: $OUTPUT_FORMAT" >> "$results_file"
    echo "" >> "$results_file"
    
    # Unique IPs
    local unique_ips=$(printf '%s\n' "${ALL_IPS[@]}" | sort -u)
    echo "=== ALL DISCOVERED IPs ===" >> "$results_file"
    echo "$unique_ips" >> "$results_file"
    echo "" >> "$results_file"
    
    # Real IPs
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
    
    # Export in requested format
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        export_results_json
    elif [ "$OUTPUT_FORMAT" = "csv" ]; then
        export_results_csv
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    print_banner
    
    mkdir -p "$OUTPUT_DIR"
    LOG_FILE="${OUTPUT_DIR}/execution_$(date +%s).log"
    
    log_message "INFO" "Starting Origin IP Hunter v2.0..."
    log_message "INFO" "Target Domain: $DOMAIN"
    log_message "INFO" "Stealth Mode: $STEALTH_MODE"
    log_message "INFO" "Verbose Mode: $VERBOSE"
    log_message "INFO" "Output Format: $OUTPUT_FORMAT"
    
    validate_domain "$DOMAIN" || exit 1
    check_dependencies
    check_advanced_tools
    load_api_keys
    
    passive_reconnaissance
    active_reconnaissance
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
  -rd, --random-delay            Add random delays between requests
  -rua, --random-user-agent      Use random user agents
  -o, --output <path>            Custom output directory
  -f, --format <format>          Output format: text, json, csv (default: text)
  -h, --help                     Show this help message

Examples:
  $0 -d example.com
  $0 -d example.com --stealth -v
  $0 -d example.com -f json -o /tmp/results

EOF
    exit 0
}

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
        -rd|--random-delay)
            RANDOM_DELAY=true
            shift
            ;;
        -rua|--random-user-agent)
            RANDOM_USER_AGENT=true
            shift
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
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

if [ -z "$DOMAIN" ]; then
    echo "Error: Domain is required"
    usage
fi

main
