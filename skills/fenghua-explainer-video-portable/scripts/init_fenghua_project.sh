#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Usage: $0 <project_root> [project_slug]" >&2
  exit 1
fi

PROJECT_ROOT="$1"
PROJECT_SLUG="${2:-new-topic}"
TARGET_DIR="${PROJECT_ROOT%/}/${PROJECT_SLUG}"

mkdir -p \
  "$TARGET_DIR/assets/avatar" \
  "$TARGET_DIR/assets/backgrounds" \
  "$TARGET_DIR/audio" \
  "$TARGET_DIR/subtitles" \
  "$TARGET_DIR/storyboards/raw" \
  "$TARGET_DIR/storyboards/final" \
  "$TARGET_DIR/outputs" \
  "$TARGET_DIR/notes"

[ -f "$TARGET_DIR/script.txt" ] || cat > "$TARGET_DIR/script.txt" <<'TXT'
Title:
Hook:
Main points:
Closing CTA:
TXT

[ -f "$TARGET_DIR/notes/scene-plan.md" ] || cat > "$TARGET_DIR/notes/scene-plan.md" <<'TXT'
# Scene plan

1. Scene 01
   - topic:
   - metaphor:
   - avatar expression:
   - layout notes:
TXT

[ -f "$TARGET_DIR/notes/storyboard-prompts.tsv" ] || cat > "$TARGET_DIR/notes/storyboard-prompts.tsv" <<'TXT'
# filename<TAB>prompt
scene-01-hook	Avatar expression: thoughtful. Main subject: one strong visual metaphor for the opening hook, plus 2 supporting infographic modules.
TXT

[ -f "$TARGET_DIR/notes/storyboard-common-prompt.txt" ] || cat > "$TARGET_DIR/notes/storyboard-common-prompt.txt" <<'TXT'
Create a Chinese AI short-video storyboard frame in the style of a bold explainer thumbnail, 16:9, no video UI, no speaker photo, no bottom banner, no readable Chinese text. Use the same creator avatar consistently. Keep the avatar medium-sized on the left, around one quarter of the frame. Make the right side the main storytelling area. Use a blue tech background, yellow highlights, infographic composition, one strong core visual metaphor, and 2 to 3 supporting highlight modules. Leave clear safe areas for later Chinese headline overlays in the upper right and lower center.
TXT

[ -f "$TARGET_DIR/notes/output-checklist.md" ] || cat > "$TARGET_DIR/notes/output-checklist.md" <<'TXT'
# Output checklist

- script reviewed
- voice generated
- subtitles reviewed
- storyboard batch approved
- 16:9 master rendered
- 3:4 publish version exported
TXT

echo "Created portable project template at: $TARGET_DIR"
