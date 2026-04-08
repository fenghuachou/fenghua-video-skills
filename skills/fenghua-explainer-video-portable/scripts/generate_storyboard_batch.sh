#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 4 ] || [ "$#" -gt 8 ]; then
  echo "Usage: $0 <scene_file.tsv> <output_dir> <avatar_ref> <style_ref_csv> [model] [resolution] [generator_script] [common_prompt_file]" >&2
  exit 1
fi

SCENE_FILE="$1"
OUTPUT_DIR="$2"
AVATAR_REF="$3"
STYLE_REF_CSV="$4"
MODEL="${5:-google/gemini-3.1-flash-image-preview}"
RESOLUTION="${6:-1K}"
GENERATOR_SCRIPT="${7:-${FENGHUA_IMAGE_GENERATOR_SCRIPT:-$HOME/.agents/skills/nano-banana-pro-openrouter/scripts/generate_image.py}}"
COMMON_PROMPT_FILE="${8:-}"

if [ ! -f "$SCENE_FILE" ]; then
  echo "Missing scene file: $SCENE_FILE" >&2
  exit 1
fi

if [ ! -f "$AVATAR_REF" ]; then
  echo "Missing avatar reference: $AVATAR_REF" >&2
  exit 1
fi

if [ ! -f "$GENERATOR_SCRIPT" ]; then
  echo "Missing generator script: $GENERATOR_SCRIPT" >&2
  echo "Set FENGHUA_IMAGE_GENERATOR_SCRIPT or pass the script path explicitly." >&2
  exit 1
fi

COMMON_PROMPT="Create a Chinese AI short-video storyboard frame in the style of a bold explainer thumbnail, 16:9, no video UI, no speaker photo, no bottom banner, no readable Chinese text. Use the same creator avatar consistently. Keep the avatar medium-sized on the left, around one quarter of the frame. Make the right side the main storytelling area. Use a blue tech background, yellow highlights, infographic composition, one strong core visual metaphor, and 2 to 3 supporting highlight modules. Leave clear safe areas for later Chinese headline overlays in the upper right and lower center."
if [ -n "$COMMON_PROMPT_FILE" ]; then
  if [ ! -f "$COMMON_PROMPT_FILE" ]; then
    echo "Missing common prompt file: $COMMON_PROMPT_FILE" >&2
    exit 1
  fi
  COMMON_PROMPT="$(cat "$COMMON_PROMPT_FILE")"
fi

mkdir -p "$OUTPUT_DIR"

IFS=',' read -r -a STYLE_REFS <<< "$STYLE_REF_CSV"
INPUT_ARGS=(--input-image "$AVATAR_REF")
for ref in "${STYLE_REFS[@]}"; do
  CLEAN_REF="$(printf '%s' "$ref" | xargs)"
  [ -n "$CLEAN_REF" ] || continue
  if [ ! -f "$CLEAN_REF" ]; then
    echo "Missing style reference: $CLEAN_REF" >&2
    exit 1
  fi
  INPUT_ARGS+=(--input-image "$CLEAN_REF")
done

if [ -n "${FENGHUA_IMAGE_RUNNER:-}" ]; then
  read -r -a RUN_CMD <<< "${FENGHUA_IMAGE_RUNNER}"
elif command -v uv >/dev/null 2>&1; then
  RUN_CMD=(uv run)
else
  RUN_CMD=(python3)
fi

while IFS=$'\t' read -r filename prompt || [ -n "$filename" ]; do
  [ -n "${filename// }" ] || continue
  [[ "$filename" =~ ^# ]] && continue
  if [ -z "${prompt// }" ]; then
    echo "Skipping scene with empty prompt: $filename" >&2
    continue
  fi

  "${RUN_CMD[@]}" "$GENERATOR_SCRIPT" \
    --model "$MODEL" \
    --prompt "$COMMON_PROMPT $prompt" \
    "${INPUT_ARGS[@]}" \
    --filename "$OUTPUT_DIR/${filename}.png" \
    --resolution "$RESOLUTION"
done < "$SCENE_FILE"

echo "Generated storyboard batch in $OUTPUT_DIR"
