#!/bin/bash

# Shiro Installation Script
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
echo "  SHIRO - Installation Script"
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

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_warning "This script is optimized for macOS. Some steps may need adjustment for other OS."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 1: Check/Install Homebrew
print_status "Checking for Homebrew..."
if ! command -v brew &> /dev/null; then
    print_warning "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    print_success "Homebrew installed"
else
    print_success "Homebrew is already installed"
fi

# Step 2: Check/Install ffmpeg
print_status "Checking for ffmpeg..."
if ! command -v ffmpeg &> /dev/null; then
    print_warning "ffmpeg not found. Installing ffmpeg..."
    brew install ffmpeg
    print_success "ffmpeg installed"
else
    print_success "ffmpeg is already installed"
    ffmpeg -version | head -n 1
fi

# Step 2.5: Check/Install pkg-config (required for PyAV)
print_status "Checking for pkg-config..."
if ! command -v pkg-config &> /dev/null; then
    print_warning "pkg-config not found. Installing pkg-config..."
    brew install pkg-config
    print_success "pkg-config installed"
else
    print_success "pkg-config is already installed"
fi

# Step 3: Check Python version and auto-fix if needed
print_status "Checking Python version..."
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3.10-3.13."
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
MAJOR_VERSION=$(echo "$PYTHON_VERSION" | cut -d. -f1)
MINOR_VERSION=$(echo "$PYTHON_VERSION" | cut -d. -f2)

# Function to check if a Python version is compatible (3.10-3.13)
is_compatible_version() {
    local version=$1
    local major=$(echo "$version" | cut -d. -f1)
    local minor=$(echo "$version" | cut -d. -f2)

    if [ "$major" -eq 3 ] && [ "$minor" -ge 10 ] && [ "$minor" -le 13 ]; then
        return 0  # Compatible
    else
        return 1  # Not compatible
    fi
}

# Check if current Python is compatible
if is_compatible_version "$PYTHON_VERSION"; then
    print_success "Python $PYTHON_VERSION found (compatible)"
