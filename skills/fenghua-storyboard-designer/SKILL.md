---
name: fenghua-storyboard-designer
description: >
  Design storyboards from video scripts — splits narration into visual frames with image prompts,
  overlay text, timing, and transitions. Outputs JSON + TSV (compatible with fenghua-explainer-video-portable).
  Use after fenghua-scriptwriter.
---

# Fenghua Storyboard Designer

Transforms a script into a frame-by-frame storyboard that drives image generation and video assembly.

## Input

- `script.json` — output from fenghua-scriptwriter

## Output

- `storyboard.json` — full structured storyboard
- `storyboard-prompts.tsv` — `filename<TAB>prompt` format, compatible with `generate_storyboard_batch.sh`
- `storyboard-common-prompt.txt` — shared prompt prefix for consistent visual style

## Frame Density

- **Default: 1 frame per 5-8 seconds** of narration
- For a 2-minute video: approximately 15-24 frames
- Faster-paced sections (hook, twist) use shorter frames (5s)
- Slower sections (argument exposition) use longer frames (8s)

## Storyboard JSON Schema

```json
{
  "project_title": "Video title",
  "style_ref": "tech-blue",
  "total_frames": 18,
  "total_duration": "2:15",
  "aspect_ratio": "16:9",
  "frames": [
    {
      "frame_id": "scene-01",
      "frame_number": 1,
      "section_ref": "hook",
      "narration_segment": "The narration text for this frame",
      "visual_description": "Human-readable description of what appears on screen",
      "image_prompt": "Detailed image generation prompt in English",
      "overlay_text": "Text displayed on screen (headline or key phrase)",
      "overlay_position": "center | top-right | bottom-center",
      "duration": "6s",
      "transition_in": "fade | slide | cut | wipe",
      "transition_duration": "0.5s",
      "key_visual_element": "The single most important visual in this frame"
    }
  ]
}
```

## TSV Output Format

Compatible with `fenghua-explainer-video-portable/scripts/generate_storyboard_batch.sh`:

```tsv
# Storyboard prompts for: Video Title
# Style: tech-blue
scene-01.png	A bold explainer thumbnail showing [visual description], 16:9 aspect ratio, ...
scene-02.png	[next frame prompt]
```

## Common Prompt File

`storyboard-common-prompt.txt` is prepended to each frame's prompt for style consistency:

```
Create a Chinese AI short-video storyboard frame in the style of a bold explainer thumbnail,
16:9, no video UI, no speaker photo, no bottom banner, no readable Chinese text.
Use [style-specific colors and layout from aesthetics library].
Keep clear safe areas for later Chinese headline overlays.
```

## Storyboard Design Rules

### Visual Storytelling Principles

1. **One core visual per frame** — each frame has ONE dominant visual metaphor
2. **Visual variety** — alternate between: data visualizations, metaphor illustrations, quote cards, comparison layouts
3. **Consistent style** — read the chosen style from `fenghua-aesthetics-library` and maintain it
4. **Text overlay safe zones** — leave upper-right and lower-center areas clear for Chinese text overlays

### Frame Type Vocabulary

| Frame Type | When to Use | Visual Pattern |
|-----------|-------------|----------------|
| **Hook frame** | Opening 3 seconds | Bold question or striking image, high contrast |
| **Data frame** | When showing numbers/stats | Large number + context, counter-style animation hint |
| **Point frame** | Each core argument | Icon/metaphor on left + text area on right |
| **Quote frame** | Key quotes or insights | Quote text with attribution, subtle background |
| **Comparison frame** | Before/after, A vs B | Split layout or side-by-side |
| **Transition frame** | Between sections | Minimal, serves as visual breath |
| **Closing frame** | Final frame | CTA text, social handles, clean layout |

### Image Prompt Writing Rules

1. **Always in English** — image generation models work best with English prompts
2. **Start with style context** — "bold explainer thumbnail style, 16:9..."
3. **Describe composition** — where elements are placed
4. **Include mood/lighting** — "tech blue glow", "warm golden ambient"
5. **Reference the common prompt** — the TSV prompt is APPENDED to the common prompt

### Avatar Mode vs Standard Mode

**Avatar mode** (when user provides personal avatar):
- Each frame MUST include the avatar character with consistent appearance
- Text labels and key information ARE baked into images by the AI model
- Overlay text in Remotion is NOT needed (images are self-contained)
- Prompts should explicitly describe the avatar (e.g., "Asian male with glasses and olive green zip sweater")
- Use `images` array in AI Gateway API to pass avatar + style references for consistency

**Standard mode** (no avatar):
- Images are purely visual/abstract/metaphorical
- Specify NO readable text in images — text will be overlaid by Remotion
- overlay_text field in storyboard.json drives Remotion text overlays

## Workflow

1. Read `script.json` — understand sections, narration, visual hints
2. Read aesthetic style reference from `fenghua-aesthetics-library`
3. Split narration into frames (5-8 seconds each)
4. For each frame:
   - Write visual description (human-readable)
   - Write image generation prompt (English, optimized for AI image gen)
   - Determine overlay text (key phrase from narration)
   - Set transition type
5. Write `storyboard-common-prompt.txt`
6. Output `storyboard.json` and `storyboard-prompts.tsv`

## Integration

- **Depends on**: fenghua-scriptwriter (script.json), fenghua-aesthetics-library (style reference)
- **Feeds into**: fenghua-image-producer (prompts), fenghua-video-assembler (timing/transitions)
