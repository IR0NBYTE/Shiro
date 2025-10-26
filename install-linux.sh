#!/bin/bash

# Shiro Installation Script for Linux
# Automates the setup process for the meeting transcription tool

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print banner
echo ""
echo "======================================================================"
echo "  SHIRO - Linux Installation Script"
echo "======================================================================"
echo ""

# Function to print colored output
print_status() {
    echo -e "${BLUE}==>${NC} $1"
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

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    print_error "Cannot detect Linux distribution"
    exit 1
fi

print_status "Detected distribution: $DISTRO"

# Step 1: Check/Install Python
print_status "Checking Python installation..."

if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed!"
    echo ""
    echo "Please install Python 3.10 or newer:"
    if [ "$DISTRO" = "ubuntu" ] || [ "$DISTRO" = "debian" ]; then
        echo "  sudo apt update"
        echo "  sudo apt install python3 python3-pip python3-venv"
    elif [ "$DISTRO" = "fedora" ] || [ "$DISTRO" = "rhel" ] || [ "$DISTRO" = "centos" ]; then
        echo "  sudo dnf install python3 python3-pip"
    elif [ "$DISTRO" = "arch" ] || [ "$DISTRO" = "manjaro" ]; then
        echo "  sudo pacman -S python python-pip"
    fi
    exit 1
fi

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
MAJOR_VERSION=$(echo $PYTHON_VERSION | cut -d'.' -f1)
MINOR_VERSION=$(echo $PYTHON_VERSION | cut -d'.' -f2)

print_success "Python $PYTHON_VERSION found"

# Verify version is compatible (3.10-3.13)
if [ "$MAJOR_VERSION" -lt 3 ] || ([ "$MAJOR_VERSION" -eq 3 ] && [ "$MINOR_VERSION" -lt 10 ]); then
    print_error "Python $PYTHON_VERSION is too old!"
    print_error "Shiro requires Python 3.10 or newer"
    echo ""
    echo "Install newer Python:"
    if [ "$DISTRO" = "ubuntu" ] || [ "$DISTRO" = "debian" ]; then
        echo "  sudo add-apt-repository ppa:deadsnakes/ppa"
        echo "  sudo apt update"
        echo "  sudo apt install python3.12 python3.12-venv"
        echo "  # Then use: python3.12 instead of python3"
    fi
    exit 1
fi

if [ "$MAJOR_VERSION" -eq 3 ] && [ "$MINOR_VERSION" -ge 14 ]; then
    print_warning "Python $PYTHON_VERSION is very new - some dependencies may not be available yet"
    print_warning "Recommended: Use Python 3.12 for best compatibility"
    echo ""
fi

# Step 2: Check/Install ffmpeg
print_status "Checking for ffmpeg..."

if ! command -v ffmpeg &> /dev/null; then
    print_error "ffmpeg is not installed!"
    echo ""
    print_status "Installing ffmpeg..."

    if [ "$DISTRO" = "ubuntu" ] || [ "$DISTRO" = "debian" ]; then
        sudo apt update
        sudo apt install -y ffmpeg
    elif [ "$DISTRO" = "fedora" ] || [ "$DISTRO" = "rhel" ] || [ "$DISTRO" = "centos" ]; then
        sudo dnf install -y ffmpeg
    elif [ "$DISTRO" = "arch" ] || [ "$DISTRO" = "manjaro" ]; then
        sudo pacman -S --noconfirm ffmpeg
    else
        print_error "Cannot auto-install ffmpeg for $DISTRO"
        echo "Please install ffmpeg manually and re-run this script"
        exit 1
    fi

    print_success "ffmpeg installed"
else
    print_success "ffmpeg is already installed"
fi

# Step 3: Check/Install development tools (needed for some Python packages)
print_status "Checking for development tools..."

if [ "$DISTRO" = "ubuntu" ] || [ "$DISTRO" = "debian" ]; then
    if ! dpkg -l | grep -q python3-dev; then
        print_status "Installing Python development headers..."
        sudo apt install -y python3-dev build-essential
    fi
elif [ "$DISTRO" = "fedora" ] || [ "$DISTRO" = "rhel" ] || [ "$DISTRO" = "centos" ]; then
    if ! rpm -qa | grep -q python3-devel; then
        print_status "Installing Python development headers..."
        sudo dnf install -y python3-devel gcc gcc-c++ make
    fi
elif [ "$DISTRO" = "arch" ] || [ "$DISTRO" = "manjaro" ]; then
    # Base-devel group usually already installed
    print_success "Development tools check passed"
fi

# Step 4: Create virtual environment
print_status "Creating virtual environment..."

if [ -d "venv" ]; then
    print_warning "Virtual environment already exists"

    # Check if venv Python version matches system Python
    VENV_PYTHON_VERSION=$(venv/bin/python --version 2>&1 | cut -d' ' -f2)
    if [ "$VENV_PYTHON_VERSION" != "$PYTHON_VERSION" ]; then
        print_warning "Virtual environment uses different Python version ($VENV_PYTHON_VERSION)"
        print_status "Recreating virtual environment with Python $PYTHON_VERSION..."
        rm -rf venv
        python3 -m venv venv
        print_success "Virtual environment recreated"
    else
        print_success "Virtual environment version is up to date"
    fi
else
    python3 -m venv venv
    print_success "Virtual environment created"
fi

# Step 5: Activate virtual environment and install dependencies
print_status "Installing Python dependencies..."

# Activate venv
source venv/bin/activate

# Upgrade pip
print_status "Upgrading pip..."
pip install --upgrade pip --quiet

# Install requirements
print_status "Installing packages (this may take several minutes)..."
pip install -r requirements.txt

print_success "All dependencies installed"

# Step 6: Create output directory
mkdir -p output
print_success "Output directory ready"

# Step 7: Setup environment file
if [ ! -f .env ]; then
    print_status "Creating .env file from template..."
    cp .env.example .env
    print_success ".env file created"
    echo ""
    print_warning "IMPORTANT: Edit .env file and add your Anthropic API key"
    print_warning "Location: $(pwd)/.env"
else
    print_success ".env file already exists"
fi

# Step 8: Verify installation
print_status "Verifying installation..."

python -c "import whisper; import anthropic; import dotenv" 2>/dev/null
if [ $? -eq 0 ]; then
    print_success "All imports successful"
else
    print_error "Import test failed - installation may be incomplete"
    exit 1
fi

# Print success message
echo ""
echo "======================================================================"
print_success "Installation Complete!"
echo "======================================================================"
echo ""
echo "Next steps:"
echo ""
echo "1. Edit .env file and add your Anthropic API key (optional for summarization)"
echo "   Get your key from: https://console.anthropic.com/"
echo ""
echo "2. Run Shiro:"
echo "   source venv/bin/activate"
echo "   python shiro.py your_meeting_video.mkv"
echo ""
echo "3. For help:"
echo "   python shiro.py --help"
echo ""
echo "======================================================================"
echo ""
