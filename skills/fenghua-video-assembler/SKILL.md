---
name: fenghua-video-assembler
description: >
  Assemble final explainer video from storyboard images, TTS audio, and subtitles using Remotion.
  Renders clean 16:9 master video (no subtitles). Subtitles are burned onto the 3:4 version
  via ffmpeg ASS filter (primary) or Python+Pillow per-frame compositing (fallback for macOS
  where Homebrew ffmpeg lacks libass). Positioned below the video area and above the logo.
  Use after fenghua-quality-reviewer and fenghua-voice-synthesizer.
---

# Fenghua Video Assembler

The final assembly stage: combines approved storyboard images, narration audio, and subtitles into a polished MP4 video using Remotion (React-based video framework) + ffmpeg post-processing.

## Pipeline Overview

```
Remotion: clean 16:9 (no subtitles)
    → ffmpeg: 1.1x speed
        → ffmpeg: overlay onto 3:4 background
            → SRT pre-split into single-line segments (≤25 chars)
                → burn subtitles into gap below video:
                    Primary: ffmpeg ASS filter (if ffmpeg has libass)
                    Fallback: Python + Pillow per-frame compositing (macOS)
```

**Key design decisions:**
1. Subtitles are NOT rendered in Remotion — burned onto 3:4 version only
2. Positioned at SUB_Y_CENTER=880, in the gap between video bottom (y=823) and logo (~y=1060)
3. **Single-line display only** — SRT is pre-split into short segments (≤25 chars) before burning
4. On macOS, Homebrew ffmpeg typically lacks libass, so Python+Pillow is the practical default

## ⚠️ Critical Pitfalls (Lessons Learned)

### Pitfall 1: scenes.ts timestamps must use ORIGINAL SRT times

**Wrong:** Dividing SRT timestamps by 1.1 in scenes.ts.
**Right:** Use original SRT timestamps directly.

**Why:** Remotion plays the ORIGINAL-speed audio (`narration.mp3`). If you pre-divide timestamps by 1.1, the scene images will advance faster than the audio → **desync**. The 1.1x speed-up is applied by ffmpeg AFTER Remotion render, which uniformly accelerates both video and audio together.

```
❌ scenes.ts: startSec: 10.404 / 1.1 = 9.46   ← WRONG, causes desync
✅ scenes.ts: startSec: 10.404                  ← RIGHT, matches audio
```

Also set `TOTAL_DURATION_SECONDS` to `Math.ceil(audio_duration)`, NOT `audio_duration / 1.1`.

### Pitfall 2: burn-subtitles.py must force FPS on the reader

After 1.1x speed-up (`setpts=PTS/1.1`), ffmpeg may change the video's frame rate (e.g., 30fps → 25fps). The `burn-subtitles.py` reader must force a consistent FPS with `-r`:

```python
# ❌ WRONG — reads at video's native fps (may be 25fps after 1.1x)
reader = Popen(["ffmpeg", "-i", INPUT, "-f", "rawvideo", ...])

# ✅ RIGHT — forces 30fps output regardless of source fps
reader = Popen(["ffmpeg", "-i", INPUT, "-r", "30", "-f", "rawvideo", ...])
```

Without `-r 30`, the reader produces fewer frames than expected (e.g., 5773 instead of 6927), but the writer still writes at 30fps → **video truncated** (e.g., 192s instead of 231s).

### Pitfall 3: SRT split timing ÷1.1 IS correct (don't confuse with Pitfall 1)

The `split-srt.py` script that generates subtitles for the 3:4 video SHOULD divide timestamps by 1.1, because subtitles are burned onto the ALREADY-sped-up video. This is the opposite of scenes.ts.

```
scenes.ts  → timestamps for Remotion → uses ORIGINAL times (audio is original speed)
split-srt  → timestamps for subtitle burn → uses ÷1.1 times (video is 1.1x speed)
```

### Pitfall 4: Remotion Chrome browser flag

`REMOTION_CHROME_EXECUTABLE` env var does NOT work reliably. Always use the CLI flag:

```bash
# ❌ May not work
export REMOTION_CHROME_EXECUTABLE="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# ✅ Always works
npx remotion render ... --browser-executable="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
```

### Pitfall 5: ffmpeg 3:4 background must use `-loop 1` and scale

When overlaying onto a background image:
- Background image may not be exactly 1080x1440 → always add `scale=1080:1440`
- Static image input needs `-loop 1` flag, otherwise output is near-empty (80KB)

```bash
ffmpeg -y -loop 1 -i bg.jpg -i video.mp4 \
  -filter_complex "[0:v]scale=1080:1440[bg];[1:v]scale=1080:-2[vid];[bg][vid]overlay=0:216:shortest=1[out]" \
  ...
```

