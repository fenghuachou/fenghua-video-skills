---
name: fenghua-aesthetics-library
description: >
  Shared aesthetic preference library storing HTML style references for AI-driven design tasks.
  Used by fenghua video pipeline skills (storyboard, image, cover design) to maintain consistent visual style.
  Invoke when any design-related skill needs aesthetic guidance.
---

# Fenghua Aesthetics Library

A shared, reusable aesthetic preference library. Instead of describing styles in text prompts, store them as renderable HTML files that AI can directly understand visually.

> "文字对于 AI 不是一个很好理解的东西，不如把它做出来。" — 余一

## How It Works

- Each style is a self-contained HTML file in `styles/` directory
- AI reads the HTML to understand color palette, layout, typography, and mood
- Multiple skills can reference the same style library — keeps aesthetics consistent

## Directory Structure

```
fenghua-aesthetics-library/
├── SKILL.md
├── styles/                  # HTML style reference files
│   ├── tech-blue.html       # 科技蓝：蓝色背景 + 黄色高亮
│   ├── minimalist-white.html # 极简白：白底黑字 + 灰色点缀
│   └── dark-gold.html       # 暗黑金：深色底 + 金色点缀
└── scripts/
    ├── add-style.sh         # Add a new style from URL or description
    └── list-styles.sh       # List all available styles
```

## Usage

### For other skills to reference aesthetics:

1. Read the styles directory to see available options:
   ```bash
   bash ~/.claude/skills/fenghua-aesthetics-library/scripts/list-styles.sh
   ```

2. Read a specific style HTML file to understand the visual language:
   ```
   Read ~/.claude/skills/fenghua-aesthetics-library/styles/tech-blue.html
   ```

3. Use the style as a reference when generating images, storyboards, or covers.

### To add a new style:

```bash
bash ~/.claude/skills/fenghua-aesthetics-library/scripts/add-style.sh <style-name> <source>
```

- `style-name`: kebab-case name (e.g., `warm-sunset`)
- `source`: URL to screenshot/reference, or "generate" to create from description

## Pre-loaded Styles

| Style Name | File | Description |
|-----------|------|-------------|
| tech-blue | `styles/tech-blue.html` | 蓝色科技感背景，黄色高亮，信息图式构图，适合 AI/科技类解说 |
| minimalist-white | `styles/minimalist-white.html` | 极简白底黑字，大留白，灰色辅助色，适合严肃/商业话题 |
| dark-gold | `styles/dark-gold.html` | 深色背景金色点缀，高端质感，适合深度分析/观点类内容 |

## Design Principles

1. **One HTML = One Style** — each file is a complete, self-contained visual reference
2. **Keep it simple** — 1-2 pages showing key elements (colors, typography, layout)
3. **Reusable across skills** — storyboard, image gen, cover design all read the same library
4. **Grow organically** — add styles as you discover good visual references
