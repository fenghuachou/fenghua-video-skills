---
name: fenghua-image-producer
description: >
  Batch-generate avatar-style storyboard images with focal content.
  Each frame features the user's cartoon avatar + embedded key-point labels/infographics.
  Uses Listenhub marswave API (primary), AI Gateway (secondary), or nano-banana-pro-openrouter (fallback).
  Supports base64 inline avatar reference for character consistency.
  Reads storyboard.json or storyboard-prompts.tsv and produces images for each frame.
  Use after fenghua-storyboard-designer, feeds into fenghua-video-assembler.
---

# Fenghua Image Producer

生成带有**个人头像 + 焦点内容**的分镜图。每帧画面中，用户的卡通头像作为讲解者出现，
画面的核心信息以黄色标签、信息图、视觉隐喻等形式直接嵌入图像中。

因为关键信息已内嵌于画面，视频合成时**无需额外叠加文字层**，避免视觉冗余。

## 核心概念：Avatar + 焦点内容

每帧分镜图由两个视觉主体组成：

```
+--------------------------------------------------+
|                                                    |
|   [焦点内容区域 ~2/3]        [头像角色 ~1/3]       |
|                                                    |
|   - 黄色标签文字                角色站位 +          |
|   - 信息图/图表                 表情/手势           |
|   - 视觉隐喻                                       |
|   - 对比/类比图                                     |
|                                                    |
+--------------------------------------------------+
```

- **头像角色**：用户提供的卡通形象，占画面约 1/3，通常站在右侧或右下角
- **焦点内容**：该帧要传达的核心信息，占画面约 2/3，以可视化元素呈现

## 焦点内容的 6 种类型

从实际项目总结出的焦点内容设计模式：

| 类型 | 描述 | 适用场景 | 提示词关键词 |
|------|------|----------|------------|
| **黄色标签** | 加粗中文关键词放在黄色标签框中 | 每帧都应有 | `Yellow label box: "关键词"` |
| **信息图** | 曲线图、柱状图、X 交叉图等 | 数据对比、趋势展示 | `infographic`, `crossing curves`, `chart` |
| **视觉隐喻** | 黑洞吸入任务卡、时钟碎裂等 | 抽象概念具象化 | `visual metaphor`, `cosmic black hole`, `disintegrating` |
| **对比/类比** | 左右分栏 before/after、A→B 箭头 | 解释概念映射 | `before/after comparison`, `arrow connects` |
| **人物互动** | 老板/名人剪影 + 动作 | 引用他人观点 | `silhouette figure`, `brain exploding with ideas` |
| **聚光灯文字** | 大号关键词 + 聚光灯效果 | 结论/金句 | `spotlight on the word "X"`, `warm light` |

## 角色站位规则

| 站位 | 适用场景 | 提示词写法 |
|------|----------|-----------|
| **右侧 1/3** | 常规帧，角色讲解 | `The character stands on the right side (1/3 of frame)` |
| **右下角（小）** | 焦点内容需要更大面积 | `The character is small in bottom-right corner` |
| **中右** | 收束/结语帧 | `The character stands center-right` |

角色表情和手势要配合该帧的情绪：

| 情绪 | 表情/手势 |
|------|----------|
| curious | `looking puzzled with a question mark above his head` |
| informative | `pointing at an infographic`, `gesturing at main content` |
| provocative | `looking alarmed with hands up` |
| warm | `looking upward with calm expression, one hand raised` |
| humorous | `looking up with wry smile` |

## Input

- `storyboard.json` — 结构化分镜，来自 fenghua-storyboard-designer
- `storyboard-prompts.tsv` — filename + prompt 对（备选输入格式）
- **Avatar URL** — 用户个人卡通头像（PNG，最好透明背景）
- **Style reference URLs** — 1-3 张已通过审核的示例帧，用于锚定视觉风格

## Output

- `storyboards/avatar-frames/scene-XX.png` — 每帧一张，最终输出 1920x1080

## 提示词架构（Prompt Architecture）

每帧提示词由 4 层组成：

