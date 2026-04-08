#!/usr/bin/env bash
set -euo pipefail

# List all available aesthetic styles in the library
STYLES_DIR="$(cd "$(dirname "$0")/../styles" && pwd)"

if [ ! -d "$STYLES_DIR" ]; then
  echo "Error: Styles directory not found at $STYLES_DIR" >&2
  exit 1
fi

echo "=== Fenghua Aesthetics Library ==="
echo "Directory: $STYLES_DIR"
echo ""

count=0
for f in "$STYLES_DIR"/*.html; do
  [ -f "$f" ] || continue
  count=$((count + 1))
  name=$(basename "$f" .html)
  # Extract title from HTML
  title=$(grep -oP '(?<=<title>).*?(?=</title>)' "$f" 2>/dev/null || echo "$name")
  size=$(wc -c < "$f" | tr -d ' ')
  echo "  [$count] $name"
  echo "       Title: $title"
  echo "       Size:  ${size} bytes"
  echo "       Path:  $f"
  echo ""
done

if [ $count -eq 0 ]; then
  echo "  (No styles found. Use add-style.sh to add one.)"
fi

echo "Total: $count style(s)"
