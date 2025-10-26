"""
Audio extraction module for extracting audio from video files using ffmpeg.
"""
import subprocess
import os
from pathlib import Path


class AudioExtractor:
    """Extract audio from video files using ffmpeg."""

    def __init__(self, output_dir: str = "./output"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def extract_audio(self, video_path: str, output_format: str = "wav") -> str:
        """
        Extract audio from video file.

        Args:
            video_path: Path to the input video file
            output_format: Output audio format (wav, mp3, etc.)

        Returns:
            Path to the extracted audio file
        """
        video_path = Path(video_path)

        if not video_path.exists():
            raise FileNotFoundError(f"Video file not found: {video_path}")

        # Create output filename
        output_filename = f"{video_path.stem}_audio.{output_format}"
        output_path = self.output_dir / output_filename

        print(f"Extracting audio from {video_path.name}...")
        print(f"Output: {output_path}")

        # Use ffmpeg to extract audio
        # -i: input file
        # -vn: disable video
        # -acodec pcm_s16le: use PCM 16-bit little-endian codec for WAV
        # -ar 16000: set sample rate to 16kHz (optimal for speech recognition)
        # -ac 1: convert to mono (sufficient for speech)
        command = [
            "ffmpeg",
            "-i", str(video_path),
            "-vn",  # No video
            "-acodec", "pcm_s16le",
            "-ar", "16000",  # 16kHz sample rate
            "-ac", "1",  # Mono
            "-y",  # Overwrite output file if exists
            str(output_path)
        ]

        try:
            result = subprocess.run(
                command,
                check=True,
                capture_output=True,
                text=True
            )
            print(f"✓ Audio extracted successfully to {output_path}")
            return str(output_path)
        except subprocess.CalledProcessError as e:
            raise RuntimeError(f"Failed to extract audio: {e.stderr}")

    @staticmethod
    def check_ffmpeg_installed() -> bool:
        """Check if ffmpeg is installed and accessible."""
        try:
            subprocess.run(
                ["ffmpeg", "-version"],
                check=True,
                capture_output=True
            )
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            return False
