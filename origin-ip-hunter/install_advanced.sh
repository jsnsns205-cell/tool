#!/bin/bash

################################################################################
# Origin IP Hunter - Advanced Installation Script
# Installs all dependencies including advanced OSINT tools
# Version: 2.0.0
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

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
║  🔧 ORIGIN IP HUNTER v2.0 - ADVANCED INSTALLATION 🔧          ║
║                                                               ║
║   Setting up comprehensive OSINT reconnaissance toolkit      ║
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

install_base_dependencies() {
    print_info "Installing base dependencies..."
    
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
                openssl \
                python3 \
                python3-pip \
                build-essential \
                libssl-dev \
                libffi-dev \
                wget \
                unzip
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
                openssl \
                python3 \
                python3-pip \
                gcc \
                openssl-devel \
                libffi-devel \
                wget \
                unzip
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
                openssl \
                python \
                base-devel \
                wget \
                unzip
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
                openssl \
                python3 \
                wget \
                unzip
            ;;
        *)
            print_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
    
    print_success "Base dependencies installed"
}

install_advanced_tools() {
    print_info "Installing advanced OSINT tools..."
    echo ""
    
    # theHarvester
    print_info "Installing theHarvester..."
    if ! command -v theHarvester &> /dev/null; then
        pip3 install theHarvester 2>/dev/null || print_warning "theHarvester installation failed"
    else
        print_success "theHarvester already installed"
    fi
    
    # dnsx (ProjectDiscovery)
    print_info "Installing dnsx..."
    if ! command -v dnsx &> /dev/null; then
        if command -v go &> /dev/null; then
            go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest 2>/dev/null || print_warning "dnsx installation failed"
        else
            print_warning "Go not installed, skipping dnsx"
        fi
    else
        print_success "dnsx already installed"
    fi
    
    # httpx (ProjectDiscovery)
    print_info "Installing httpx..."
    if ! command -v httpx &> /dev/null; then
        if command -v go &> /dev/null; then
            go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest 2>/dev/null || print_warning "httpx installation failed"
        else
            print_warning "Go not installed, skipping httpx"
        fi
    else
        print_success "httpx already installed"
    fi
    
    # Amass
    print_info "Installing Amass..."
    if ! command -v amass &> /dev/null; then
        if command -v go &> /dev/null; then
            go install -v github.com/OWASP/Amass/v3/...@master 2>/dev/null || print_warning "Amass installation failed"
        else
            print_warning "Go not installed, skipping Amass"
        fi
    else
        print_success "Amass already installed"
    fi
    
    # assetfinder
    print_info "Installing assetfinder..."
    if ! command -v assetfinder &> /dev/null; then
        if command -v go &> /dev/null; then
            go install -v github.com/tomnomnom/assetfinder@latest 2>/dev/null || print_warning "assetfinder installation failed"
        else
            print_warning "Go not installed, skipping assetfinder"
        fi
    else
        print_success "assetfinder already installed"
    fi
    
    # altdns
    print_info "Installing altdns..."
    if ! command -v altdns &> /dev/null; then
        pip3 install altdns 2>/dev/null || print_warning "altdns installation failed"
    else
        print_success "altdns already installed"
    fi
    
    # asnmap (ProjectDiscovery)
    print_info "Installing asnmap..."
    if ! command -v asnmap &> /dev/null; then
        if command -v go &> /dev/null; then
            go install -v github.com/projectdiscovery/asnmap/cmd/asnmap@latest 2>/dev/null || print_warning "asnmap installation failed"
        else
            print_warning "Go not installed, skipping asnmap"
        fi
    else
        print_success "asnmap already installed"
    fi
    
    # Subfinder (ProjectDiscovery)
    print_info "Installing subfinder..."
    if ! command -v subfinder &> /dev/null; then
        if command -v go &> /dev/null; then
            go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest 2>/dev/null || print_warning "subfinder installation failed"
        else
            print_warning "Go not installed, skipping subfinder"
        fi
    else
        print_success "subfinder already installed"
    fi
    
    echo ""
    print_success "Advanced tools installation completed"
}

install_go() {
    print_info "Checking for Go installation..."
    
    if command -v go &> /dev/null; then
        print_success "Go is already installed"
        return
    fi
    
    print_warning "Go is not installed. Some tools require Go."
    print_info "Installing Go..."
    
    case $OS in
        ubuntu|debian|fedora|rhel|centos|arch)
            if [ "$OS" = "macos" ]; then
                brew install go
            else
                wget -q https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
                sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
                rm go1.21.0.linux-amd64.tar.gz
                echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
                export PATH=$PATH:/usr/local/go/bin
            fi
            ;;
        macos)
            brew install go
            ;;
    esac
    
    print_success "Go installed successfully"
}

setup_directories() {
    print_info "Setting up directories..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    mkdir -p "$script_dir/output"
    mkdir -p "$script_dir/config"
    mkdir -p "$script_dir/logs"
    mkdir -p "$script_dir/wordlists"
    
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
        cp "$script_dir/config/api_keys.conf.example" "$config_file" 2>/dev/null || true
        chmod 600 "$config_file"
        print_success "Configuration template created"
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
    
    print_success "All required dependencies verified"
}

create_symlink() {
    print_info "Creating symlinks for easy access..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local main_script="$script_dir/src/origin_ip_hunter.sh"
    local enhanced_script="$script_dir/src/origin_ip_hunter_enhanced.sh"
    local symlink="/usr/local/bin/origin-ip-hunter"
    local symlink_enhanced="/usr/local/bin/origin-ip-hunter-enhanced"
    
    if [ -f "$main_script" ]; then
        if sudo ln -sf "$main_script" "$symlink" 2>/dev/null; then
            print_success "Symlink created: $symlink"
        else
            print_warning "Could not create symlink (requires sudo)"
        fi
    fi
    
    if [ -f "$enhanced_script" ]; then
        if sudo ln -sf "$enhanced_script" "$symlink_enhanced" 2>/dev/null; then
            print_success "Symlink created: $symlink_enhanced"
        else
            print_warning "Could not create symlink (requires sudo)"
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
    echo "2. Run the standard tool:"
    echo "   ./src/origin_ip_hunter.sh -d example.com"
    echo ""
    echo "3. Run the enhanced version with advanced features:"
    echo "   ./src/origin_ip_hunter_enhanced.sh -d example.com"
    echo ""
    echo "4. View results:"
    echo "   ls -la output/"
    echo ""
    echo -e "${CYAN}${BOLD}Available Options (Enhanced Version):${NC}"
    echo "   -d, --domain <domain>           Target domain to scan"
    echo "   -s, --stealth                   Passive reconnaissance only"
    echo "   -t, --tor                       Use TOR proxy"
    echo "   -v, --verbose                   Enable verbose output"
    echo "   -rd, --random-delay             Add random delays between requests"
    echo "   -rua, --random-user-agent       Use random user agents"
    echo "   -f, --format <format>           Output format (text, json, csv)"
    echo "   -o, --output <path>             Custom output directory"
    echo ""
}

main() {
    print_header
    
    detect_os
    
    print_info "Detected OS: $OS"
    print_info "Starting advanced installation..."
    echo ""
    
    install_base_dependencies
    install_go
    install_advanced_tools
    setup_directories
    create_config_template
    verify_installation
    create_symlink
    
    echo ""
    print_success "Advanced installation completed successfully!"
    print_next_steps
}

main
