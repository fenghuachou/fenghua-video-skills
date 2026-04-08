---
name: fenghua-quality-reviewer
description: >
  AI quality control for storyboard images — visual defect detection, style consistency check,
  and content-narration alignment. Auto-retries failed frames (max 2 retries).
  Use after fenghua-image-producer, before fenghua-video-assembler.
---

# Fenghua Quality Reviewer

Performs automated quality control on generated storyboard images before video assembly.

## Scope

1. **Visual defect detection** — garbled text, deformed elements, artifacts
2. **Style consistency** — all frames match the chosen aesthetic style
3. **Content alignment** — image content matches the narration/storyboard intent

## Input

- `storyboards/final/*.png` — generated images
- `storyboard.json` — storyboard with visual descriptions and narration
- Style reference HTML from `fenghua-aesthetics-library`

## Output

- `quality-report.json` — detailed QC report for each frame
- Auto-triggers regeneration for failed frames (max 2 retries)

## Quality Report Schema

```json
{
  "review_timestamp": "2026-03-15T10:30:00Z",
  "total_frames": 18,
  "passed": 16,
  "failed": 1,
  "retried_and_passed": 1,
  "skipped": 0,
  "frames": [
    {
      "frame_id": "scene-01",
      "image_path": "storyboards/final/scene-01.png",
      "status": "passed | failed | retried_passed | skipped",
      "checks": {
        "visual_defects": {"pass": true, "notes": ""},
        "style_consistency": {"pass": true, "notes": ""},
        "content_alignment": {"pass": true, "notes": ""}
      },
      "retry_count": 0,
      "overall_score": "good | acceptable | poor"
    }
  ],
  "summary": "17/18 frames passed QC. 1 frame retried successfully."
}
```

## QC Checks

### 1. Visual Defect Detection

Read each image file and check for:

| Defect | Detection Method | Severity |
|--------|-----------------|----------|
| Garbled/unreadable text baked into image | Visual inspection — look for distorted characters | HIGH |
| Deformed human features (hands, faces) | Visual inspection — check proportions | HIGH |
| Obvious artifacts or glitches | Visual inspection — color blocks, tears | HIGH |
| Blurry or low-resolution areas | Visual inspection — check sharpness | MEDIUM |
| Watermarks or unwanted overlays | Visual inspection — check for logos/text | MEDIUM |

### 2. Style Consistency

Compare each frame against:
- The chosen aesthetic style (read from aesthetics library)
- Other frames in the same storyboard

Check for:
- Color palette adherence (dominant colors match style)
- Layout consistency (avatar position, content areas)
- Typography area reserved (safe zones for overlays)

### 3. Content Alignment

Compare each frame's image against:
- `visual_description` from storyboard.json
- `narration_segment` from the corresponding section

Check for:
- Core visual element is present
- No contradictory imagery (e.g., showing failure when narration describes success)
- Emotional tone matches (energetic image for energetic narration)

## Review Process

### Per-frame review:

```
For each frame in storyboard:
  1. Read the image file (multimodal)
  2. Read the corresponding storyboard entry
  3. Evaluate against 3 check categories
  4. Score: good / acceptable / poor
  5. If poor (any HIGH severity defect):
     → If retry_count < 2: trigger regeneration via fenghua-image-producer
     → If retry_count >= 2: mark as "skipped", log warning
  6. Record results in quality-report.json
```

### Regeneration trigger:

When a frame fails QC:
1. Log the specific defect in the report
2. Optionally adjust the prompt (e.g., add "no text", "no watermark")
3. Call fenghua-image-producer for just that frame
4. Re-check the new image
5. Update the report

## Decision Framework (Red/Yellow/Green)

Following the "余一决策模式":

| Level | Condition | Action |
|-------|-----------|--------|
| **Green** | All checks pass, score is "good" | Proceed automatically |
| **Yellow** | Minor issues, score is "acceptable" | Proceed, log for future improvement |
| **Red** | HIGH severity defect after 2 retries | Skip frame, flag for human review |

## Integration

- **Depends on**: fenghua-image-producer (images), fenghua-storyboard-designer (context)
- **Triggers**: fenghua-image-producer (for regeneration)
- **Feeds into**: fenghua-video-assembler (approved images)
