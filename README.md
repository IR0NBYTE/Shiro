# Shiro 🎯

> **100% Free & Open-Source Meeting Transcription & Summarization**
>
> Never miss important details from your meetings again. Shiro transcribes and summarizes your meeting recordings using powerful local AI models and optional cloud summarization.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Open Source](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)](https://opensource.org/)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)

---

## Why Shiro?

### The Problem

I was having weekly 1-on-1s with my manager, and every time I'd walk away feeling like I'd captured the key points. But inevitably, a few days later, I'd realize I'd missed something important—an action item, a deadline, or a nuanced piece of feedback.

I tried taking more detailed notes, but then I wasn't fully present in the conversation. I tried recording and rewatching, but who has time to watch an hour-long meeting again? Commercial transcription services were either expensive, had subscription fees, or I didn't trust them with my work conversations.

### The Solution

So I built Shiro. It's a simple tool that:
- **Extracts audio** from meeting recordings (MKV, MP4, etc.)
- **Transcribes** using OpenAI's Whisper model running **locally on your machine**
- **Summarizes** using Claude API to extract action items, decisions, and key discussion points

No subscriptions. No hidden fees. No data leaving your machine unless you want it to (for summarization). Just a tool built by a developer who was tired of missing details.

### Why Free & Open-Source?

**Privacy First:** Your meeting recordings are sensitive. Shiro runs transcription entirely on your machine—your data never leaves your computer unless you explicitly choose to use the optional cloud summarization.

**No Vendor Lock-In:** No subscriptions, no credits, no usage limits. Install it once, use it forever.

**Community-Driven:** The best tools are built by communities. If Shiro helps you, consider contributing back—whether that's code, documentation, bug reports, or just spreading the word.

**Transparency:** You can see exactly what the code does. No black boxes, no telemetry, no surprises.

---

## Features

- 🎤 **Local Speech-to-Text**: Uses OpenAI Whisper for accurate transcription
- 🎬 **Video Audio Extraction**: Automatically extracts audio from MKV, MP4, and other video formats
- 📝 **Multiple Output Formats**: JSON (detailed), TXT (clean text), SRT (subtitles), Markdown
- 🧠 **AI-Powered Summaries**: Optional Claude API integration for intelligent meeting analysis
- ⚡ **Smart Auto-Detection**: Skips already-completed steps (audio extraction, transcription)
- 🔒 **Privacy-Focused**: All transcription happens on your machine
- 💰 **100% Free**: No subscriptions, no hidden fees, completely open-source
- 🎯 **Action Item Extraction**: Automatically identifies tasks, decisions, and follow-ups
- ⏱️ **Word-Level Timestamps**: Detailed timing information for every word
- 🔧 **Automated Setup**: One-command installation with automatic Python version management

---

## Quick Start

### Installation

#### macOS

```bash
# Clone the repository
git clone https://github.com/yourusername/shiro.git
cd shiro

# Run the automated installer (handles everything!)
chmod +x install.sh
./install.sh
```

The macOS installer automatically:
- ✅ Installs Homebrew (if needed)
- ✅ Detects and fixes Python version compatibility issues
- ✅ Installs pyenv and Python 3.12 if you have Python 3.14+
- ✅ Installs ffmpeg via Homebrew
- ✅ Sets up project-specific Python version
- ✅ Creates virtual environment
- ✅ Installs all dependencies
- ✅ Verifies installation

#### Linux

```bash
# Clone the repository
git clone https://github.com/yourusername/shiro.git
cd shiro

# Run the automated installer (handles everything!)
chmod +x install-linux.sh
./install-linux.sh
```

The Linux installer automatically:
- ✅ Detects your Linux distribution (Ubuntu, Debian, Fedora, Arch, etc.)
- ✅ Installs ffmpeg using your package manager
- ✅ Installs Python development headers
- ✅ Verifies Python version (3.10-3.13 required)
- ✅ Creates virtual environment
- ✅ Installs all dependencies
- ✅ Verifies installation

**Supported distributions:** Ubuntu, Debian, Fedora, RHEL, CentOS, Arch, Manjaro

#### Windows

```cmd
# Clone the repository
git clone https://github.com/yourusername/shiro.git
cd shiro

# Run the automated installer
install.bat
```

The Windows installer automatically:
- ✅ Verifies Python installation (3.10-3.13 required)
- ✅ Checks for ffmpeg (provides install instructions if missing)
- ✅ Creates virtual environment
- ✅ Installs all dependencies
- ✅ Verifies installation

**Prerequisites for Windows:**
- **Python 3.10-3.13** from [python.org](https://www.python.org/downloads/) (make sure to check "Add Python to PATH")
- **ffmpeg** - Install via:
  - [Chocolatey](https://chocolatey.org/): `choco install ffmpeg`
  - [Scoop](https://scoop.sh/): `scoop install ffmpeg`
  - Or download from [ffmpeg.org](https://ffmpeg.org/download.html)

### Basic Usage

**macOS / Linux:**
```bash
# Activate virtual environment
source venv/bin/activate

# Transcribe and summarize a meeting
python shiro.py meeting_recording.mkv

# Transcribe only (no summarization)
python shiro.py meeting_recording.mkv --no-summary

# Force re-processing (ignore cached files)
python shiro.py meeting_recording.mkv --force
```

**Windows:**
```cmd
# Activate virtual environment
venv\Scripts\activate

# Transcribe and summarize a meeting
python shiro.py meeting_recording.mkv

# Transcribe only (no summarization)
python shiro.py meeting_recording.mkv --no-summary

# Force re-processing (ignore cached files)
python shiro.py meeting_recording.mkv --force
```

### Configuration

1. Copy the example environment file:
```bash
cp .env.example .env
```

2. (Optional) Add your Claude API key for summarization:
```bash
# Edit .env and add your key
ANTHROPIC_API_KEY=sk-ant-xxxxx
```

> **Note:** Summarization is optional. Without an API key, Shiro will still transcribe your meetings perfectly—you just won't get the AI-powered summary and action item extraction.

---

## How It Works

### Architecture

```
┌─────────────────┐
│  Meeting Video  │
│   (MKV/MP4)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Audio Extractor │ ──▶ output/meeting_audio.wav
│    (ffmpeg)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Transcriber    │ ──▶ output/meeting_transcript.json
│ (Whisper Local) │ ──▶ output/meeting_transcript.txt
└────────┬────────┘ ──▶ output/meeting_transcript.srt
         │
         ▼
┌─────────────────┐
│  Summarizer     │ ──▶ output/meeting_summary.md
│ (Claude API)    │ ──▶ output/meeting_summary.json
└─────────────────┘
```

### Processing Pipeline

1. **Audio Extraction** (`src/audio_extractor.py`)
   - Converts video to 16kHz mono WAV using ffmpeg
   - Optimized format for speech recognition
   - Smart skip: Won't re-extract if audio file exists

2. **Transcription** (`src/transcriber.py`)
   - Uses OpenAI Whisper (medium model by default)
   - Runs entirely on your local machine
   - Generates word-level timestamps
   - Outputs: JSON (detailed), TXT (clean), SRT (subtitles)
   - Smart skip: Won't re-transcribe if transcript exists

3. **Summarization** (`src/summarizer.py`)
   - Optional Claude API integration
   - Extracts: executive summary, discussion points, decisions, action items
   - Cost: ~$0.15 per hour-long meeting
   - Outputs: Markdown (readable), JSON (structured data)

### Smart Auto-Detection

Shiro intelligently skips completed steps:

```bash
# First run: Full pipeline (~10 minutes)
python shiro.py meeting.mkv
# ▶ Extracting audio...
# ▶ Transcribing audio...
# ▶ Generating summary...

# Second run: Only new summary (~30 seconds)
python shiro.py meeting.mkv
# ⏭️ Skipping audio extraction (file already exists)
# ⏭️ Skipping transcription (file already exists)
# ▶ Generating summary...

# Force complete re-processing
python shiro.py meeting.mkv --force
```

---

## Output Files

After processing `meeting.mkv`, you'll find:

```
output/
├── meeting_audio.wav          # Extracted audio (16kHz mono)
├── meeting_transcript.json    # Full transcript with timestamps
├── meeting_transcript.txt     # Clean text transcript
├── meeting_transcript.srt     # Subtitle file
├── meeting_summary.md         # Human-readable summary
└── meeting_summary.json       # Structured summary data
```


---

## Command Line Options

```bash
python shiro.py <video_file> [options]

Required:
  video_file              Path to video file (MKV, MP4, etc.)

Optional:
  --no-summary           Skip summarization (transcription only)
  --skip-extraction      Skip audio extraction step
  --force                Force re-processing (ignore cached files)
  --whisper-model SIZE   Whisper model size (tiny/base/small/medium/large)
  --language CODE        Language code (en, es, fr, etc.)
  --meeting-context TEXT Additional context for summarization
```

### Examples

```bash
# Transcribe Spanish meeting
python shiro.py meeting.mkv --language es

# Use larger model for better accuracy (slower)
python shiro.py meeting.mkv --whisper-model large

# Transcribe only, no summary
python shiro.py meeting.mkv --no-summary

# Add context for better summarization
python shiro.py meeting.mkv --meeting-context "Weekly sprint planning"
```

---

## Performance & Cost

### Processing Times (M4 Max)

| Task | Duration (1-hour meeting) |
|------|--------------------------|
| Audio Extraction | ~30 seconds |
| Transcription (medium) | ~8-10 minutes |
| Transcription (large) | ~15-20 minutes |
| Summarization | ~10-30 seconds |
| **Total** | **~10-15 minutes** |

### Whisper Model Comparison

| Model | Speed | Accuracy | VRAM |
|-------|-------|----------|------|
| tiny | Very Fast | Good | ~1 GB |
| base | Fast | Good | ~1 GB |
| small | Medium | Better | ~2 GB |
| **medium** | Slower | **Great** (default) | ~5 GB |
| large | Slowest | Best | ~10 GB |

### API Costs (Optional Summarization)

- **Claude 3.5 Sonnet**: ~$0.10-0.20 per hour-long meeting
- **Alternative**: Skip summarization entirely (free) and sumerize using free ChatGPT by dropping the .txt file.

---

## Troubleshooting

### Python Version Issues

**Problem:** `Python 3.14.0 is too new!`

**Solution:** The installer automatically handles this! It will:
1. Install pyenv (if needed)
2. Install Python 3.12
3. Set Shiro to use Python 3.12 automatically

If you still see this error:
```bash
# Manually activate pyenv and retry
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
./install.sh
```

### ffmpeg Not Found

**Problem:** `Audio extraction failed: ffmpeg not found`

**Solution:**
```bash
# macOS
brew install ffmpeg

# Ubuntu/Debian
sudo apt-get install ffmpeg
```

### Out of Memory During Transcription

**Problem:** System runs out of memory with large model

**Solution:** Use a smaller Whisper model
```bash
python shiro.py meeting.mkv --whisper-model small
```

### Claude API Credit Balance Low

**Problem:** `Your credit balance is too low to access the Anthropic API`

**Solution:** Either:
1. Add credits to your Anthropic account at https://console.anthropic.com
2. Skip summarization: `python shiro.py meeting.mkv --no-summary`

### Files Not Being Skipped

**Problem:** Shiro re-processes everything even when files exist

**Solution:** Use auto-detection (default behavior). If you want to force re-processing:
```bash
python shiro.py meeting.mkv --force
```

---

## Security Best Practices

### API Key Management

**Never commit `.env` file to Git!** The `.gitignore` file already excludes it, but double-check:

```bash
# Verify .env is not tracked
git status

# If .env appears, remove it immediately
git rm --cached .env
```

### Secure Your API Key

1. **Use environment variables** (already configured)
2. **Rotate keys regularly** at https://console.anthropic.com
3. **Set usage limits** in Anthropic dashboard
4. **Never share** your `.env` file

### Privacy Considerations

- **Transcription** happens entirely on your machine—no data sent anywhere
- **Summarization** sends transcript text to Claude API (opt-in)
- **Meeting recordings** never leave your machine
- **No telemetry** or usage tracking of any kind

---

## Project Structure

```
shiro/
├── shiro.py                # Main orchestration script
├── install.sh              # Automated installation script
├── requirements.txt        # Python dependencies
├── .env.example           # Environment configuration template
├── .gitignore             # Git ignore rules
├── LICENSE                # MIT License
│
├── src/
│   ├── __init__.py
│   ├── audio_extractor.py # Audio extraction from video (ffmpeg)
│   ├── transcriber.py     # Speech-to-text (Whisper)
│   └── summarizer.py      # AI summarization (Claude)
│
├── output/                # Generated files (git-ignored)
│   ├── *_audio.wav
│   ├── *_transcript.json
│   ├── *_transcript.txt
│   ├── *_transcript.srt
│   ├── *_summary.md
│   └── *_summary.json
│
└── venv/                  # Python virtual environment (git-ignored)
```

---

## Contributing

**Contributions are welcome!** This project is open-source because the best tools are built by communities.

### How to Contribute

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub, then:
   git clone https://github.com/YOUR_USERNAME/shiro.git
   cd shiro
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Write clean, documented code
   - Follow existing code style
   - Test your changes thoroughly

4. **Commit and push**
   ```bash
   git add .
   git commit -m "Add: your feature description"
   git push origin feature/your-feature-name
   ```

5. **Open a Pull Request**
   - Describe what your PR does
   - Reference any related issues
   - Be responsive to feedback

### Areas We Need Help

**High Priority:**
- [ ] Support for more video formats (AVI, MOV, WebM)
- [ ] Multi-language support improvements
- [ ] Speaker diarization (who said what)
- [ ] Web UI for easier use
- [ ] Docker containerization
- [ ] Windows installation support

**Medium Priority:**
- [ ] Custom summarization prompts
- [ ] Export to Notion, Obsidian, etc.
- [ ] Batch processing multiple files
- [ ] Integration with calendar apps
- [ ] Meeting comparison/trends over time

**Documentation:**
- [ ] Video tutorial
- [ ] Use case examples
- [ ] Performance benchmarks on different hardware
- [ ] Translation of README to other languages


---

## Tech Stack

| Component | Technology | Why? |
|-----------|-----------|------|
| **Transcription** | OpenAI Whisper | State-of-the-art accuracy, runs locally |
| **Summarization** | Claude 3.5 Sonnet | Best-in-class understanding, structured output |
| **Audio Extraction** | ffmpeg | Industry standard, handles all formats |
| **Language** | Python 3.12 | Rich ML ecosystem, easy to read/modify |
| **Env Management** | pyenv | Project-specific Python versions |
| **Package Management** | pip + venv | Standard, simple, reliable |

---

## Comparison

### vs. Otter.ai / Fireflies.ai

| Feature | Shiro | Commercial Services |
|---------|-------|-------------------|
| **Cost** | 100% Free | $10-30/month subscription |
| **Privacy** | Local transcription | Data sent to cloud |
| **Customization** | Full source code access | Limited API |
| **Offline Use** | Yes (except summary) | No |
| **Vendor Lock-in** | None | High |

### vs. Plain Whisper

| Feature | Shiro | Just Whisper |
|---------|-------|-------------|
| **Audio Extraction** | Automatic | Manual ffmpeg |
| **Summarization** | AI-powered | None |
| **Output Formats** | 5 formats | 1 format |
| **Action Items** | Auto-extracted | Manual |
| **Smart Skip** | Yes | No |
| **Setup** | One command | Complex |

---

## FAQ

**Q: Does this work on Windows?**
A: Currently macOS/Linux only. Windows support is planned—contributions welcome!

**Q: Can I use it without an API key?**
A: Yes! Transcription works completely offline. You only need an API key for optional summarization.

**Q: Is my data private?**
A: Transcription happens 100% locally. If you use summarization, only the transcript text is sent to Claude API.

**Q: What languages are supported?**
A: Whisper supports 99 languages. Use `--language <code>` to specify (e.g., `--language es` for Spanish).

**Q: Can I use a different summarization API?**
A: Yes! The code is modular. You can easily swap out `src/summarizer.py` for OpenAI, Gemini, or local models.

**Q: Why "Shiro"?**
A: Shiro (白) means "white" or "pure" in Japanese—representing the project's focus on transparency and simplicity.

---

## License

MIT License - see [LICENSE](LICENSE) file for details.

**TL;DR:** You can use, modify, and distribute this software freely, even commercially. Just keep the copyright notice.

---

**Built with ❤️ by a Ir0nByte tired of missing meeting details.**

If Shiro saves you time, consider:
- ⭐ Starring the repo
- 🐛 Reporting bugs
- 💡 Suggesting features
- 🔧 Contributing code
- 📢 Sharing with others

**Let's build better tools, together.**
