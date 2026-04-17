---
name: fenghua-explainer-video-portable
description: Portable Fenghua-style explainer video workflow for use across different computers. Use when Codex needs a path-agnostic version of the Fenghua video pipeline, or when the user wants to move the skill to another machine and keep TTS, storyboard generation, Remotion rendering (clean 16:9, no subtitles), ffmpeg 3:4 packaging, and ASS subtitle burn working with environment variables and local project-relative files.
---

# Fenghua Explainer Video Portable

## Overview

Use this skill when the workflow must survive machine changes. It preserves the same Fenghua explainer video pipeline as the local skill, but removes project-specific absolute paths and replaces them with portable defaults, environment variables, and per-project inputs.

## When To Use

Use this skill when the user asks to:

1. move the Fenghua video workflow to another computer
2. make the existing skill portable
3. avoid hard-coded workspace paths
4. run the same pipeline in a new project folder

## Core Rules

1. Never hard-code project asset paths into the skill.
2. Treat every project as self-contained under one project root.
3. Prefer environment variables for machine-specific dependencies.
4. Fail with a clear setup error when an external dependency cannot be found.
5. Keep output names stable so downstream steps remain automatable.

## Required External Dependencies

The skill expects these tools or integrations to exist on the target machine:

1. `ffmpeg`
2. `node`, `npm`, `npx`
3. `uv` or `python3`
4. a Chromium-based browser for Remotion rendering
5. `listenhub` if TTS is required
6. `nano-banana-pro-openrouter` if storyboard generation is required

## Preferred Environment Variables

Use these when present:

1. `LISTENHUB_API_KEY`
2. `OPENROUTER_API_KEY`
3. `REMOTION_BROWSER_EXECUTABLE`
4. `FENGHUA_IMAGE_GENERATOR_SCRIPT`
5. `FENGHUA_IMAGE_RUNNER`

## Bundled Scripts

1. `scripts/init_fenghua_project.sh`
   - creates a portable project skeleton
   - use first on a new machine or new topic

2. `scripts/generate_storyboard_batch.sh`
   - batch-generates storyboard images from `filename<TAB>prompt`
   - uses environment variables or explicit arguments instead of machine-specific paths

3. `scripts/render_16x9_master.sh`
   - renders the clean `16:9` master from a prepared Remotion project (no subtitles)
   - auto-detects a browser if `REMOTION_BROWSER_EXECUTABLE` is not set

4. `scripts/package_3x4_bg_top.sh`
   - wraps a `16:9` master inside a `3:4` background at y=216
   - outputs intermediate file without subtitles

5. `scripts/generate_ass_subtitles.sh`
   - converts SRT to ASS format for 3:4 frame
   - applies speed factor (1.1x), sets Alignment=8 MarginV=840
   - smart Chinese punctuation wrapping (~22-24 chars/line)

6. `scripts/burn_ass_subtitles.sh`
   - burns ASS subtitles into 3:4 video via ffmpeg
   - positions subtitles below 16:9 video area, above logo

Read [references/pipeline.md](./references/pipeline.md) for setup and path conventions.

## Recommended Project Layout

Create one project directory per video topic.

Use this shape:

1. `script.txt`
2. `audio/`
3. `subtitles/`
4. `storyboards/raw/`
5. `storyboards/final/`
6. `assets/avatar/`
7. `assets/backgrounds/`
8. `outputs/`
9. `notes/`

## Workflow

### A. Full build from script

1. normalize the spoken script
2. generate `mp3 + srt`
3. write scene prompts into `notes/storyboard-prompts.tsv`
4. generate storyboard images
5. render clean `16:9` master (no subtitles in Remotion)
6. speed up to 1.1x (ffmpeg)
7. overlay onto `3:4` branded background (ffmpeg)
8. generate ASS subtitle file from SRT (timing / 1.1, smart Chinese wrapping)
9. burn ASS subtitles into `3:4` video (ffmpeg) — positioned below 16:9 area
10. **[基本节点] 生成视频号介绍文本** → `outputs/intro-text.md`
    - 三段式结构：短版（≤30字）+ 长版（200-300字）+ 话题标签（5-8个）
    - 从 script.json 的 social_caption / hashtags 起稿
11. **[基本节点] 生成 3:4 封面图** → `outputs/cover-3x4.png`
    - Listenhub `/images/generation`，`aspectRatio: "3:4"`
    - 四层结构：主标题 + 视觉元素 + 头像（bottom-right，必传 referenceImages）+ 副标签
    - 参见 references/pipeline.md 的 "Publishing Assets" 章节

### B. Existing `mp3 + srt`

Start from storyboard planning.

### C. Existing `16:9` master

Skip timeline work and use the packaging scripts only.

## Portability Guidance

1. Keep project assets inside the project root, not inside the skill.
2. Pass explicit paths into scripts rather than editing the skill each time.
3. Install external skills on the new machine if you want the same TTS or image-generation helpers.
4. If the browser path differs by OS, set `REMOTION_BROWSER_EXECUTABLE` rather than editing scripts.
5. If the OpenRouter image generator script is elsewhere, set `FENGHUA_IMAGE_GENERATOR_SCRIPT`.

## Outputs

Typical output set:

1. `audio/topic-fenghua.mp3`
2. `subtitles/topic-fenghua.srt`
3. `subtitles/topic-3x4.ass` — ASS subtitles for 3:4 (Alignment=8, MarginV=840)
4. `storyboards/final/*.png`
5. `outputs/topic-16x9-clean.mp4` — clean 16:9, no subtitles
6. `outputs/topic-16x9-1.1x.mp4` — 1.1x speed
7. `outputs/topic-3x4.mp4` — 3:4 with subtitles burned below video area
8. `outputs/cover-3x4.png` — 视频号封面图（3:4, Listenhub API 生成）
9. `outputs/intro-text.md` — 视频号介绍文本（短版+长版+话题标签）

## References

Read [references/pipeline.md](./references/pipeline.md) for:

1. setup checklist for a new machine
2. environment-variable contract
3. portable script usage

Read [references/publishing-assets.md](./references/publishing-assets.md) for:

1. 视频号介绍文本（Node 10）撰写模板与原则
2. 3:4 封面图（Node 11）生成脚本模板与 prompt 四层结构
3. Listenhub 图片生成 API 参数要点与响应解析
