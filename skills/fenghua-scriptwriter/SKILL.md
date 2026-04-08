---
name: fenghua-scriptwriter
description: >
  Generate short video narration scripts from content analysis JSON.
  Produces a 5-section script (hook, pain point, arguments, twist, closing) with timing,
  emotion cues, visual hints, and 3 candidate titles. Use after fenghua-content-analyzer.
---

# Fenghua Scriptwriter

Transforms the structured content analysis into a broadcast-ready narration script for 1-3 minute explainer videos.

## Input

- `content-analysis.json` — output from fenghua-content-analyzer

## Output

- `script.json` — structured script with timing and metadata
- `script.txt` — plain narration text (for TTS input)

## Script Structure: 5-Section Model

| Section | Purpose | Duration | Key Technique |
|---------|---------|----------|---------------|
| **Hook** | Grab attention in 3 seconds | 5-10s | Question, surprising fact, or bold claim |
| **Pain Point** | Establish the problem or phenomenon | 10-20s | Relatable scenario, "you've probably noticed..." |
| **Arguments** | 2-3 core points with evidence | 60-120s | Each point: claim + evidence + so-what |
| **Twist** | Key quote, counter-intuitive insight, or reframe | 10-20s | "But here's the thing..." |
| **Closing** | Call to action or thought-provoking question | 5-15s | "Think about this..." or "Try this today..." |

## Output Schema (script.json)

```json
{
  "video_titles": [
    "Title option 1 (most clickable)",
    "Title option 2 (most accurate)",
    "Title option 3 (most provocative)"
  ],
  "selected_title_index": 0,
  "total_duration_est": "2:15",
  "total_word_count": 450,
  "language": "zh",
  "sections": [
    {
      "id": "hook",
      "label": "开场钩子",
      "narration": "Full narration text for this section...",
      "duration_est": "8s",
      "word_count": 40,
      "emotion": "urgent | curious | calm | provocative | warm",
      "visual_hint": "Brief description of what should be shown on screen",
      "key_words": ["highlighted", "words", "for", "emphasis"]
    }
  ],
  "social_caption": "Ready-to-post social media caption for this video",
  "hashtags": ["#tag1", "#tag2", "#tag3"]
}
```

## Writing Guidelines

See `references/writing-guidelines.md` for detailed scriptwriting rules.

### Quick Rules:
1. **First 3 seconds decide everything** — the hook must create instant curiosity
2. **One idea per sentence** — short sentences, no complex clauses
3. **Speak, don't write** — the script is for SPEAKING, use conversational tone
4. **Show, don't tell** — every section includes `visual_hint` for the storyboard designer
5. **Title formula**: [Curiosity gap] + [Concrete benefit] + [Target audience signal]
   - Bad: "棉手套理论" (confusion, not curiosity)
   - Good: "别再当AI的保姆了" (relatable, clear target)

## Workflow

1. Read `content-analysis.json`
2. Select the best angle from `suggested_angles`
3. Draft 3 candidate titles — evaluate each for:
   - Would the target audience click? (user perspective, not creator perspective)
   - Is the meaning clear within 1 second?
   - Does it create curiosity (not confusion)?
4. Write each section following the 5-section model
5. Estimate duration: ~250 Chinese characters per minute / ~150 English words per minute
6. Output both `script.json` and `script.txt`

## Integration

- **Depends on**: fenghua-content-analyzer (input)
- **Feeds into**: fenghua-storyboard-designer (visual_hint), fenghua-voice-synthesizer (narration text)
