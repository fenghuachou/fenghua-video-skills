---
name: fenghua-voice-synthesizer
description: >
  Generate TTS narration audio from video scripts using Listenhub.
  Supports voice clones for personalized narration.
  Produces a complete audio file and subtitle/SRT file for video assembly.
  Use after fenghua-scriptwriter, feeds into fenghua-video-assembler.
---

# Fenghua Voice Synthesizer

Converts the video script narration into spoken audio using Listenhub TTS (FlowSpeech).
Supports both standard speakers and user voice clones for personalized narration.

## Input

- `script.json` or `script.txt` — narration text from fenghua-scriptwriter

## Output

- `audio/narration.mp3` — complete narration audio file
- `subtitles/narration.srt` — subtitle file with precise word-level timing from TTS engine

## Workflow

### Step 1: Prepare narration text

Extract the full narration from `script.json` by concatenating all `sections[].narration` fields in order:

```
hook narration + pain_point narration + arguments narration + twist narration + closing narration
```

Or use `script.txt` directly if available.

**Important:** The text must be under 10,000 characters (Listenhub limit). For a 1-3 min video script (~250-750 Chinese chars), this is well within limits.

### Step 2: Select speaker

Get available speakers including voice clones:

```bash
## Option A: Use the marswaveai/skills tts skill (recommended)
# Invoke the tts skill which handles API calls internally.
# The tts skill is at: ~/.claude/skills/.agents/skills/tts/
# API reference docs at: ~/.claude/skills/.agents/skills/shared/

## Option B: Direct API call to get speakers
curl -s "https://api.marswave.ai/openapi/v1/tts/speakers?language=zh" \
  -H "Authorization: Bearer $LISTENHUB_API_KEY"
```

The response includes both standard speakers and user voice clones:

```json
{
  "code": 0,
  "data": {
    "items": [
      { "name": "Yuanye", "speakerId": "cozy-man-english", "gender": "male", "language": "zh" },
      { "name": "MyClone", "speakerId": "voice-clone-xxxxxxxxxxxxxxxxxxxxxxxx", "gender": "male", "language": "zh" }
    ]
  }
}
```

**Speaker selection priority:**
1. **User voice clone** — if the user has cloned voices (speakerId starts with `voice-clone-`), prefer these for personalized narration
2. **Standard speaker** — choose based on video tone:
   - Informative/analytical: calm, authoritative voice
   - Provocative/inspiring: energetic, dynamic voice

**Always ask the user** which voice they prefer if multiple options are available. Present voice clones prominently as they provide the most personalized result.

### Step 3: Generate TTS audio

Use Listenhub `create-tts.sh` in **direct mode** (no content alteration):

```bash
# Use the marswaveai tts skill or call API directly:
curl -s -X POST "https://api.marswave.ai/openapi/v1/tts" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $LISTENHUB_API_KEY" \
  -d '{
    "type": "text",
    "content": "Full narration text here",
    "language": "zh",
    "mode": "direct",
    "speakers": ["<selected-speaker-id>"]
  }'
```

This returns an episode ID in the response:
```json
{"code": 0, "data": {"episodeId": "69b6c8c416a758dc65bc84f7"}}
```

### Step 4: Wait for completion

```bash
# Poll until completed (check every 10s, timeout 300s)
curl -s "https://api.marswave.ai/openapi/v1/tts/status?episodeId=<episode-id>" \
  -H "Authorization: Bearer $LISTENHUB_API_KEY"
```

Note: Status will transition from `processing` to `completed`. Poll every 10s until done.

### Step 5: Download audio and SRT

Once completed, the check-status response includes both audio and subtitle URLs. **Always download both.**

```bash
# Download audio
curl -sL "<audioUrl>" -o audio/narration.mp3

# Download SRT subtitles (CRITICAL for audio-video sync)
curl -sL "<subtitlesUrl>" -o subtitles/narration.srt
```

**Key fields from the response:**
- `audioUrl` — direct MP3 download link
- `audioStreamUrl` — HLS streaming link
- `subtitlesUrl` — SRT file with precise timing from the TTS engine

### Step 6: Use TTS-generated SRT for video sync

**Critical:** Always use the SRT file returned by the TTS engine (`subtitlesUrl`) as the
authoritative timing source for video assembly. This SRT contains precise word-level
timestamps that match the actual audio, ensuring perfect audio-video sync.

**Do NOT** estimate subtitle timing from script section durations. The TTS engine may
speak faster or slower than estimated, and estimated timings will cause noticeable
audio-video desync.

The TTS-generated SRT should be used to:
1. Update `subtitles.ts` in the Remotion project with exact timestamps
2. Re-calculate scene segment boundaries in `scenes.ts` to align with actual narration timing
3. Compute accurate `TOTAL_DURATION_SECONDS` and `TOTAL_FRAMES` from the SRT end time

**Example SRT-to-scene mapping:**
```
SRT entries 1-2 (0s - 11.4s)    → scene-01 (hook)
SRT entries 3-4 (11.5s - 27.3s) → scene-04 (pain point)
SRT entries 5-6 (27.5s - 49.7s) → scene-07 (history)
...
```

## SRT Format Reference

TTS-generated SRT uses millisecond precision:

```srt
1
00:00:00,000 --> 00:00:03,313
你用AI省下的时间，最后都去哪了？

2
00:00:03,456 --> 00:00:11,413
写代码快了，回邮件快了，做PPT也快了。但你有没有发现——你比以前更忙了。
```

Note: The TTS engine may merge adjacent short sentences into a single SRT entry.
The number of SRT entries may differ from the number of script lines — this is normal.

## Error Handling

1. If TTS generation fails, check:
   - `LISTENHUB_API_KEY` is set (`source ~/.zshrc 2>/dev/null; echo $LISTENHUB_API_KEY`)
   - Text is under 10,000 characters
   - Speaker ID is valid (call `get-speakers.sh` to verify)
   - Voice clone may have expired — check with user
2. If audio quality is poor:
   - Try a different speaker or voice clone
   - Ensure punctuation is correct in the script (affects pacing)
   - Consider adding pause markers: "..." for natural pauses
3. If check-status returns exit code 2 (timeout):
   - Wait briefly and retry — generation may still be in progress

## Configuration

| Parameter | Default | Notes |
|-----------|---------|-------|
| Language | zh | Auto-detected from script |
| Mode | direct | Preserves script text exactly; use `smart` for grammar/punctuation fixes |
| Timeout | 300s | Max wait for TTS completion |
| Speaker | User's voice clone | Falls back to first speaker matching language if no clone available |

## Integration

- **Depends on**: fenghua-scriptwriter (script text), marswaveai/skills tts (`~/.claude/skills/.agents/skills/tts/`)
- **API base**: `https://api.marswave.ai/openapi/v1` (requires `LISTENHUB_API_KEY`)
- **API reference docs**: `~/.claude/skills/.agents/skills/shared/api-tts.md`, `api-speakers.md`
- **Feeds into**: fenghua-video-assembler (audio + SRT subtitles + scene timing)
- **Parallel with**: fenghua-image-producer (can run simultaneously)
