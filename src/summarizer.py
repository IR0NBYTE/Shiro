"""
Summarization module using Claude API for detailed meeting analysis.
Designed to extract all key points without missing any details.
"""
from anthropic import Anthropic
from pathlib import Path
from typing import Dict, Optional
import json
import os


class MeetingSummarizer:
    """Summarize meeting transcripts using Claude API with detail preservation."""

    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize the summarizer.

        Args:
            api_key: Anthropic API key (if not provided, reads from ANTHROPIC_API_KEY env var)
        """
        self.api_key = api_key or os.getenv("ANTHROPIC_API_KEY")

        if not self.api_key:
            raise ValueError(
                "Anthropic API key not found. Set ANTHROPIC_API_KEY environment variable "
                "or pass api_key parameter."
            )

        self.client = Anthropic(api_key=self.api_key)
        print("✓ Claude API client initialized")

    def summarize_meeting(self, transcript: str, meeting_context: Optional[str] = None) -> Dict:
        """
        Analyze and summarize meeting transcript with comprehensive detail extraction.

        Args:
            transcript: Full meeting transcript text
            meeting_context: Optional context about the meeting (topic, participants, etc.)

        Returns:
            Dictionary containing structured summary with all key points
        """
        print("\nAnalyzing transcript with Claude...")

        # Build the prompt for detailed analysis
        system_prompt = """You are an expert meeting analyst. Your task is to analyze meeting transcripts
and extract ALL important information without missing any details. You should be thorough and comprehensive.

Your analysis should include:
1. Executive Summary - Brief overview of the meeting
2. Key Discussion Points - All topics discussed with details
3. Decisions Made - Any decisions or conclusions reached
4. Action Items - Tasks, assignments, or next steps mentioned
5. Important Details - Specific numbers, dates, deadlines, names, or technical details
6. Questions Raised - Any open questions or concerns
7. Follow-up Needed - Items that need further discussion

Be meticulous and ensure you capture every important point, even minor details."""

        user_prompt = f"""Please analyze this meeting transcript and provide a comprehensive summary.

{f"Meeting Context: {meeting_context}" if meeting_context else ""}

Transcript:
{transcript}

Provide your analysis in a structured format with clear sections. Ensure you capture ALL details discussed."""

        try:
            # Use Claude 3.5 Sonnet for best analysis quality
            message = self.client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=4000,
                temperature=0,  # Deterministic for consistency
                system=system_prompt,
                messages=[{
                    "role": "user",
                    "content": user_prompt
                }]
            )

            summary_text = message.content[0].text

            # Also extract structured data using a second call
            structured_data = self._extract_structured_data(transcript, summary_text)

            result = {
                "summary": summary_text,
                "structured_data": structured_data,
                "model_used": message.model,
                "tokens_used": {
                    "input": message.usage.input_tokens,
                    "output": message.usage.output_tokens
                }
            }

            print(f"✓ Summary generated successfully")
            print(f"  Tokens used: {message.usage.input_tokens} input, {message.usage.output_tokens} output")

            return result

        except Exception as e:
            raise RuntimeError(f"Failed to generate summary: {str(e)}")

    def _extract_structured_data(self, transcript: str, summary: str) -> Dict:
        """
        Extract structured data from the transcript for easy reference.

        Args:
            transcript: Original transcript
            summary: Generated summary

        Returns:
            Dictionary with structured data (action items, decisions, etc.)
        """
        print("Extracting structured data...")

        extraction_prompt = f"""Based on this meeting summary, extract structured data in JSON format.

Summary:
{summary}

Extract and format as JSON with these fields:
{{
  "action_items": [
    {{"task": "description", "owner": "person if mentioned", "deadline": "if mentioned"}}
  ],
  "decisions": [
    {{"decision": "what was decided", "context": "why/how"}}
  ],
  "key_dates": [
    {{"date": "date mentioned", "event": "what it's for"}}
  ],
  "participants_mentioned": ["list of people mentioned"],
  "technical_details": ["specific technical points, numbers, or specifications"],
  "open_questions": ["any unresolved questions or concerns"]
}}

Only include fields that have actual data. If a field has no data, use an empty array."""

        try:
            message = self.client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=2000,
                temperature=0,
                messages=[{
                    "role": "user",
                    "content": extraction_prompt
                }]
            )

            # Extract JSON from the response
            response_text = message.content[0].text

            # Try to parse JSON from the response
            # Claude might wrap it in markdown code blocks
            if "```json" in response_text:
                json_start = response_text.find("```json") + 7
                json_end = response_text.find("```", json_start)
                json_str = response_text[json_start:json_end].strip()
            elif "```" in response_text:
                json_start = response_text.find("```") + 3
                json_end = response_text.find("```", json_start)
                json_str = response_text[json_start:json_end].strip()
            else:
                json_str = response_text.strip()

            structured_data = json.loads(json_str)
            print("✓ Structured data extracted")

            return structured_data

        except Exception as e:
            print(f"Warning: Could not extract structured data: {str(e)}")
            return {}

    def save_summary(self, summary_result: Dict, output_path: str):
        """
        Save summary to files (markdown and JSON).

        Args:
            summary_result: Result from summarize_meeting()
            output_path: Base output path (without extension)
        """
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        # Save as JSON
        json_path = output_path.with_name(f"{output_path.stem}_summary.json")
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(summary_result, f, indent=2, ensure_ascii=False)
        print(f"✓ Saved JSON summary to {json_path}")

        # Save as Markdown (more readable)
        md_path = output_path.with_name(f"{output_path.stem}_summary.md")
        with open(md_path, "w", encoding="utf-8") as f:
            f.write(f"# Meeting Summary\n\n")
            f.write(summary_result["summary"])
            f.write("\n\n---\n\n## Structured Data\n\n")

            structured = summary_result.get("structured_data", {})

            if structured.get("action_items"):
                f.write("### Action Items\n\n")
                for item in structured["action_items"]:
                    owner = f" ({item.get('owner', 'Unassigned')})" if item.get('owner') else ""
                    deadline = f" - Due: {item.get('deadline')}" if item.get('deadline') else ""
                    f.write(f"- {item['task']}{owner}{deadline}\n")
                f.write("\n")

            if structured.get("decisions"):
                f.write("### Decisions Made\n\n")
                for decision in structured["decisions"]:
                    f.write(f"- **{decision['decision']}**\n")
                    if decision.get('context'):
                        f.write(f"  - {decision['context']}\n")
                f.write("\n")

            if structured.get("key_dates"):
                f.write("### Key Dates\n\n")
                for date_info in structured["key_dates"]:
                    f.write(f"- {date_info['date']}: {date_info['event']}\n")
                f.write("\n")

            if structured.get("open_questions"):
                f.write("### Open Questions\n\n")
                for question in structured["open_questions"]:
                    f.write(f"- {question}\n")
                f.write("\n")

            if structured.get("technical_details"):
                f.write("### Technical Details\n\n")
                for detail in structured["technical_details"]:
                    f.write(f"- {detail}\n")
                f.write("\n")

            # Add metadata
            f.write("\n---\n\n## Analysis Metadata\n\n")
            f.write(f"- Model: {summary_result.get('model_used', 'N/A')}\n")
            tokens = summary_result.get('tokens_used', {})
            f.write(f"- Tokens: {tokens.get('input', 0)} input, {tokens.get('output', 0)} output\n")

        print(f"✓ Saved Markdown summary to {md_path}")