### Pitfall 6: Avatar image size for API calls

Avatar reference images >1MB cause API timeouts. Always resize before batch image generation:

```bash
magick convert avatar.png -resize 500x500 avatar-small.png  # Target ~300KB
```

## Input

- `storyboards/final/*.png` — QC-approved images
- `storyboard.json` — timing, transitions, overlay text
- `audio/narration.mp3` — TTS audio
- `subtitles/narration.srt` — subtitle file (from TTS)
- Style reference from `fenghua-aesthetics-library`

## Output

- `outputs/video-16x9.mp4` — 16:9 master video (1920x1080, clean, no subtitles)
- `outputs/video-16x9-1.1x.mp4` — 1.1x speed version
- `outputs/video-3x4.mp4` — 3:4 vertical packaging (1080x1440) with subtitles burned below video

## Architecture: Remotion Project

The assembler creates a Remotion project that composes the video programmatically.

### Project Structure

```
remotion-project/
├── public/
│   ├── images/          # Storyboard images (copied from storyboards/final/)
│   ├── audio/           # Narration audio
│   └── subtitles/       # SRT file
├── src/
│   ├── Root.tsx          # Composition definitions
│   ├── ExplainerVideo.tsx # Main video component (Ken Burns + crossfade + subtitles)
│   ├── index.ts          # Entry point with registerRoot()
│   └── data/
│       ├── scenes.ts     # Scene segments with timing (from TTS SRT)
│       └── subtitles.ts  # Subtitle entries parsed from TTS SRT
├── package.json
└── remotion.config.ts
```

### Video Composition Layers (Remotion — clean 16:9, bottom to top)

```
Layer 1: Background image (storyboard frame, with built-in text from AI generation)
Layer 2: Ken Burns zoom (slow scale 1.0→1.06 per scene)
Layer 3: Crossfade transition (last 0.5s of each scene)
Layer 4: Audio track (narration.mp3)
```

**No subtitles in Remotion.** Subtitles are burned later via ffmpeg ASS filter onto the 3:4 version.

**Note on overlay text:** When storyboard images already contain text labels, titles,
and key information (e.g., avatar-style frames with built-in label cards), do NOT add
a separate overlay text layer. This avoids visual clutter and redundancy.

## Remotion Implementation Guide

### Key Remotion Patterns (reference `remotion` skill rules)

**Composition setup:**
```tsx
// Root.tsx
<Composition
  id="FenghuaExplainerVideo"
  component={ExplainerVideo}
  durationInFrames={totalFrames}  // calculated from audio duration
  fps={30}
  width={1920}
  height={1080}
  defaultProps={{ storyboard, audioSrc, subtitleSrc }}
/>
```

**Scene transitions (using @remotion/transitions):**
```tsx
import { TransitionSeries, linearTiming } from '@remotion/transitions';
import { fade } from '@remotion/transitions/fade';

<TransitionSeries>
  {frames.map((frame, i) => (
    <>
      <TransitionSeries.Sequence durationInFrames={frame.durationFrames}>
        <SceneFrame frame={frame} />
      </TransitionSeries.Sequence>
      {i < frames.length - 1 && (
        <TransitionSeries.Transition
          presentation={fade()}
          timing={linearTiming({ durationInFrames: 15 })}
        />
      )}
    </>
  ))}
</TransitionSeries>
```

**Images (MUST use Remotion Img):**
```tsx
import { Img, staticFile } from 'remotion';
<Img src={staticFile(`images/${frame.frame_id}.png`)} />
```

**Audio:**
```tsx
import { Audio } from '@remotion/media';
<Audio src={staticFile('audio/narration.mp3')} />
```

**Animations (MUST use useCurrentFrame, NO CSS animations):**
```tsx
const frame = useCurrentFrame();
const opacity = interpolate(frame, [0, 15], [0, 1], { extrapolateRight: 'clamp' });
```

## Workflow

### Step 1: Initialize Remotion project

```bash
npx create-video@latest remotion-project --template blank
cd remotion-project
npm install @remotion/media @remotion/transitions
```

### Step 2: Copy assets

```bash
cp storyboards/final/*.png remotion-project/public/images/
cp audio/narration.mp3 remotion-project/public/audio/
cp subtitles/narration.srt remotion-project/public/subtitles/
```

### Step 3: Generate Remotion source code

Create the React components based on storyboard.json:
- Parse storyboard.json to determine frame count, durations, transitions
- Calculate total duration from audio length (frames = duration_seconds * fps)
- Generate SceneFrame components for each storyboard frame
- Wire up audio, subtitles, and transitions

