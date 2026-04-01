---
name: fenghua-video-master
description: >
  End-to-end explainer video orchestrator. Give it an article, link, or viewpoint and it produces
  a complete short video with narration, images, subtitles, plus social copy and cover image.
  Semi-automatic with 4 human checkpoints. Coordinates all fenghua sub-skills.
---

# Fenghua Video Master

The master orchestrator that turns raw input into a polished explainer video. One input, full delivery.

## Quick Start

```
Create an explainer video from this article: https://example.com/article
```

Or:

```
Create an explainer video about this viewpoint: "AI 时代最重要的能力不是使用 AI，而是管理 AI"
```

## What You Get

| Deliverable | File | Description |
|------------|------|-------------|
| Video (16:9) | `outputs/video-16x9.mp4` | Main explainer video, 1-3 minutes |
| Video (16:9, 1.1x) | `outputs/video-16x9-1.1x.mp4` | Speed-optimized for short video platforms |
| Video (3:4) | `outputs/video-3x4.mp4` | Vertical version with subtitles below video |
| Cover image | `outputs/cover.png` | Video thumbnail/cover |
| Social copy | `outputs/social-copy.txt` | Ready-to-post caption with hashtags |
| Project archive | `project/` | All intermediate files for future editing |

## Pipeline Overview

```
INPUT (article / URL / viewpoint)
  |
  v
[1] fenghua-content-analyzer ──── Analyze & extract
  |
  v
>>> CHECKPOINT 1: Confirm angle & approach <<<
  |
  v
[2] fenghua-scriptwriter ──────── Write narration script
  |
  v
>>> CHECKPOINT 2: Confirm script & titles <<<
  |
  v
[3] fenghua-voice-synthesizer ── Generate TTS audio + SRT
  |
  v
>>> CHECKPOINT 3: Confirm 口播稿 (listen to TTS audio) <<<
  |
  +──────────────┬──────────────+
  |              |              |
  v              v              v
[4] storyboard  Cover image   (audio ready)
  designer       generation
  |
  v
[5] image
  producer
  |
  v
[6] quality
  reviewer
  |
  +──────────────+
  |
  v
>>> CHECKPOINT 4: Confirm before rendering <<<
  |
  v
[6] fenghua-video-assembler ──── Render final video
  |
  v
DELIVERY: video + cover + social copy
```

## Four Checkpoints

### Checkpoint 1: After Content Analysis

**What to review:**
- Selected angle from `suggested_angles`
- Target audience identification
- Emotional tone choice
- Style selection (tech-blue / minimalist-white / dark-gold)

**User action:** Approve or adjust the angle/style.

### Checkpoint 2: After Script Writing

**What to review:**
- 3 candidate video titles (select one)
- Full narration script (文稿)
- Duration estimate
- Visual hints per section

**User action:** Approve script or request revisions.

### Checkpoint 3: After TTS Generation (口播稿确认)

**What to review:**
- Listen to the generated TTS audio (narration.mp3)
- Check pronunciation accuracy (names, technical terms, numbers)
- Verify pacing and emotion match the intended tone
- Review SRT subtitle text against script (TTS may adjust wording)

**User action:** Approve audio or request re-generation with adjustments. This is the last chance to fix narration issues before visual production begins.

### Checkpoint 4: Before Video Rendering

**What to review:**
- Storyboard frame count and layout
- Quality report summary (X/Y frames passed)
- Audio confirmed at Checkpoint 3
- Estimated render time

**User action:** Approve to proceed with rendering.

## Detailed Workflow

### Phase 1: Analysis (automatic)

```
1. Detect input type (URL / text / file)
2. Invoke fenghua-content-analyzer
3. Read fenghua-aesthetics-library/scripts/list-styles.sh to show available styles
4. Present analysis summary + recommended angle + style options
5. >>> CHECKPOINT 1 <<<
```

### Phase 2: Script (automatic)

```
6. Invoke fenghua-scriptwriter with confirmed angle and style
7. Present script with 3 title options and duration estimate
8. >>> CHECKPOINT 2 <<<
```

### Phase 3: TTS Generation + 口播稿确认

```
9. Invoke fenghua-voice-synthesizer → narration.mp3 + narration.srt
   - Prefer user voice clone (speakerId: voice-clone-*) if available
   - Download TTS-generated SRT for precise timing
10. Present TTS audio for review:
    - Provide audio file link for playback
    - Show SRT text alongside original script for comparison
    - Highlight any pronunciation concerns (names, numbers, terms)
11. >>> CHECKPOINT 3: 口播稿确认 <<<
```

### Phase 4: Visual Production (parallel, automatic)

After 口播稿 approval, run these in parallel:

```
PARALLEL TRACK A (Images):
  12a. Invoke fenghua-storyboard-designer → storyboard.json + .tsv
  13a. Invoke fenghua-image-producer → generate all frame images
       - Use avatar + style reference images if available (AI Gateway primary)
       - Post-process: trim white borders + resize to 1920x1080
  14a. Invoke fenghua-quality-reviewer → QC images, auto-retry failures

PARALLEL TRACK B (Cover):
  12b. Generate cover image using generate-image Skill or Listenhub
       - MUST use user's cartoon avatar (not stock photos of public figures)
       - Title text must be prominent and clearly readable
       - Use the selected title + style as prompt
```

### Phase 5: Assembly (after checkpoint)

