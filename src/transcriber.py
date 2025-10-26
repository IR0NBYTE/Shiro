"""
Transcription module using OpenAI Whisper for speech-to-text.
Compatible with Python 3.8+ including latest versions.
"""
import whisper
from pathlib import Path
from typing import List, Dict
import json
import warnings

# Suppress FP16 warnings on CPU
warnings.filterwarnings("ignore", message="FP16 is not supported on CPU")


class Transcriber:
    """Transcribe audio files using OpenAI Whisper."""

    def __init__(self, model_size: str = "medium", device: str = "auto"):
        """
        Initialize the transcriber.

        Args:
            model_size: Whisper model size (tiny, base, small, medium, large, large-v2, large-v3)
            device: Device to use (auto, cpu, cuda) - auto will use CPU on Mac
        """
        self.model_size = model_size

        print(f"Loading Whisper model '{model_size}'...")
        print("This may take a moment on first run as the model downloads...")

        # Load the model
        self.model = whisper.load_model(model_size, device=device if device != "auto" else None)

        print(f"✓ Model loaded successfully")

    def transcribe(self, audio_path: str, language: str = "en") -> Dict:
        """
        Transcribe audio file to text.

        Args:
            audio_path: Path to audio file
            language: Language code (en, es, fr, etc.) or None for auto-detection

        Returns:
            Dictionary containing full transcript and segments with timestamps
        """
        audio_path = Path(audio_path)

        if not audio_path.exists():
            raise FileNotFoundError(f"Audio file not found: {audio_path}")

        print(f"\nTranscribing {audio_path.name}...")
        print("This may take several minutes depending on the audio length...")

        # Transcribe with word-level timestamps
        result = self.model.transcribe(
            str(audio_path),
            language=language if language else None,
            word_timestamps=True,
            verbose=False
        )

        detected_language = result.get("language", language or "unknown")
        print(f"Detected language: {detected_language}")

        # Collect all segments
        transcript_segments = []
        full_text = []

        for segment in result["segments"]:
            segment_data = {
                "start": segment["start"],
                "end": segment["end"],
                "text": segment["text"].strip(),
                "words": []
            }

            # Add word-level timestamps if available
            if "words" in segment and segment["words"]:
                for word in segment["words"]:
                    segment_data["words"].append({
                        "word": word.get("word", ""),
                        "start": word.get("start", 0),
                        "end": word.get("end", 0),
                        "probability": word.get("probability", 1.0)
                    })

            transcript_segments.append(segment_data)
            full_text.append(segment["text"].strip())

        # Calculate duration from segments
        duration = transcript_segments[-1]["end"] if transcript_segments else 0

        transcript_result = {
            "language": detected_language,
            "language_probability": 1.0,  # OpenAI Whisper doesn't provide this
            "duration": duration,
            "full_transcript": " ".join(full_text),
            "segments": transcript_segments
        }

        print(f"✓ Transcription complete: {len(transcript_segments)} segments, {duration:.1f} seconds")

        return transcript_result

    def save_transcript(self, transcript: Dict, output_path: str, format: str = "all"):
        """
        Save transcript to file.

        Args:
            transcript: Transcript dictionary from transcribe()
            output_path: Base output path (without extension)
            format: Output format (json, txt, srt, or all)
        """
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        if format in ["json", "all"]:
            json_path = output_path.with_suffix(".json")
            with open(json_path, "w", encoding="utf-8") as f:
                json.dump(transcript, f, indent=2, ensure_ascii=False)
            print(f"✓ Saved JSON transcript to {json_path}")

        if format in ["txt", "all"]:
            txt_path = output_path.with_suffix(".txt")
            with open(txt_path, "w", encoding="utf-8") as f:
                f.write(transcript["full_transcript"])
            print(f"✓ Saved text transcript to {txt_path}")

        if format in ["srt", "all"]:
            srt_path = output_path.with_suffix(".srt")
            self._save_srt(transcript["segments"], srt_path)
            print(f"✓ Saved SRT subtitle file to {srt_path}")

    @staticmethod
    def _save_srt(segments: List[Dict], output_path: Path):
        """Save transcript as SRT subtitle file."""
        with open(output_path, "w", encoding="utf-8") as f:
            for i, segment in enumerate(segments, 1):
                # Convert seconds to SRT timestamp format
                start = Transcriber._format_timestamp(segment["start"])
                end = Transcriber._format_timestamp(segment["end"])

                f.write(f"{i}\n")
                f.write(f"{start} --> {end}\n")
                f.write(f"{segment['text']}\n\n")

    @staticmethod
    def _format_timestamp(seconds: float) -> str:
        """Convert seconds to SRT timestamp format (HH:MM:SS,mmm)."""
        hours = int(seconds // 3600)
        minutes = int((seconds % 3600) // 60)
        secs = int(seconds % 60)
        millis = int((seconds % 1) * 1000)
        return f"{hours:02d}:{minutes:02d}:{secs:02d},{millis:03d}"
