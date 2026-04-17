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
| Cover (3:4) | `outputs/cover-3x4.png` | 视频号封面图（3:4，头像+标题+视觉元素） |
| Intro text | `outputs/intro-text.md` | 视频号介绍文本（短版 + 长版 + 话题标签） |
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
  v
[4] fenghua-storyboard-designer ── Plan frames
  |
  v
[5] fenghua-image-producer ─────── Generate all frames
  |
  v
[6] fenghua-quality-reviewer ───── QC + auto-retry
  |
  v
>>> CHECKPOINT 4: Confirm before rendering <<<
  |
  v
[7] fenghua-video-assembler ────── Render final video (16:9 + 1.1x + 3:4 + subs)
  |
  v
[8] Intro text generator ───────── Write 视频号介绍文本 → outputs/intro-text.md
  |
  v
[9] Cover image generator ──────── Generate 3:4 封面图 → outputs/cover-3x4.png
  |
  v
DELIVERY: video + cover + intro text
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

### Phase 4: Visual Production (automatic)

After 口播稿 approval:

```
12. Invoke fenghua-storyboard-designer → storyboard.json + .tsv
13. Invoke fenghua-image-producer → generate all frame images
    - Use avatar + style reference images if available (AI Gateway primary)
    - Post-process: trim white borders + resize to 1920x1080
14. Invoke fenghua-quality-reviewer → QC images, auto-retry failures
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
```

**Key pipeline:** Subtitles are NOT in the 16:9 Remotion render. They are burned onto the 3:4 version only, positioned in the gap between the video bottom (y=823) and the logo (~y=1050). Each subtitle shows as a single line (pre-split from SRT), avoiding multi-line clutter.

### Phase 6: Publishing Assets (基本节点 — 必须执行)

视频渲染完成后，**必须**生成两项发布配套资产。这两步是主流程的一级节点，不可省略。

#### Node 8: 视频号介绍文本 → `outputs/intro-text.md`

生成三段式发布文案，覆盖微信视频号 / 小红书 / 抖音等平台：

```
23. 撰写 outputs/intro-text.md，结构固定为三段：

    ## 短版（30 字以内，首屏钩子）
    用于视频号默认展示区，需包含数字冲击 + 核心悬念。
    例："Ramp 内部文件泄露：他们如何让 99.5% 员工主动用 AI？"

    ## 长版（200-300 字，展开说明）
    - 开头 1-2 句钩子（冲突 / 反常识 / 数字）
    - 中段 3-5 条要点列表（视频核心结论或金句）
    - 结尾 1 句 CTA（点赞 / 关注 / 留言）
    - 使用换行和 emoji 提升可读性（克制使用，1-2 个即可）

    ## 话题标签
    5-8 个 # 开头的话题标签，覆盖：
    - 核心主题（#AI转型 #企业AI）
    - 目标人群（#管理者 #创业者）
    - 内容类型（#案例拆解 #认知升级）
```

**写作原则：**
- 从 `script.json` 的 `social_caption` 和 `hashtags` 字段起稿（如有）
- 金句优先从脚本中直接提取，不要重写
- 标题句使用选定的 video title（Checkpoint 2 确认）
- 避免夸大 / 标题党 / 绝对化表述

#### Node 9: 视频号封面图（3:4）→ `outputs/cover-3x4.png`

使用 Listenhub `/images/generation` API 生成 3:4 封面图：

```
24. 生成 outputs/cover-3x4.png

    API: POST https://api.marswave.ai/openapi/v1/images/generation
    模型: gemini-3-pro-image-preview
    imageConfig: { imageSize: "2K", aspectRatio: "3:4" }
    referenceImages: [avatar_base64]  ← 必须传头像，保证人物一致性
```

**Prompt 四层结构（必须包含）：**

| Layer | 位置 | 内容 |
|-------|------|------|
| 1 | TOP（主标题） | 两行 Chinese 大标题，thick sans-serif，white + black outline。核心数字用亮黄色高亮 |
| 2 | MIDDLE | 视觉信息元素（数据卡片、对比图、关键符号等），配合 Layer 1 标题 |
| 3 | BOTTOM-RIGHT（人物） | Fenghua 头像（Asian male, glasses, olive green zip sweater），约占 30% 画面宽度，must match reference avatar exactly |
| 4 | BOTTOM-LEFT（副标签） | 小号黄色 tag（4-6 字），如「AI 转型真相」「认知升级」|

**设计要求：**
- 严格 3:4 portrait（1080x1440 或 2K 等比）
- 手机端小图仍清晰可读
- 避免视频 UI / 底部横条（视频号会叠加）
- 配色匹配视频整体 style（tech-blue / minimalist-white / dark-gold）
- 头像文件必须 <1MB（参见 fenghua-image-producer 的 avatar 限制）

**脚本示例：** 参见 project-ramp-ai-culture/generate-cover.py

### Phase 7: Delivery

```
25. Present final deliverables:
    - Video files: 16:9 clean, 16:9 1.1x, 3:4 with subtitles
    - Cover image: outputs/cover-3x4.png
    - Intro text: outputs/intro-text.md
26. Save project archive with all intermediate files
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
│   ├── video-16x9-1.1x.mp4    # 1.1x speed for social
│   ├── video-3x4.mp4          # Vertical with branded background + subtitles
│   ├── cover-3x4.png          # 视频号封面图（3:4, Phase 6 Node 9）
│   └── intro-text.md          # 视频号介绍文本（Phase 6 Node 8）
├── generate-cover.py          # Phase 6 Node 9 脚本
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