**⚠️ scenes.ts timing — use ORIGINAL SRT timestamps (see Pitfall 1):**
```typescript
// TOTAL_DURATION_SECONDS = Math.ceil(audio_duration_seconds)
// NOT audio_duration / 1.1 !!
export const TOTAL_DURATION_SECONDS = 254; // e.g., ceil(253.525)

// Scene timestamps come directly from SRT, NOT divided by 1.1
export const scenes: Scene[] = [
  { id: "scene-01", image: "scene-01.png", startSec: 0, endSec: 10.268 },
  // ... use original SRT end times
];
```

### Step 4: Render clean 16:9 master (no subtitles)

```bash
npx remotion render src/index.ts FenghuaExplainerVideo \
  --output="../outputs/video-16x9.mp4" \
  --browser-executable="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
```

**Important:**
- Use `--browser-executable` flag (see Pitfall 4 — env var doesn't work reliably)
- Rendering 7000+ frames typically takes 8-15 minutes on Apple Silicon
- The Remotion video must NOT include subtitles — burned later via ffmpeg
- **Verify duration matches audio:** `ffprobe -show_entries format=duration output.mp4` should ≈ `TOTAL_DURATION_SECONDS`

### Step 5: Speed up to 1.1x

```bash
ffmpeg -y -i outputs/video-16x9.mp4 \
  -filter_complex "[0:v]setpts=PTS/1.1[v];[0:a]atempo=1.1[a]" \
  -map "[v]" -map "[a]" \
  -c:v libx264 -preset medium -crf 18 \
  -c:a aac -b:a 192k \
  outputs/video-16x9-1.1x.mp4
```

### Step 6: Package 3:4 vertical with branded background (no subtitles yet)

```bash
# ⚠️ Background MUST use -loop 1, and MUST be scaled to exact 1080x1440 (see Pitfall 5)
ffmpeg -y \
  -loop 1 -i assets/backgrounds/bg-3x4.jpg \
  -i outputs/video-16x9-1.1x.mp4 \
  -filter_complex "\
    [0:v]scale=1080:1440[bg]; \
    [1:v]scale=1080:-2[vid]; \
    [bg][vid]overlay=0:216:shortest=1[out]" \
  -map "[out]" -map "1:a" \
  -c:v libx264 -preset medium -crf 18 \
  -c:a copy \
  -shortest \
  outputs/video-3x4-nosub.mp4
```

**Layout specs (1080x1440):**
- 16:9 video scaled to 1080x607, placed at y=216 (upper area)
- Video bottom edge at y=823
- Bottom area (~617px) shows branded background with logo
- **Verify:** `ffprobe` duration should match the 1.1x video (~231s)

### Step 7: Pre-split SRT into single-line segments

**Critical step:** Before burning subtitles, split long SRT entries into short natural-sentence segments for single-line display. This prevents multi-line subtitle clutter.

Create a Python script (`split-srt-v2.py`) that:
- Reads the 1.1x-adjusted SRT (`subtitles/narration-1.1x.srt`)
- Splits at sentence ends (。！？) first, then clause separators (，、；) if still too long
- Target: ≤25 characters per segment
- Distributes time proportionally by character count
- Each segment = one displayed subtitle line (NO multi-line wrapping)
- Outputs: `subtitles/narration-1.1x-split.srt`

**Timing for 1.1x SRT:** Adjust original SRT timestamps by dividing by 1.1:
```bash
# Generate 1.1x-adjusted SRT from original
python3 -c "
import re
# Read original SRT, divide all timestamps by 1.1, write new SRT
"
```

### Step 8: Burn subtitles into 3:4 video

**Two methods available — try Primary first, fall back to Fallback:**

#### Primary: ffmpeg ASS filter (requires libass)

Generate ASS file from pre-split SRT, then burn:

```bash
ffmpeg -y \
  -i outputs/video-3x4-nosub.mp4 \
  -vf "ass=subtitles/narration-3x4.ass" \
  -c:v libx264 -preset medium -crf 18 \
  -c:a copy \
  outputs/video-3x4.mp4
```

**Check if available:** `ffmpeg -filters 2>&1 | grep ass` — if no output, ffmpeg lacks libass → use fallback.

#### Fallback: Python + Pillow per-frame compositing (macOS default)

When ffmpeg lacks libass (common on macOS Homebrew), use a Python script that:
1. Reads each frame from the 3:4 video via ffmpeg rawvideo pipe
2. Looks up current subtitle text from the pre-split SRT
3. Composites white text with black outline using Pillow
4. Writes frame back via ffmpeg rawvideo pipe

**Key parameters for the burn script (`burn-subtitles.py`):**

```python
WIDTH, HEIGHT = 1080, 1440
FPS = 30
FONT_SIZE = 42
SUB_Y_CENTER = 880  # between video bottom (y=823) and logo (y=1060)
# Font: STHeiti Medium (macOS) / PingFang SC / WenQuanYi Zen Hei (Linux)
# White text (255,255,255) with black outline (2px, opacity 220)
# Single-line display only — text already pre-split from Step 7
```

**ffmpeg pipe setup:**
```python
# Reader: decode video to raw RGB frames
# ⚠️ MUST use -r FPS to force consistent frame rate (see Pitfall 2)
# Without -r, the 1.1x video may have different fps (e.g. 25fps) → truncation
reader = subprocess.Popen(
    ["ffmpeg", "-i", INPUT, "-r", str(FPS), "-f", "rawvideo", "-pix_fmt", "rgb24", "-v", "quiet", "-"],
    stdout=subprocess.PIPE)

# Writer: encode raw frames back to H.264, copy audio from input
writer = subprocess.Popen(
    ["ffmpeg", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24",
     "-s", f"{WIDTH}x{HEIGHT}", "-r", str(FPS), "-i", "-",
     "-i", INPUT, "-map", "0:v", "-map", "1:a",
     "-c:v", "libx264", "-preset", "medium", "-crf", "18",
     "-c:a", "copy", "-shortest", OUTPUT],
    stdin=subprocess.PIPE)
```

**Performance:** ~2-3 minutes for a 2-minute video at 30fps on Apple Silicon. Caches subtitle overlay and only re-renders when text changes.

**Verify:** Extract a frame at ~10s and visually confirm subtitles appear as single lines in the gap between the video bottom (y=823) and the Fenghua.AI logo (~y=1060).

### ffmpeg Installation

On macOS (this machine), ffmpeg is installed via Homebrew:

```bash
# Already installed at /opt/homebrew/bin/ffmpeg
FFMPEG=ffmpeg
```

On Linux, download a static binary if needed:

```bash
curl -sL https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz \
  -o /tmp/ffmpeg.tar.xz
cd /tmp && tar xf ffmpeg.tar.xz
chmod +x /tmp/ffmpeg-*-amd64-static/ffmpeg
FFMPEG=/tmp/ffmpeg-*-amd64-static/ffmpeg
```

## Text Overlay Specs

### Headline overlay (CONDITIONAL — only when images lack built-in text):
- **Skip overlay text** when storyboard images already contain text labels, titles,
  and key information (e.g., avatar-style frames with built-in label cards)
- Only add overlay text for purely photographic/abstract images with no embedded text
- If used: Font PingFang SC / Noto Sans SC (bold), 48-64px, fade in/out animation

### Subtitles (burned onto 3:4 only):
- **Method:** ffmpeg ASS filter (primary) or Python+Pillow (fallback for macOS)
- **Font:** STHeiti Medium (macOS primary) / PingFang SC / WenQuanYi Zen Hei (Linux)
- **Size:** 42 (Pillow) or 28 (ASS PlayRes 1080x1440)
- **Position:** SUB_Y_CENTER=880, between video bottom (y=823) and logo (~y=1060)
- **Color:** White text with black outline (2px), semi-transparent shadow
- **Display:** Single-line only — SRT pre-split into segments ≤25 chars
- **Splitting rules:** Sentence ends (。！？) first, then clause separators (，、；) if too long
- **Timing:** SRT times ÷ 1.1 speed factor, distributed proportionally by char count

## Dependencies

| Package | Purpose |
|---------|---------|
| remotion | Core video framework |
| @remotion/media | Audio/video components |
| @remotion/transitions | Scene transitions (fade, slide, wipe) |
| @remotion/cli | Rendering CLI |

**External tools:**
- Node.js (for Remotion)
- Chromium-based browser (for rendering, auto-installed by `npx remotion browser ensure`)
- ffmpeg (for 1.1x speed + 3:4 packaging + subtitle burn if libass available)
- ImageMagick (for image border trimming: `convert -fuzz 15% -trim`)
- Python 3 + Pillow (for subtitle burn fallback when ffmpeg lacks libass; `pip install Pillow`)

## Integration

- **Depends on**: fenghua-quality-reviewer (approved images), fenghua-voice-synthesizer (audio + subtitles), fenghua-storyboard-designer (timing + layout), remotion skill (best practices)
- **Reuses**: fenghua-explainer-video-portable scripts (render + package)
- **Feeds into**: fenghua-video-master (final delivery)