```
[Layer 1: 角色锚定]
Using the cartoon character from the first reference image
(具体外貌描述，如 Asian male with glasses and olive green zip sweater)
as the main presenter, and matching the explainer video frame style
from the second and third reference images, create a new frame:

[Layer 2: 角色站位 + 表情]
The character stands on the right side (1/3 of frame), looking puzzled
with a question mark above his head.

[Layer 3: 焦点内容（画面主体）]
Left side: a digital clock disintegrating into particles floating away.
Yellow label boxes read "AI省下的时间" and "去哪了？".

[Layer 4: 背景 + 风格约束]
Background: soft blue watercolor wash. 16:9 landscape.
Cartoon illustration style, not photorealistic.
```

**Layer 1 在所有帧中完全相同**，确保角色一致性。
**Layer 4 基本相同**，仅微调背景色调（blue → dark blue 等）。
**Layer 2 和 Layer 3 是每帧的变量**，由分镜脚本决定。

### 实际项目示例

以下是「杰文斯悖论」视频 7 帧分镜的提示词摘要：

| 帧 | 角色站位 | 焦点内容 | 关键标签 |
|----|---------|---------|---------|
| scene-01 (钩子) | 右侧，困惑 | 碎裂的时钟，粒子飞散 | "AI省下的时间" "去哪了？" |
| scene-04 (痛点) | 右侧，指向 | X 形交叉曲线图（成本↓ 任务量↑） | "任务通胀" |
| scene-07 (论点) | 右下角小 | 蒸汽机 + 煤堆 + 箭头 | "效率↑" "消耗也↑？" |
| scene-10 (类比) | 右侧，手势 | 左右对比：煤炭=时间 → 蒸汽机=AI | "杰文斯悖论" |
| scene-12 (转折) | 右侧，惊恐 | 宇宙黑洞吸入任务卡片 | "任务黑洞" |
| scene-13 (金句) | 右下角小 | 老板剪影脑中爆发灵感→任务卡 | "解放的是老板的想象力" |
| scene-16 (收束) | 中右，平静 | 聚光灯照在"选择"二字上 | "选择不做什么" |

## Image Generation Chain

### Priority 1: Listenhub marswave API（推荐，唯一必需）

支持 base64 内联头像参考图，确保角色一致性。仅需 `LISTENHUB_API_KEY`。

**API 端点：** `https://api.marswave.ai/openapi/v1/images/generation`

```python
import requests, base64, json

API_KEY = os.environ["LISTENHUB_API_KEY"]
AVATAR_PATH = "path/to/avatar.png"

# 将头像编码为 base64 内联引用
with open(AVATAR_PATH, "rb") as f:
    avatar_b64 = base64.b64encode(f.read()).decode()

response = requests.post(
    "https://api.marswave.ai/openapi/v1/images/generation",
    headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}"
    },
    json={
        "model": "google/gemini-2.0-flash-exp",
        "prompt": "<4-layer-prompt>",
        "images": [f"data:image/png;base64,{avatar_b64}"],
        "n": 1,
        "size": "1024x1024",
        "response_format": "b64_json"
    }
)

result = response.json()
img_data = base64.b64decode(result["data"][0]["b64_json"])
with open("scene-01.png", "wb") as f:
    f.write(img_data)
```

**模型选择：**
- `google/gemini-2.0-flash-exp` — 实测画质好、速度快，推荐
- `google/gemini-2.5-flash-preview-04-17` — 备选

**关键特性：**
- 头像通过 `images` 数组以 `data:image/png;base64,...` 格式内联传入
- 无需外部 URL 托管头像图片

**⚠️ 头像文件必须 <1MB，否则 API 超时！**
原始头像如果较大（>1MB），必须先缩小再使用：
```bash
magick convert avatar.png -resize 500x500 fenghua-avatar-small.png  # 目标 ~300KB
```
之后用 `fenghua-avatar-small.png` 作为 base64 输入。
- 响应中 `data[0].b64_json` 为生成图片的 base64 编码
- 建议用 Python 脚本批量生成（避免 shell 中处理大 base64 字符串的问题）

### Priority 2: AI Gateway `images/generations`（可选备选）

需要 `AI_GATEWAY_API_KEY`。支持 `images` 数组传入头像 URL + 风格参考图。

