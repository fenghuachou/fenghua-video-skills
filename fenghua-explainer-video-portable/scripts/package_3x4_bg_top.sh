#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 3 ] || [ "$#" -gt 5 ]; then
  echo "Usage: $0 <input_master.mp4> <background.png> <output.mp4> [top_offset] [video_width]" >&2
  exit 1
fi

INPUT_MASTER="$1"
BACKGROUND="$2"
OUTPUT="$3"
TOP_OFFSET="${4:-164}"
VIDEO_WIDTH="${5:-1000}"

for path in "$INPUT_MASTER" "$BACKGROUND"; do
  if [ ! -f "$path" ]; then
    echo "Missing file: $path" >&2
    exit 1
  fi
done

FPS=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$INPUT_MASTER" | awk -F/ '{if ($2 == 0 || $2 == "") print 30; else printf "%.6f", $1 / $2}')
[ -n "$FPS" ] || FPS="30"

ffmpeg -y \
  -stream_loop -1 -framerate "$FPS" -i "$BACKGROUND" \
  -i "$INPUT_MASTER" \
  -filter_complex "[1:v]scale=${VIDEO_WIDTH}:-2[fg];[0:v]fps=${FPS}[bg];[bg][fg]overlay=(W-w)/2:${TOP_OFFSET}:shortest=1,format=yuv420p[v]" \
  -map "[v]" -map 1:a? \
  -c:v libx264 -preset medium -crf 20 \
  -c:a copy \
  -shortest \
  "$OUTPUT"
