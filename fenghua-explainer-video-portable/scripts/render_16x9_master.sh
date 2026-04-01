#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 5 ]; then
  echo "Usage: $0 <remotion_project_dir> <output.mp4> [composition_id] [props_json] [browser_executable]" >&2
  exit 1
fi

find_browser() {
  if [ -n "${1:-}" ] && [ -x "$1" ]; then
    printf '%s\n' "$1"
    return 0
  fi

  if [ -n "${REMOTION_BROWSER_EXECUTABLE:-}" ] && [ -x "$REMOTION_BROWSER_EXECUTABLE" ]; then
    printf '%s\n' "$REMOTION_BROWSER_EXECUTABLE"
    return 0
  fi

  for path in \
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' \
    '/Applications/Chromium.app/Contents/MacOS/Chromium' \
    '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser'
  do
    if [ -x "$path" ]; then
      printf '%s\n' "$path"
      return 0
    fi
  done

  for cmd in google-chrome chromium-browser chromium brave-browser; do
    if command -v "$cmd" >/dev/null 2>&1; then
      command -v "$cmd"
      return 0
    fi
  done

  return 1
}

PROJECT_DIR="$1"
OUTPUT="$2"
COMPOSITION_ID="${3:-HowOneAILongVideo}"
PROPS_JSON="${4:-}"
BROWSER_EXECUTABLE="$(find_browser "${5:-}")" || {
  echo 'No usable browser found. Set REMOTION_BROWSER_EXECUTABLE or pass a browser path explicitly.' >&2
  exit 1
}
ENTRY_FILE="${PROJECT_DIR%/}/src/index.ts"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "Missing Remotion project directory: $PROJECT_DIR" >&2
  exit 1
fi

if [ ! -f "$ENTRY_FILE" ]; then
  echo "Missing Remotion entry file: $ENTRY_FILE" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

if [ -x "$PROJECT_DIR/node_modules/.bin/remotion" ]; then
  REMOTION_CMD=("$PROJECT_DIR/node_modules/.bin/remotion")
else
  REMOTION_CMD=(npx remotion)
fi

CMD=("${REMOTION_CMD[@]}" render "$ENTRY_FILE" "$COMPOSITION_ID" "$OUTPUT" --browser-executable "$BROWSER_EXECUTABLE")

if [ -n "$PROPS_JSON" ]; then
  if [ ! -f "$PROPS_JSON" ]; then
    echo "Missing props JSON: $PROPS_JSON" >&2
    exit 1
  fi
  CMD+=(--props "$PROPS_JSON")
fi

(
  cd "$PROJECT_DIR"
  "${CMD[@]}"
)

echo "Rendered 16:9 master: $OUTPUT"
