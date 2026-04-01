# Fenghua portable pipeline reference

## Setup checklist on a new machine

Install or verify:

1. `ffmpeg`
2. `node`, `npm`, `npx`
3. `uv` or `python3`
4. Google Chrome, Chromium, or another Chromium-based browser usable by Remotion
5. optional: `listenhub` skill for TTS
6. optional: `nano-banana-pro-openrouter` skill for storyboard generation

## Environment variables

### Required when using external services

- `LISTENHUB_API_KEY`
- `OPENROUTER_API_KEY`

### Recommended overrides

- `REMOTION_BROWSER_EXECUTABLE`
  - explicit browser path for Remotion rendering
- `FENGHUA_IMAGE_GENERATOR_SCRIPT`
  - full path to `generate_image.py`
- `FENGHUA_IMAGE_RUNNER`
  - command used to run the image generator script, for example `uv run` or `python3`

## Bundled script reference

### init_fenghua_project.sh

Usage:

```bash
scripts/init_fenghua_project.sh <project_root> [project_slug]
```

Creates:

- `assets/avatar`
- `assets/backgrounds`
- `audio`
- `subtitles`
- `storyboards/raw`
- `storyboards/final`
- `outputs`
- `notes`
- `script.txt`
- `notes/scene-plan.md`
- `notes/storyboard-prompts.tsv`
- `notes/storyboard-common-prompt.txt`
- `notes/output-checklist.md`

### generate_storyboard_batch.sh

Usage:

```bash
scripts/generate_storyboard_batch.sh <scene_file.tsv> <output_dir> <avatar_ref> <style_ref_csv> [model] [resolution] [generator_script] [common_prompt_file]
```

Notes:

1. `style_ref_csv` is a comma-separated list of local image paths
2. lines beginning with `#` in the TSV are ignored
3. if `generator_script` is omitted, the script will try:
   - `FENGHUA_IMAGE_GENERATOR_SCRIPT`
   - `~/.agents/skills/nano-banana-pro-openrouter/scripts/generate_image.py`
4. if `FENGHUA_IMAGE_RUNNER` is unset, the script uses `uv run` when `uv` exists, otherwise `python3`

### render_16x9_master.sh

Usage:

```bash
scripts/render_16x9_master.sh <remotion_project_dir> <output.mp4> [composition_id] [props_json] [browser_executable]
```

Browser detection order:

1. explicit fifth argument
2. `REMOTION_BROWSER_EXECUTABLE`
3. macOS app paths for Chrome, Chromium, Brave
4. Linux commands: `google-chrome`, `chromium-browser`, `chromium`, `brave-browser`

Notes:

1. defaults composition to `HowOneAILongVideo`
2. uses the project's local `node_modules/.bin/remotion` when present
3. otherwise falls back to `npx remotion`
4. errors early if no usable browser is found

### package_3x4_bg_centered.sh

Usage:

```bash
scripts/package_3x4_bg_centered.sh <input_master.mp4> <background.png> <output.mp4> [video_width]
```

### package_3x4_bg_top.sh

Usage:

```bash
scripts/package_3x4_bg_top.sh <input_master.mp4> <background.png> <output.mp4> [top_offset] [video_width]
```

## Recommended naming convention

1. script: `script.txt`
2. audio: `audio/topic-fenghua.mp3`
3. subtitles: `subtitles/topic-fenghua.srt`
4. prompts: `notes/storyboard-prompts.tsv`
5. storyboards: `storyboards/final/*.png`
6. 16:9 master: `outputs/topic-16x9-clean.mp4`
7. 3:4 publish: `outputs/topic-3x4-bg-centered.mp4`

## Migration rule

Only move the skill folder after checking that the target machine also has:

1. the external APIs configured
2. the required CLI tools installed
3. the image-generation and TTS helper skills installed if you depend on them
