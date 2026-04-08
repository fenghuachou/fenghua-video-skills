**[中文](./README_zh.md) | English**

# Fenghua Explainer Video Skills

A modular skill pipeline for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that transforms articles, links, or raw content into polished short explainer videos — complete with AI-generated narration, storyboard images, subtitles, and branded packaging.

## Overview

This pipeline orchestrates 10 specialized skills to produce 2-minute vertical explainer videos, ideal for platforms like WeChat Channels (视频号), Douyin, or YouTube Shorts.

```
Article / URL / Text
       │
       ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────────────┐
│  content-    │────▶│  script-     │────▶│  storyboard-         │
│  analyzer    │     │  writer      │     │  designer            │
└──────────────┘     └──────────────┘     └──────────────────────┘
                                                │
                          ┌─────────────────────┤
                          ▼                     ▼
                  ┌──────────────┐     ┌──────────────────┐
                  │  voice-      │     │  image-           │
                  │  synthesizer │     │  producer          │
                  └──────┬───────┘     └──────┬────────────┘
                         │                    │
                         │    ┌───────────────┘
                         │    ▼
                         │  ┌──────────────┐
                         │  │  quality-    │
                         │  │  reviewer    │
                         │  └──────┬───────┘
                         │         │
                         ▼         ▼
                  ┌──────────────────────┐
                  │  video-assembler     │
                  │  (Remotion + ffmpeg) │
                  └──────────┬───────────┘
                             │
                             ▼
                   Final Video Outputs
                   ├── 16:9 master
                   ├── 3:4 vertical (with subtitles)
                   └── Cover image + social copy
```

## Skills

| Skill | Description |
|-------|-------------|
| **fenghua-video-master** | End-to-end orchestrator — give it an article and it coordinates all other skills |
| **fenghua-content-analyzer** | Extracts core arguments, key quotes, data points from articles/URLs/text |
| **fenghua-scriptwriter** | Generates broadcast-ready narration scripts (Hook → Pain Point → Arguments → Twist → Closing) |
| **fenghua-storyboard-designer** | Converts scripts into frame-by-frame visual plans with image prompts |
| **fenghua-image-producer** | Batch-generates avatar-style storyboard images via Listenhub marswave API |
| **fenghua-voice-synthesizer** | TTS narration with voice clone support via Listenhub |
| **fenghua-quality-reviewer** | Automated QC on generated images (defect detection, style consistency) |
| **fenghua-video-assembler** | Remotion + ffmpeg assembly: Ken Burns zoom, crossfade, 1.1x speed, 3:4 packaging, subtitle burning |
| **fenghua-aesthetics-library** | Shared visual style references (HTML templates for color palettes and layouts) |
| **fenghua-explainer-video-portable** | Machine-portable version of the pipeline using environment variables |

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Node.js 18+ and npm
- Python 3.10+ with Pillow (`pip install Pillow`)
- ffmpeg (via Homebrew on macOS: `brew install ffmpeg`)
- ImageMagick (`brew install imagemagick`)
- A [Listenhub](https://listenhub.ai) API key (for TTS and image generation)

## Installation

This repo is packaged as a **Claude Code plugin**. Install it with one command inside Claude Code:

```
/plugin install https://github.com/fenghuachou/fenghua-video-skills
```

You will be prompted for your `LISTENHUB_API_KEY` during installation.

### Manual install (alternative)

```bash
git clone https://github.com/fenghuachou/fenghua-video-skills.git ~/.claude/plugins/fenghua-video
echo 'export LISTENHUB_API_KEY="your-key-here"' >> ~/.zshrc
source ~/.zshrc
```

### Optional — enhanced TTS helpers

```bash
npx skills add marswaveai/skills
```

## Quick Start

In Claude Code, simply say:

```
/fenghua-video:fenghua-video-master

请根据以下链接创作一条解说短视频：https://example.com/article
```

The master skill will:
1. Analyze the article content
2. Generate a narration script (awaits your approval)
3. Design a storyboard (awaits your approval)
4. Generate TTS audio + storyboard images in parallel
5. QC the images
6. Assemble the final video with Remotion
7. Package into 3:4 vertical format with subtitles
8. Generate cover image and social media copy

## Output Files

```
outputs/
├── video-16x9.mp4          # 16:9 master video (1920x1080)
├── video-16x9-1.1x.mp4     # 1.1x speed version
├── video-3x4.mp4           # 3:4 vertical with burned subtitles (1080x1440)
├── video-3x4-nosub.mp4     # 3:4 without subtitles
├── cover.png               # 3:4 cover image
└── social-copy.txt         # Video description for social platforms
```

## Customization

### Avatar

Provide your cartoon avatar (PNG, preferably transparent background) when prompted. The image producer encodes it as base64 and includes it in every frame generation request for character consistency.

### Visual Style

Edit `fenghua-aesthetics-library/styles/` to add or modify HTML style references. The storyboard designer and image producer use these to maintain visual consistency.

### Script Structure

The scriptwriter follows a 5-section model:
1. **Hook** (钩子) — Attention-grabbing opening question
2. **Pain Point** (痛点) — Relatable problem statement
3. **Arguments** (论点 x3) — Core insights with evidence
4. **Twist** (转折) — Surprising perspective shift
5. **Closing** (收束) — Memorable takeaway

### Subtitle Settings

Subtitles are pre-split into single-line segments (max 25 Chinese characters) and positioned at y=880 in the 3:4 frame (between video bottom and logo area).

Two subtitle burning methods:
- **ffmpeg ASS filter** — if your ffmpeg has libass support
- **Python + Pillow** — fallback for macOS Homebrew ffmpeg (default on Mac)

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `LISTENHUB_API_KEY` | Yes | Listenhub / marswave API key for TTS and image generation |
| `AI_GATEWAY_API_KEY` | No | Optional AI Gateway for image generation fallback |
| `OPENROUTER_API_KEY` | No | Optional OpenRouter for additional model access |

## Architecture Notes

- **Image generation** uses a 4-layer prompt architecture: character anchor → position/expression → focal content → background/style
- **Focal content types**: yellow label boxes, infographics, visual metaphors, before/after comparisons, character interactions, spotlight text
- **Video assembly**: Remotion renders clean 16:9 → ffmpeg applies 1.1x speed → overlays onto 3:4 background → burns subtitles
- **Subtitle pipeline**: SRT from TTS → adjust timing for 1.1x → split into ≤25 char segments → burn with Pillow/ASS

## License

MIT
