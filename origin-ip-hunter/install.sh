#!/bin/bash

################################################################################
# Origin IP Hunter - Installation Script
# Purpose: Install all dependencies and configure the tool
# Author: Manus AI
# Version: 1.0.0
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
}

print_header() {
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     🔧 ORIGIN IP HUNTER - INSTALLATION SCRIPT 🔧              ║
║                                                               ║
║   Setting up the advanced OSINT reconnaissance tool          ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

install_dependencies() {
    print_info "Installing dependencies..."
    
    case $OS in
        ubuntu|debian)
            print_info "Detected Debian/Ubuntu system"
            sudo apt-get update
            sudo apt-get install -y \
                curl \
                dnsutils \
                whois \
                netcat-openbsd \
                jq \
                git \
                parallel \
                openssl
            ;;
        fedora|rhel|centos)
            print_info "Detected RHEL/Fedora system"
            sudo dnf install -y \
                curl \
                bind-utils \
                whois \
                ncat \
                jq \
                git \
                parallel \
                openssl
            ;;
        arch)
            print_info "Detected Arch Linux system"
            sudo pacman -S --noconfirm \
                curl \
                bind \
                whois \
                netcat \
                jq \
                git \
                parallel \
                openssl
            ;;
        macos)
            print_info "Detected macOS system"
            if ! command -v brew &> /dev/null; then
                print_error "Homebrew not found. Please install it first:"
                echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                exit 1
            fi
            brew install \
                curl \
                bind \
                whois \
                netcat \
                jq \
                git \
                parallel \
                openssl
            ;;
        *)
            print_error "Unsupported OS: $OS"
            print_info "Please install the following tools manually:"
            echo "  - curl"
            echo "  - dig/dnsutils"
            echo "  - whois"
            echo "  - netcat"
            echo "  - jq"
            echo "  - git"
            echo "  - parallel"
            echo "  - openssl"
            exit 1
            ;;
    esac
    
    print_success "Dependencies installed"
}

setup_directories() {
    print_info "Setting up directories..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    mkdir -p "$script_dir/output"
    mkdir -p "$script_dir/config"
    mkdir -p "$script_dir/logs"
    
    chmod 755 "$script_dir/output"
    chmod 755 "$script_dir/config"
    chmod 755 "$script_dir/logs"
    
    print_success "Directories created"
}

create_config_template() {
    print_info "Creating configuration template..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local config_file="$script_dir/config/api_keys.conf"
    
    if [ ! -f "$config_file" ]; then
        cat > "$config_file" << 'EOF'
################################################################################
# Origin IP Hunter - API Keys Configuration
# Add your API keys here to enhance reconnaissance capabilities
# Leave blank to use free APIs only
################################################################################

# Shodan API Key
# Get it from: https://www.shodan.io/
SHODAN_API_KEY=""

# VirusTotal API Key
# Get it from: https://www.virustotal.com/
VIRUSTOTAL_API_KEY=""

# Censys API Credentials
# Get them from: https://censys.com/
CENSYS_API_ID=""
CENSYS_API_SECRET=""

# SecurityTrails API Key
# Get it from: https://securitytrails.com/
SECURITYTRAILS_API_KEY=""

# ipinfo.io API Key
# Get it from: https://ipinfo.io/
IPINFO_API_KEY=""

# ViewDNS API Key
# Get it from: https://www.viewdns.net/
VIEWDNS_API_KEY=""

# HunterIO API Key (for email enumeration)
# Get it from: https://hunter.io/
HUNTER_API_KEY=""

# WhoisXML API Key (for historical DNS)
# Get it from: https://whoisxmlapi.com/
WHOISXML_API_KEY=""

################################################################################
# Optional Settings
################################################################################

# TOR Proxy (if using TOR)
TOR_PROXY="socks5://127.0.0.1:9050"

# Custom timeout for requests (in seconds)
REQUEST_TIMEOUT="10"

# Maximum number of IPs to scan in active reconnaissance
MAX_IPS_TO_SCAN="50"

# Enable debug logging
DEBUG_MODE="false"
EOF
        chmod 600 "$config_file"
        print_success "Configuration template created at: $config_file"
        print_warning "Please add your API keys to: $config_file"
    else
        print_info "Configuration file already exists"
    fi
}

verify_installation() {
    print_info "Verifying installation..."
    
    local required_tools=("curl" "dig" "jq" "whois" "nc" "grep" "awk" "sed")
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        else
            print_success "$tool is installed"
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing tools: ${missing_tools[*]}"
        exit 1
    fi
    
    print_success "All dependencies verified"
}

create_symlink() {
    print_info "Creating symlink for easy access..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local main_script="$script_dir/src/origin_ip_hunter.sh"
    local symlink="/usr/local/bin/origin-ip-hunter"
    
    if [ -f "$main_script" ]; then
        if sudo ln -sf "$main_script" "$symlink" 2>/dev/null; then
            print_success "Symlink created: $symlink"
            print_info "You can now run: origin-ip-hunter -d example.com"
        else
            print_warning "Could not create symlink (requires sudo). Run manually:"
            echo "  sudo ln -sf $main_script $symlink"
        fi
    fi
}

print_next_steps() {
    echo ""
    echo -e "${CYAN}${BOLD}Next Steps:${NC}"
    echo ""
    echo "1. Add your API keys to the configuration file:"
    echo "   nano config/api_keys.conf"
    echo ""
    echo "2. Run the tool:"
    echo "   ./src/origin_ip_hunter.sh -d example.com"
    echo ""
    echo "3. View results:"
    echo "   ls -la output/"
    echo ""
    echo -e "${CYAN}${BOLD}Available Options:${NC}"
    echo "   -d, --domain <domain>    Target domain to scan"
    echo "   -s, --stealth            Passive reconnaissance only"
    echo "   -v, --verbose            Enable verbose output"
    echo "   -o, --output <path>      Custom output directory"
    echo "   -h, --help               Show help message"
    echo ""
    echo -e "${CYAN}${BOLD}Documentation:${NC}"
    echo "   See README.md for detailed usage and examples"
    echo ""
}

main() {
    print_header
    
    detect_os
    
    print_info "Detected OS: $OS"
    print_info "Starting installation..."
    echo ""
    
    install_dependencies
    setup_directories
    create_config_template
    verify_installation
    create_symlink
    
    echo ""
    print_success "Installation completed successfully!"
    print_next_steps
}

# Run main function
main