```
15. Align scene timing to TTS-generated SRT (not estimated durations!)
    - Update scenes.ts boundaries to match actual SRT timestamps
    - Recalculate TOTAL_FRAMES from actual audio end time
    - Note: subtitles.ts kept for reference but NOT rendered in Remotion
16. Present production summary:
    - Frames passed QC: X/Y
    - Audio status: confirmed at Checkpoint 3
    - Cover image: ready
17. >>> CHECKPOINT 4 <<<
18. Invoke fenghua-video-assembler → render clean 16:9 (NO subtitles)
19. Speed up to 1.1x (ffmpeg)
20. Overlay onto 3:4 branded background (ffmpeg) → intermediate file (no subtitles yet)
21. Split SRT into short natural-sentence segments (≤25 chars each):
    - Split at sentence ends (。！？) first, then clause separators (，、；) if still too long
    - Each segment is a single displayed subtitle line — NO multi-line wrapping
    - SRT timing ÷ 1.1 speed factor, time distributed proportionally by char count
22. Burn subtitles into 3:4 video:
    - **Primary:** ffmpeg `ass` filter (if ffmpeg has libass compiled in)
    - **Fallback:** Python + Pillow per-frame compositing (when ffmpeg lacks libass, e.g. macOS Homebrew default)
    - Font: STHeiti Medium (macOS) / PingFang SC / WenQuanYi Zen Hei (Linux)
    - Font size: 42, white text with black outline (2px)
    - Position: SUB_Y_CENTER=880 (between video bottom y=823 and logo y=1060)
    - Single-line display only — one subtitle line at a time
23. Generate social-copy.txt from script.json social_caption + hashtags
24. Generate cover image (3:4, Listenhub API, avatar + title)
```

**Key pipeline:** Subtitles are NOT in the 16:9 Remotion render. They are burned onto the 3:4 version only, positioned in the gap between the video bottom (y=823) and the logo (~y=1050). Each subtitle shows as a single line (pre-split from SRT), avoiding multi-line clutter.

### Phase 5: Delivery

```
21. Present final deliverables:
    - Video file(s): 16:9 clean, 16:9 1.1x, 3:4 with subtitles
    - Cover image
    - Social copy
22. Save project archive with all intermediate files
```

## Project Directory Structure

```
project-{slug}/
├── content-analysis.json      # Phase 1 output
├── script.json                # Phase 2 output
├── script.txt                 # Plain narration text
├── storyboard.json            # Phase 3 output
├── storyboard-prompts.tsv
├── storyboard-common-prompt.txt
├── storyboards/
│   └── final/                 # QC-approved images
├── audio/
│   └── narration.mp3
├── subtitles/
│   ├── narration.srt           # TTS-generated SRT (timing source)
│   └── narration-3x4.ass      # ASS subtitles for 3:4 (burned via ffmpeg)
├── quality-report.json
├── remotion-project/          # Remotion source
├── outputs/
│   ├── video-16x9.mp4         # Master render
│   ├── video-16x9-1.1x.mp4   # 1.1x speed for social
│   ├── video-3x4.mp4          # Vertical with branded background
│   ├── cover.png
│   └── social-copy.txt
└── manifest.json              # Full project manifest
```

## Configuration Options

Users can override defaults when invoking:

| Option | Default | Description |
|--------|---------|-------------|
| `style` | auto-select | Aesthetic style (tech-blue, minimalist-white, dark-gold) |
| `duration` | 1-3 min | Target video length |
| `language` | auto-detect | zh or en |
| `speed` | 1.1 | Playback speed multiplier for social media version |
| `vertical` | true | Produce 3:4 vertical version with branded background |
| `vertical_bg` | user-provided | Path to 3:4 background image (e.g., 视频背景2.jpg) |
| `avatar_url` | none | Personal avatar image URL for character consistency |
| `style_refs` | none | 1-3 style reference image URLs |
| `voice_clone` | auto-detect | Prefer voice-clone-* speakerId if available |
| `checkpoints` | true | Enable/disable human checkpoints |

## Decision Framework

| Decision Level | Scope | Who Decides |
|---------------|-------|-------------|
| **Green** | Technical choices, prompt wording, transition types | AI (automatic) |
| **Yellow** | Style selection, frame density, retry strategies | AI (logged) |
| **Red** | Content angle, script approval, render confirmation | Human (checkpoint) |

## Sub-Skill Dependencies

```
fenghua-video-master
  ├── fenghua-content-analyzer
  ├── fenghua-scriptwriter
  ├── fenghua-storyboard-designer
  │   └── fenghua-aesthetics-library
  ├── fenghua-image-producer
  │   ├── Listenhub marswave API (primary, supports base64 avatar refs)
  │   ├── AI Gateway (secondary, if API key available)
  │   └── nano-banana-pro-openrouter (fallback)
  ├── fenghua-voice-synthesizer
  │   └── Listenhub marswaveai/skills tts (supports voice clones)
  ├── fenghua-quality-reviewer
  └── fenghua-video-assembler
      ├── remotion (clean 16:9 render, no subtitles)
      ├── ffmpeg (1.1x speed + 3:4 packaging)
      └── Python+Pillow (subtitle burn, fallback when ffmpeg lacks libass)
```

## Environment Requirements

| Variable | Required For | How to Get |
|----------|-------------|------------|
| `LISTENHUB_API_KEY` | TTS + image gen (唯一必需) | https://listenhub.ai/settings/api-keys |
| `AI_GATEWAY_API_KEY` | Image gen (可选备选) | Pre-configured in HappyCapy |
| `OPENROUTER_API_KEY` | Image fallback (可选) | https://openrouter.ai/keys |

**最小可用配置：仅需 `LISTENHUB_API_KEY` 即可完成 TTS + 图片生成全流程。**

## Tips for Best Results

1. **Rich input = better output** — the more context you provide, the better the content analysis
2. **Review at checkpoints** — these 3 pauses exist for a reason; small course-corrections here save big rework later
3. **Let it fail gracefully** — even if 1-2 images fail QC, the video will still be produced with the successful frames
4. **Iterate after delivery** — use the project archive to regenerate specific frames or re-edit the script