```javascript
const body = {
  model: 'google/gemini-3-pro-image-preview',
  prompt: '<4-layer-prompt>',
  images: [
    '<avatar-url>',        // 个人卡通头像（需外部 URL）
    '<style-ref-1-url>',   // 已审核通过的示例帧 1
    '<style-ref-2-url>'    // 已审核通过的示例帧 2
  ],
  response_format: 'b64_json',
  n: 1,
  aspectRatio: '16:9'
};

const response = await fetch('https://ai-gateway.happycapy.ai/api/v1/images/generations', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${process.env.AI_GATEWAY_API_KEY}`
  },
  body: JSON.stringify(body)
});
```

### Priority 3: nano-banana-pro-openrouter

```bash
python3 ~/.claude/skills/nano-banana-pro-openrouter/scripts/generate_image.py \
  --prompt "<4-layer-prompt>" \
  --model google/gemini-3.1-flash-image-preview \
  --resolution 2K --output scene-01.png
```

## 完整工作流

### Step 0: 收集参考素材

1. 获取用户头像 URL（卡通形象，最好透明 PNG）
2. 获取 1-3 张风格参考图 URL（用户已审核通过的示例帧）
3. 记录角色外貌描述（如 "Asian male with glasses and olive green zip sweater"）

### Step 1: 为每帧构建 4 层提示词

从 `storyboard.json` 读取每帧的内容，按 4 层架构组装提示词：

- Layer 1: 角色锚定（固定模板，含外貌描述 + 参考图说明）
- Layer 2: 角色站位 + 表情（从分镜的 emotion 字段映射）
- Layer 3: 焦点内容（从分镜的 visual_hint + key_words 构建）
- Layer 4: 背景 + 风格约束（固定模板，微调色调）

**焦点内容构建要点：**
- 脚本中的 `key_words` → 转化为黄色标签框文字
- 脚本中的 `visual_hint` → 转化为具体视觉元素描述
- 确保每帧至少有 1 个黄色标签，最多 3 个

### Step 2: 逐帧生成图像

依次调用 AI Gateway API，传入头像 + 风格参考图 + 4 层提示词。

**逐帧串行处理**（API 有频率限制），每帧等待上一帧完成后再发起请求。

### Step 3: 后处理 -- 裁白边 + 统一尺寸

AI 生成的图像常有装饰性白边，用 ImageMagick 自动裁切：

```bash
for f in storyboards/avatar-frames/scene-*.png; do
  convert "$f" -fuzz 15% -trim +repage \
    -resize 1920x1080^ -gravity center -extent 1920x1080 \
    "$f"
done
```

- `-fuzz 15%` 处理近白色边距
- `-resize 1920x1080^` 等比缩放至覆盖目标尺寸
- `-gravity center -extent 1920x1080` 居中裁切到精确尺寸

### Step 4: 生成 manifest

记录生成结果到 `storyboards/manifest.json`。

## 批量生成脚本

以下是经过实际项目验证的 Python 批量生成脚本模板（推荐用 Python 而非 shell/JS，避免大 base64 字符串在 shell 中溢出）：

```python
#!/usr/bin/env python3
"""Batch generate storyboard frames using Listenhub marswave API."""
import os, json, base64, time, requests

API_KEY = os.environ["LISTENHUB_API_KEY"]
API_URL = "https://api.marswave.ai/openapi/v1/images/generation"
MODEL = "google/gemini-2.0-flash-exp"

# === 用户配置区 ===
AVATAR_PATH = "path/to/avatar.png"
OUTPUT_DIR = "storyboards/avatar-frames"
MAX_RETRIES = 3
RETRY_WAIT = 15  # seconds

# 角色外貌描述（所有帧共享的 Layer 1）
CHARACTER_DESC = "Asian male with glasses and olive green ribbed zip-up sweater, short black hair"
LAYER1 = f"Using the cartoon character from the reference image ({CHARACTER_DESC}) as the main presenter, create a new explainer video frame:\n"
LAYER4 = "\nBackground: soft blue watercolor wash. 16:9 landscape. Cartoon illustration style, not photorealistic."

# 将头像编码为 base64
with open(AVATAR_PATH, "rb") as f:
    AVATAR_B64 = f"data:image/png;base64,{base64.b64encode(f.read()).decode()}"

