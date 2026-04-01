#!/usr/bin/env bash
set -euo pipefail

# Add a new aesthetic style to the library
# Usage: add-style.sh <style-name> [source-html-file]
#
# Examples:
#   add-style.sh warm-sunset /path/to/reference.html
#   add-style.sh neon-purple                          # creates empty template

STYLES_DIR="$(cd "$(dirname "$0")/../styles" && pwd)"

if [ $# -lt 1 ]; then
  echo "Usage: $(basename "$0") <style-name> [source-html-file]"
  echo ""
  echo "  style-name:       kebab-case name (e.g., warm-sunset)"
  echo "  source-html-file: optional path to an existing HTML file to copy"
  echo ""
  echo "If no source file is provided, creates an empty template."
  exit 1
fi

STYLE_NAME="$1"
TARGET="$STYLES_DIR/${STYLE_NAME}.html"

if [ -f "$TARGET" ]; then
  echo "Error: Style '$STYLE_NAME' already exists at $TARGET" >&2
  echo "To replace it, delete the existing file first." >&2
  exit 1
fi

if [ $# -ge 2 ] && [ -f "$2" ]; then
  # Copy from source
  cp "$2" "$TARGET"
  echo "Style '$STYLE_NAME' added from $2"
else
  # Create template
  cat > "$TARGET" <<'TEMPLATE'
<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Style: STYLE_NAME_PLACEHOLDER</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif; }

  /* === PAGE 1: Storyboard Frame Reference (1920x1080) === */
  .frame {
    width: 1920px; height: 1080px;
    background: #ffffff;
    position: relative; overflow: hidden; margin: 0 auto 40px;
  }

  /* TODO: Add your style here */
  /* - Background colors/gradients */
  /* - Typography (headline, subtitle, body) */
  /* - Accent colors */
  /* - Card/block styles */
  /* - Avatar zone positioning */

  /* === PAGE 2: Color Palette === */
  .palette { max-width: 1200px; margin: 60px auto; padding: 40px; }
</style>
</head>
<body>

<!-- PAGE 1: Storyboard frame example -->
<div class="frame">
  <!-- TODO: Design your storyboard frame layout -->
</div>

<!-- PAGE 2: Color palette reference -->
<div class="palette">
  <h2>Color System</h2>
  <!-- TODO: Add color swatches and typography specs -->
</div>

</body>
</html>
TEMPLATE
  # Replace placeholder with actual name
  sed -i "s/STYLE_NAME_PLACEHOLDER/$STYLE_NAME/g" "$TARGET"
  echo "Style template '$STYLE_NAME' created at $TARGET"
  echo "Edit the file to add your visual design."
fi

echo "Path: $TARGET"
