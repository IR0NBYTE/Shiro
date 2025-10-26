#!/usr/bin/env python3
"""
Shiro - Meeting Transcription and Summarization Tool

Main script to orchestrate the complete pipeline:
1. Extract audio from video
2. Transcribe using Whisper
3. Summarize using Claude API
"""
import argparse
import sys
from pathlib import Path
from dotenv import load_dotenv
import os
import time

from src.audio_extractor import AudioExtractor
from src.transcriber import Transcriber
from src.summarizer import MeetingSummarizer


def print_banner():
    """Print the application banner."""
    print("=" * 70)
    print("  SHIRO - Meeting Transcription & Summarization")
    print("=" * 70)
    print()


def check_requirements():
    """Check if all requirements are met."""
    issues = []

    # Check ffmpeg
    if not AudioExtractor.check_ffmpeg_installed():
        issues.append("ffmpeg is not installed. See README for installation instructions")

    # Check API key
    if not os.getenv("ANTHROPIC_API_KEY"):
        issues.append("ANTHROPIC_API_KEY not set in environment or .env file")

    return issues


def main():
    """Main execution function."""
    parser = argparse.ArgumentParser(
        description="Transcribe and summarize meeting videos (with smart auto-detection)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s meeting.mkv                      # Auto-skips completed steps
  %(prog)s meeting.mkv --force              # Force re-process everything
  %(prog)s meeting.mkv --model large-v3     # Use larger model
  %(prog)s meeting.mkv --context "Sprint planning for Q1"

Note: Shiro automatically detects existing output files and skips completed steps.
Use --force to override and re-process everything.
        """
    )

    parser.add_argument(
        "video_path",
        help="Path to the meeting video file (mkv, mp4, etc.)"
    )

    parser.add_argument(
        "--model",
        default=os.getenv("WHISPER_MODEL", "medium"),
        choices=["tiny", "base", "small", "medium", "large-v2", "large-v3"],
        help="Whisper model size (default: medium). Larger = more accurate but slower"
    )

    parser.add_argument(
        "--language",
        default="en",
        help="Language code (en, es, fr, etc.) or 'auto' for detection (default: en)"
    )

    parser.add_argument(
        "--output",
        help="Output directory or base filename (default: ./output/<video_name>)"
    )

    parser.add_argument(
        "--context",
        help="Optional context about the meeting for better summarization"
    )

    parser.add_argument(
        "--skip-extraction",
        action="store_true",
        help="Skip audio extraction (use if you already have the audio file)"
    )

    parser.add_argument(
        "--skip-transcription",
        action="store_true",
        help="Skip transcription (use if you already have the transcript)"
    )

    parser.add_argument(
        "--skip-summary",
        action="store_true",
        help="Skip summarization (only transcribe)"
    )

    parser.add_argument(
        "--force",
        action="store_true",
        help="Force re-processing even if output files already exist"
    )

    args = parser.parse_args()

    # Load environment variables
    load_dotenv()

    print_banner()

    # Check requirements
    issues = check_requirements()
    if issues and not (args.skip_extraction and args.skip_summary):
        print("❌ Missing requirements:")
        for issue in issues:
            print(f"   - {issue}")
        print()
        return 1

    # Setup paths
    video_path = Path(args.video_path)
    if not video_path.exists() and not args.skip_extraction:
        print(f"❌ Error: Video file not found: {video_path}")
        return 1

    # Determine output path
    if args.output:
        output_base = Path(args.output)
    else:
        output_dir = Path(os.getenv("OUTPUT_DIR", "./output"))
        output_base = output_dir / video_path.stem

    output_base.parent.mkdir(parents=True, exist_ok=True)

    print(f"📁 Video: {video_path}")
    print(f"📁 Output: {output_base.parent}")
    print(f"🎯 Whisper Model: {args.model}")
    print()

    start_time = time.time()

    try:
        # Step 1: Extract Audio
        audio_path = str(output_base) + "_audio.wav"

        if args.skip_extraction:
            print("⏭️  Skipping audio extraction (--skip-extraction flag)")
            if not Path(audio_path).exists():
                print(f"❌ Error: Audio file not found: {audio_path}")
                return 1
        elif not args.force and Path(audio_path).exists():
            print("⏭️  Skipping audio extraction (file already exists)")
            print(f"   Found: {audio_path}")
            print(f"   Use --force to re-extract")
            print()
        else:
            print("🎵 Step 1: Extracting Audio")
            print("-" * 70)
            extractor = AudioExtractor(output_dir=output_base.parent)
            audio_path = extractor.extract_audio(str(video_path))
            print()

        # Step 2: Transcribe
        transcript_path = str(output_base) + "_transcript.json"

        if args.skip_transcription:
            print("⏭️  Skipping transcription (--skip-transcription flag)")
            if not Path(transcript_path).exists():
                print(f"❌ Error: Transcript file not found: {transcript_path}")
                return 1
            import json
            with open(transcript_path, 'r') as f:
                transcript_data = json.load(f)
        elif not args.force and Path(transcript_path).exists():
            print("⏭️  Skipping transcription (file already exists)")
            print(f"   Found: {transcript_path}")
            print(f"   Use --force to re-transcribe")
            print()
            import json
            with open(transcript_path, 'r') as f:
                transcript_data = json.load(f)
        else:
            print("🎙️  Step 2: Transcribing Audio")
            print("-" * 70)
            transcriber = Transcriber(model_size=args.model)

            language = None if args.language == "auto" else args.language
            transcript_data = transcriber.transcribe(audio_path, language=language)

            # Save transcript
            transcript_output = str(output_base) + "_transcript"
            transcriber.save_transcript(transcript_data, transcript_output, format="all")
            print()

        # Step 3: Summarize
        if args.skip_summary:
            print("⏭️  Skipping summarization")
        else:
            print("🤖 Step 3: Analyzing with Claude")
            print("-" * 70)
            summarizer = MeetingSummarizer()

            summary_result = summarizer.summarize_meeting(
                transcript=transcript_data["full_transcript"],
                meeting_context=args.context
            )

            # Save summary
            summarizer.save_summary(summary_result, str(output_base))
            print()

        # Print completion message
        elapsed_time = time.time() - start_time
        print("=" * 70)
        print("✨ Processing Complete!")
        print("-" * 70)
        print(f"⏱️  Total time: {elapsed_time:.1f} seconds ({elapsed_time/60:.1f} minutes)")
        print()
        print("📄 Generated files:")

        # List all generated files
        for file in sorted(output_base.parent.glob(f"{output_base.stem}*")):
            size = file.stat().st_size
            if size > 1024 * 1024:
                size_str = f"{size / (1024*1024):.1f} MB"
            elif size > 1024:
                size_str = f"{size / 1024:.1f} KB"
            else:
                size_str = f"{size} bytes"
            print(f"   - {file.name} ({size_str})")

        print()
        print("📖 View the summary: " + str(output_base) + "_summary.md")
        print("=" * 70)

        return 0

    except KeyboardInterrupt:
        print("\n\n⚠️  Process interrupted by user")
        return 130
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