# === 分镜定义区 ===
FRAMES = [
    {
        "id": "scene-01",
        "layer2": "The character stands on the right side (1/3 of frame), looking puzzled.",
        "layer3": 'Left side: a digital clock disintegrating. Yellow label boxes read "关键词".',
    },
    # ... more frames
]

def generate_frame(frame):
    prompt = LAYER1 + frame["layer2"] + "\n" + frame["layer3"] + LAYER4
    payload = {
        "model": MODEL,
        "prompt": prompt,
        "images": [AVATAR_B64],
        "n": 1,
        "size": "1024x1024",
        "response_format": "b64_json"
    }

    for attempt in range(1, MAX_RETRIES + 1):
        print(f"[{frame['id']}] Attempt {attempt}...")
        resp = requests.post(API_URL, headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {API_KEY}"
        }, json=payload, timeout=120)

        result = resp.json()
        if "data" in result and result["data"][0].get("b64_json"):
            img = base64.b64decode(result["data"][0]["b64_json"])
            out = os.path.join(OUTPUT_DIR, f"{frame['id']}.png")
            with open(out, "wb") as f:
                f.write(img)
            print(f"[{frame['id']}] Saved ({len(img)//1024} KB)")
            return True
        else:
            print(f"[{frame['id']}] Failed: {json.dumps(result)[:200]}")
            if attempt < MAX_RETRIES:
                time.sleep(RETRY_WAIT)
    return False

os.makedirs(OUTPUT_DIR, exist_ok=True)
ok, fail = 0, 0
for frame in FRAMES:
    if generate_frame(frame):
        ok += 1
    else:
        fail += 1

print(f"\nDone: {ok} succeeded, {fail} failed out of {len(FRAMES)} frames")
```

运行方式：
- 全部：`python3 generate-all.py`
- 依赖：`pip install requests`（通常已预装）

## 视觉一致性清单

1. **每帧都传入相同的头像 + 风格参考图** -- `images` 数组内容不变
2. **Layer 1 + Layer 4 固定不变** -- 角色描述和风格约束全局共享
3. **黄色标签框** -- 每帧至少 1 个，使用中文关键词，视觉上最醒目
4. **角色占比** -- 始终约 1/3 画面，不要让角色占满整帧
5. **水彩背景** -- 统一使用 watercolor wash，仅微调色调（soft blue / dark blue / warm light）
6. **统一后处理** -- 所有帧用相同的 ImageMagick 参数裁切和缩放

## 错误处理

| 错误 | 处理 |
|------|------|
| Listenhub marswave 失败 | 检查 API key，重试 3 次（间隔 15s），再失败降级到 AI Gateway |
| AI Gateway 500 / 429 | 切换到 Flash 模型重试一次，再失败降级到 nano-banana-pro |
| 图片有白色/灰色边框 | ImageMagick `-fuzz 15% -trim` 自动裁切 |
| 角色外貌偏差 | 检查 Layer 1 描述是否完整，确认头像参考图 URL 正确 |
| 焦点内容文字缺失 | 在 Layer 3 中明确用引号写出标签文字，如 `Yellow label boxes read "关键词"` |
| 所有引擎失败 | 标记为 missing，记录日志，继续后续帧 |

## Output Manifest

```json
{
  "total_frames": 7,
  "generated": 7,
  "failed": 0,
  "avatar_url": "<avatar-url>",
  "character_desc": "Asian male with glasses and olive green zip sweater",
  "style_refs": ["<ref1>", "<ref2>"],
  "frames": [
    {
      "frame_id": "scene-01",
      "path": "storyboards/avatar-frames/scene-01.png",
      "engine": "ai-gateway",
      "focal_content": "碎裂时钟 + 黄色标签",
      "labels": ["AI省下的时间", "去哪了？"],
      "status": "ok"
    }
  ]
}
```

## Integration

- **Depends on**: fenghua-storyboard-designer (分镜 + 提示词), fenghua-aesthetics-library (风格参考)
- **Feeds into**: fenghua-quality-reviewer (图像质检), fenghua-video-assembler (最终合成)
- **Parallel with**: fenghua-voice-synthesizer (可同时进行)
- **Key rule**: 因为图像已内嵌文字标签，video-assembler 不应再叠加 overlay text 层
