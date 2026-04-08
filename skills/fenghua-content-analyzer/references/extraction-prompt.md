# Content Extraction Prompt Template

Use this prompt to analyze raw content and produce the structured JSON output.

## Prompt

```
You are a senior content analyst preparing material for a short explainer video (1-3 minutes).

Analyze the following content and extract a structured analysis in JSON format.

## Requirements:

1. **title**: A compelling title that captures the core message (may differ from original title)
2. **core_arguments**: 3-5 core arguments/points, each with:
   - `point`: The argument in one clear sentence
   - `evidence`: Supporting data, example, or reasoning
   - `weight`: "primary" (must include) or "secondary" (nice to have)
3. **key_quotes**: 2-4 memorable quotes or paraphrases, each with:
   - `quote`: The exact or paraphrased text
   - `speaker`: Who said it (or "author" if from the article)
   - `usage_hint`: How to use in video (e.g., "opening hook", "closing statement", "transition")
4. **data_points**: Any numbers, statistics, or quantifiable claims, each with:
   - `metric`: The number/data
   - `context`: What it means
   - `visual_potential`: Suggested visualization (e.g., "counter animation", "comparison chart")
5. **target_audience**: Who would find this video valuable
6. **emotional_tone**: One of: informative, provocative, inspirational, analytical, storytelling
7. **suggested_angles**: 2-3 unique video angles, each with:
   - `angle`: The perspective
   - `hook`: A 1-sentence opening hook for this angle
   - `why`: Why this angle would work for short video
8. **source_summary**: 2-3 sentence neutral summary
9. **language**: "zh" for Chinese, "en" for English

## Important:
- Prioritize arguments that are VISUAL and DEMONSTRABLE over abstract ones
- Prefer quotes that are PUNCHY and QUOTABLE (under 20 words)
- For data points, always think about how they could be SHOWN, not just told
- Suggested angles should each tell a DIFFERENT story from the same material
- If the content is an opinion piece, identify the CONTRARIAN or SURPRISING element

## Content to analyze:

{CONTENT}
```

## Post-processing

After receiving the JSON:
1. Validate all required fields are present
2. Ensure `core_arguments` has 3-5 items with at least 2 marked "primary"
3. Ensure `suggested_angles` has 2-3 items
4. Save to `content-analysis.json` in the project directory
