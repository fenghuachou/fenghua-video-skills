---
name: fenghua-content-analyzer
description: >
  Analyze and internalize content from URLs, text, or files for the fenghua video pipeline.
  Extracts core arguments, key quotes, data points, audience profile, and suggested video angles.
  Use as the first step when creating explainer videos from articles, viewpoints, or links.
---

# Fenghua Content Analyzer

Receives raw input (article URL, plain text, uploaded file) and produces a structured content analysis JSON that feeds all downstream skills (scriptwriter, storyboard, etc.).

## Supported Input Types

| Type | Description | Method |
|------|-------------|--------|
| **URL** | Web article, blog post, news page | WebFetch (primary), browser tool (fallback for JS-rendered pages) |
| **Plain text** | Pasted text, viewpoint, idea | Direct analysis |
| **File** | Markdown (.md), text (.txt) file | Read file, then analyze |

## Workflow

1. **Detect input type** — URL, text, or file path
2. **Fetch content** (if URL):
   - Try WebFetch first
   - If content is insufficient or JS-rendered, fallback to `browser navigate` + `browser extract`
3. **Analyze content** using the structured extraction prompt (see `references/extraction-prompt.md`)
4. **Output** structured JSON to `{project_dir}/content-analysis.json`

## Output Schema

```json
{
  "title": "Article or topic title",
  "core_arguments": [
    {
      "point": "Core argument in one sentence",
      "evidence": "Supporting evidence or example",
      "weight": "primary | secondary"
    }
  ],
  "key_quotes": [
    {
      "quote": "Exact quote or paraphrase",
      "speaker": "Attribution if available",
      "usage_hint": "How this quote could be used in video"
    }
  ],
  "data_points": [
    {
      "metric": "The number or data",
      "context": "What it means",
      "visual_potential": "How to visualize this"
    }
  ],
  "target_audience": "Description of who would watch this video",
  "emotional_tone": "informative | provocative | inspirational | analytical | storytelling",
  "suggested_angles": [
    {
      "angle": "A specific perspective for the video",
      "hook": "Opening hook sentence for this angle",
      "why": "Why this angle works"
    }
  ],
  "source_summary": "2-3 sentence summary of the original content",
  "source_type": "url | text | file",
  "source_ref": "URL or filename",
  "word_count": 1500,
  "language": "zh | en"
}
```

## Usage

### As a standalone skill:

```
Analyze this article for video production: https://example.com/article
```

### Called by fenghua-video-master:

The master orchestrator passes input to this skill and receives the structured JSON.

## Content Fetch Strategy

### For URLs:
1. **WebFetch** — fast, works for most static pages
2. **Browser fallback** — if WebFetch returns insufficient content (<200 chars or error):
   ```
   browser navigate <url>
   browser extract "Extract the full article text, including title, all paragraphs, and any data/quotes"
   ```
3. Clean and normalize the extracted text

### For files:
- Read the file using the Read tool
- Detect language from content

### For plain text:
- Use directly, detect language

## Analysis Prompt

See `references/extraction-prompt.md` for the complete analysis prompt template.

## Integration

- **Output feeds into**: fenghua-scriptwriter, fenghua-storyboard-designer
- **Does not depend on**: any other fenghua skill (this is the entry point)
