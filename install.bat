@echo off
REM Shiro Installation Script for Windows
REM Automates the setup process for the meeting transcription tool

echo.
echo ======================================================================
echo   SHIRO - Windows Installation Script
echo ======================================================================
echo.

REM Check Python version
echo [*] Checking Python installation...
python --version >nul 2>&1
if errorlevel 1 (
    echo [X] Python is not installed!
    echo.
    echo Please install Python 3.10-3.13 from https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation
    pause
    exit /b 1
)

REM Get Python version
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo [+] Found Python %PYTHON_VERSION%

REM Check if Python version is compatible (3.10-3.13)
for /f "tokens=1,2 delims=." %%a in ("%PYTHON_VERSION%") do (
    set MAJOR=%%a
    set MINOR=%%b
)

if %MAJOR% LSS 3 (
    echo [X] Python version too old! Need Python 3.10 or newer
    pause
    exit /b 1
)

if %MAJOR% EQU 3 (
    if %MINOR% LSS 10 (
        echo [X] Python 3.%MINOR% is too old! Need Python 3.10 or newer
        pause
        exit /b 1
    )
    if %MINOR% GEQ 14 (
        echo [!] Python 3.%MINOR% is too new! Some dependencies may not work
        echo [!] Recommended: Install Python 3.12 from https://www.python.org/downloads/
        pause
    )
)

echo [+] Python version is compatible

REM Check for ffmpeg
echo.
echo [*] Checking for ffmpeg...
ffmpeg -version >nul 2>&1
if errorlevel 1 (
    echo [X] ffmpeg is not installed!
    echo.
    echo Please install ffmpeg:
    echo 1. Using Chocolatey: choco install ffmpeg
    echo 2. Using Scoop: scoop install ffmpeg
    echo 3. Download from: https://ffmpeg.org/download.html
    echo.
    echo After installation, restart this script.
    pause
    exit /b 1
) else (
    echo [+] ffmpeg is installed
)

REM Create virtual environment
echo.
echo [*] Creating virtual environment...
if exist venv (
    echo [!] Virtual environment already exists, skipping creation
) else (
    python -m venv venv
    if errorlevel 1 (
        echo [X] Failed to create virtual environment
        pause
        exit /b 1
    )
    echo [+] Virtual environment created
)

REM Activate virtual environment
echo.
echo [*] Activating virtual environment...
call venv\Scripts\activate.bat
if errorlevel 1 (
    echo [X] Failed to activate virtual environment
    pause
    exit /b 1
)

REM Upgrade pip
echo.
echo [*] Upgrading pip...
python -m pip install --upgrade pip --quiet
echo [+] pip upgraded

REM Install requirements
echo.
echo [*] Installing Python dependencies...
echo [!] This may take several minutes (downloading Whisper models)
pip install -r requirements.txt
if errorlevel 1 (
    echo [X] Failed to install dependencies
    pause
    exit /b 1
)
echo [+] Dependencies installed successfully

REM Create output directory
if not exist output mkdir output
echo [+] Output directory ready

REM Setup environment file
echo.
if not exist .env (
    echo [*] Creating .env file from template...
    copy .env.example .env >nul
    echo [+] .env file created
    echo.
    echo [!] IMPORTANT: Edit .env file and add your Anthropic API key
    echo [!] Location: .env
) else (
    echo [+] .env file already exists
)

REM Verify installation
echo.
echo [*] Verifying installation...
python -c "import whisper; import anthropic; import dotenv" 2>nul
if errorlevel 1 (
    echo [X] Import test failed - installation may be incomplete
    pause
    exit /b 1
)
echo [+] All imports successful

REM Print success message
echo.
echo ======================================================================
echo [+] Installation Complete!
echo ======================================================================
echo.
echo Next steps:
echo 1. Edit .env file and add your Anthropic API key (optional for summarization)
echo    - Get your key from: https://console.anthropic.com/
echo.
echo 2. Run Shiro:
echo    venv\Scripts\activate
echo    python shiro.py your_meeting_video.mkv
echo.
echo 3. For help:
echo    python shiro.py --help
echo.
echo ======================================================================
echo.

pause