else
    print_warning "Python $PYTHON_VERSION found (incompatible - needs 3.10-3.13)"

    # Try to auto-fix using pyenv
    if command -v pyenv &> /dev/null; then
        # Initialize pyenv for this session
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"

        print_status "Searching for compatible Python version via pyenv..."

        # Get list of installed pyenv versions
        COMPATIBLE_VERSION=""
        while IFS= read -r version; do
            # Clean up version string (remove leading/trailing whitespace and *)
            clean_version=$(echo "$version" | sed 's/^[* ]*//' | sed 's/ .*//')

            # Skip if it's not a version number
            if [[ ! "$clean_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                continue
            fi

            # Check if this version is compatible
            if is_compatible_version "$clean_version"; then
                COMPATIBLE_VERSION="$clean_version"
                break
            fi
        done < <(pyenv versions --bare)

        if [ -n "$COMPATIBLE_VERSION" ]; then
            print_success "Found compatible Python $COMPATIBLE_VERSION via pyenv"
            print_status "Automatically switching to Python $COMPATIBLE_VERSION for this project..."

            # Set local version for this project
            pyenv local "$COMPATIBLE_VERSION"

            # Clear shell hash to pick up new python3
            hash -r 2>/dev/null || true

            # Verify the switch worked
            NEW_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
            if is_compatible_version "$NEW_VERSION"; then
                print_success "Successfully switched to Python $NEW_VERSION"
                PYTHON_VERSION="$NEW_VERSION"
                MAJOR_VERSION=$(echo "$PYTHON_VERSION" | cut -d. -f1)
                MINOR_VERSION=$(echo "$PYTHON_VERSION" | cut -d. -f2)
            else
                print_error "Failed to switch Python version"
                exit 1
            fi
        else
            # No compatible version found, offer to install
            print_warning "No compatible Python version found in pyenv"
            echo ""
            echo "  ${YELLOW}Auto-installing Python 3.12.8...${NC}"
            echo ""

            if pyenv install 3.12.8; then
                print_success "Python 3.12.8 installed successfully"
                pyenv local 3.12.8
                hash -r 2>/dev/null || true
                PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
                print_success "Switched to Python $PYTHON_VERSION"
            else
                print_error "Failed to install Python 3.12.8"
                echo ""
                echo "  Please install manually:"
                echo "    ${BLUE}pyenv install 3.12.8${NC}"
                echo "    ${BLUE}pyenv local 3.12.8${NC}"
                echo "    ${BLUE}./install.sh${NC}"
                exit 1
            fi
        fi
    else
        # pyenv not installed - offer to install it
        print_warning "pyenv is not installed"
        echo ""
        echo "  ${YELLOW}Auto-installing pyenv and Python 3.12.8...${NC}"
        echo ""

        # Install pyenv via Homebrew
        print_status "Installing pyenv..."
        if brew install pyenv; then
            print_success "pyenv installed"

            # Configure shell
            print_status "Configuring shell environment..."
            if [ -f ~/.zshrc ]; then
                if ! grep -q "PYENV_ROOT" ~/.zshrc; then
                    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
                    echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
                    echo 'eval "$(pyenv init -)"' >> ~/.zshrc
                    print_success "Shell configuration updated"
                fi
            fi

            # Initialize pyenv for current session
            export PYENV_ROOT="$HOME/.pyenv"
            export PATH="$PYENV_ROOT/bin:$PATH"
            eval "$(pyenv init -)"

            # Install Python 3.12.8
            print_status "Installing Python 3.12.8 (this may take several minutes)..."
            if pyenv install 3.12.8; then
                print_success "Python 3.12.8 installed"

                # Set local version
                pyenv local 3.12.8

                # Clear shell hash to pick up new python3
                hash -r 2>/dev/null || true

                # Verify
                PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
                print_success "Switched to Python $PYTHON_VERSION"
                echo ""
                print_warning "Shell configuration was updated. After installation completes, restart your terminal or run:"
                echo "           ${BLUE}source ~/.zshrc${NC}"
            else
                print_error "Failed to install Python 3.12.8"
                echo ""
                echo "  Please try manually:"
                echo "    ${BLUE}source ~/.zshrc${NC}"
                echo "    ${BLUE}pyenv install 3.12.8${NC}"
                echo "    ${BLUE}pyenv local 3.12.8${NC}"
                echo "    ${BLUE}./install.sh${NC}"
                exit 1
            fi
        else
            print_error "Failed to install pyenv"
            echo ""
            echo "  Please install manually:"
            echo "    ${BLUE}brew install pyenv${NC}"
            echo "    ${BLUE}echo 'export PYENV_ROOT=\"\$HOME/.pyenv\"' >> ~/.zshrc${NC}"
            echo "    ${BLUE}echo '[[ -d \$PYENV_ROOT/bin ]] && export PATH=\"\$PYENV_ROOT/bin:\$PATH\"' >> ~/.zshrc${NC}"
            echo "    ${BLUE}echo 'eval \"\$(pyenv init -)\"' >> ~/.zshrc${NC}"
            echo "    ${BLUE}source ~/.zshrc${NC}"
            echo "    ${BLUE}pyenv install 3.12.8${NC}"
            echo "    ${BLUE}cd $(pwd)${NC}"
            echo "    ${BLUE}pyenv local 3.12.8${NC}"
            echo "    ${BLUE}./install.sh${NC}"
            echo ""
            echo "  See ${BLUE}PYTHON_VERSION_FIX.md${NC} for detailed guide"
            exit 1
        fi
    fi
fi

# Final verification
if ! is_compatible_version "$PYTHON_VERSION"; then
    print_error "Python version check failed. Expected 3.10-3.13, got $PYTHON_VERSION"
    exit 1
fi

# Step 4: Create virtual environment
print_status "Setting up Python virtual environment..."
if [ -d "venv" ]; then
    # Check if existing venv uses the correct Python version
    if [ -f "venv/bin/python" ]; then
        VENV_PYTHON_VERSION=$(venv/bin/python --version 2>&1 | cut -d' ' -f2)
        if [ "$VENV_PYTHON_VERSION" != "$PYTHON_VERSION" ]; then
            print_warning "Existing venv uses Python $VENV_PYTHON_VERSION, but we need $PYTHON_VERSION"
            print_status "Removing old virtual environment..."
            rm -rf venv
            print_status "Creating new virtual environment with Python $PYTHON_VERSION..."
            python3 -m venv venv
            print_success "Virtual environment created"
        else
            print_success "Virtual environment already exists with correct Python version"
        fi
    else
        # venv directory exists but is invalid
        print_warning "Invalid venv directory found"
        rm -rf venv
        python3 -m venv venv
        print_success "Virtual environment created"
    fi
else
    python3 -m venv venv
    print_success "Virtual environment created"
fi

# Step 5: Activate virtual environment and install dependencies
print_status "Installing Python dependencies..."
source venv/bin/activate

# Upgrade pip
print_status "Upgrading pip..."
pip install --upgrade pip --quiet

# Install requirements
print_status "Installing packages (this may take a few minutes)..."
echo "           This includes faster-whisper, anthropic, and their dependencies..."

if pip install -r requirements.txt; then
    print_success "Python dependencies installed"
else
    print_error "Failed to install Python dependencies"
    echo ""
    echo "Try installing pkg-config manually:"
    echo "  brew install pkg-config"
    echo ""
    echo "Then run this script again, or install manually with:"
    echo "  source venv/bin/activate"
    echo "  pip install -r requirements.txt"
    exit 1
fi

# Step 6: Set up environment file
print_status "Setting up environment configuration..."
if [ -f ".env" ]; then
    print_warning ".env file already exists. Skipping creation."
    echo "           To reconfigure, edit .env manually or delete it and run install.sh again."
else
    cp .env.example .env
    print_success ".env file created from template"
    echo ""
    print_warning "IMPORTANT: You need to add your Anthropic API key to .env"
    echo ""
    echo "   1. Get your API key from: https://console.anthropic.com/settings/keys"
    echo "   2. Open .env file and replace 'your_api_key_here' with your actual key"
    echo ""
    read -p "Do you want to enter your API key now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        read -p "Enter your Anthropic API key: " api_key
        if [ -n "$api_key" ]; then
            # Update the .env file with the API key
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s/your_api_key_here/$api_key/" .env
            else
                sed -i "s/your_api_key_here/$api_key/" .env
            fi
            print_success "API key saved to .env"
        else
            print_warning "No API key entered. You'll need to edit .env manually."
        fi
    else
        print_warning "Remember to edit .env and add your API key before running Shiro!"
    fi
fi

# Step 7: Create output directory
print_status "Creating output directory..."
mkdir -p output
print_success "Output directory created"

# Step 8: Verify installation
print_status "Verifying installation..."

# Test imports
python3 << 'PYTHON_SCRIPT'
import sys
try:
    import anthropic
    import whisper
    from dotenv import load_dotenv
    print("✓ All Python packages imported successfully")
    sys.exit(0)
except ImportError as e:
    print(f"✗ Import error: {e}")
    sys.exit(1)
PYTHON_SCRIPT

if [ $? -eq 0 ]; then
    print_success "Python packages verified"
else
    print_error "Package verification failed"
    exit 1
fi

# Final success message
echo ""
echo "======================================================================"
echo -e "${GREEN}✨ Installation Complete!${NC}"
echo "======================================================================"
echo ""
echo "Next steps:"
echo ""
echo "  1. Activate the virtual environment:"
echo "     ${BLUE}source venv/bin/activate${NC}"
echo ""

if ! grep -q "^ANTHROPIC_API_KEY=sk-ant-" .env 2>/dev/null; then
    echo "  2. Add your Anthropic API key to .env:"
    echo "     ${BLUE}nano .env${NC}  # or use your preferred editor"
    echo ""
    echo "  3. Run Shiro:"
else
    echo "  2. Run Shiro:"
fi
echo "     ${BLUE}python shiro.py /path/to/your/meeting.mkv${NC}"
echo ""
echo "For help and examples, see:"
echo "  - QUICKSTART.md for quick guide"
echo "  - README.md for full documentation"
echo ""
echo "======================================================================"
echo ""

# Deactivate virtual environment
deactivate 2>/dev/null || true
