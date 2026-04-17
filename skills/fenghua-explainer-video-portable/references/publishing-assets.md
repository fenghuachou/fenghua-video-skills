# Publishing Assets — 基本节点 10 & 11

视频渲染完成后必须生成的两项发布配套资产。这两步是主流程的一级节点，不可省略。

---

## Node 10: 视频号介绍文本 → `outputs/intro-text.md`

### 文件结构（固定三段）

```markdown
# 视频标题

## 短版（30 字以内）
<一句话钩子，数字 + 悬念 + 核心关键词>

## 长版（200-300 字）
<开头 1-2 句钩子（冲突 / 反常识 / 数字）>

<中段 3-5 条要点列表（核心结论或金句）>
- 要点 1
- 要点 2
- 要点 3

<结尾 1 句 CTA（点赞 / 关注 / 留言）>

## 话题标签
#标签1 #标签2 #标签3 #标签4 #标签5
```

### 撰写原则

1. **标题句用选定的 video title**（Checkpoint 2 确认版本）
2. **金句直接从脚本提取**，不要重写
3. **短版是首屏展示区**（视频号默认只展开到第一行），必须包含数字或冲突
4. **长版可用 1-2 个 emoji 做视觉锚点**，克制使用
5. **话题标签 5-8 个**，覆盖三个维度：
   - 核心主题（#AI转型 #企业AI #增长策略）
   - 目标人群（#管理者 #创业者 #数字游民）
   - 内容类型（#案例拆解 #认知升级 #深度思考）
6. **不要用**：标题党、夸张、绝对化词汇（"震惊"、"必看"、"史上最"）

### 起稿来源

- `script.json` 的 `social_caption` 字段（若有）
- `script.json` 的 `hashtags` 字段（若有）
- 脚本里的金句（通常在开头钩子段和结尾升华段）

---

## Node 11: 3:4 视频号封面图 → `outputs/cover-3x4.png`

### 生成脚本模板

```python
#!/usr/bin/env python3
"""Generate 3:4 cover image for 视频号 (WeChat Channels)."""
import os, base64, requests

API_KEY = os.environ.get("LISTENHUB_API_KEY")
PROJ = os.path.dirname(os.path.abspath(__file__))

with open(f"{PROJ}/assets/avatar/fenghua-avatar-small.png", "rb") as f:
    avatar_b64 = base64.b64encode(f.read()).decode()

PROMPT = """Create a bold, eye-catching Chinese short-video cover thumbnail in 3:4 portrait
aspect ratio, cinematic editorial illustration style, high-contrast and instantly readable
on mobile.

Layer 1 (TOP - main title, largest element): Massive bold Chinese title text arranged in
two stacked lines:
  Line 1 (larger): "<主标题第一行>"
  Line 2 (slightly smaller, with yellow highlight underline): "<主标题第二行>"
  Typography: thick sans-serif, white text with strong black outline or drop shadow,
  extremely prominent. Key number/percentage should be in bright yellow for emphasis.

Layer 2 (MIDDLE): A dramatic editorial infographic element — <对应视频核心视觉：数据卡片 /
对比图 / 关键符号 / 泄露文档等>. <颜色调性> color palette with accent colors.

Layer 3 (BOTTOM-RIGHT): An Asian male presenter character (glasses, olive green zip sweater,
warm confident expression). The character must match the reference avatar exactly. Position
him in the bottom-right corner, occupying about 30% of the frame width, gesturing toward
the main visual element.

Layer 4 (BOTTOM-LEFT small tag): A small yellow label "<副标签 4-6 字>" in Chinese.

Background: <深色 / 浅色> gradient with subtle <纹理>. No video UI, no bottom banner.
Strict 3:4 portrait aspect ratio. Mobile-optimized — all text must be readable at small
size."""

payload = {
    "provider": "google",
    "model": "gemini-3-pro-image-preview",
    "prompt": PROMPT,
    "imageConfig": {"imageSize": "2K", "aspectRatio": "3:4"},
    "referenceImages": [
        {"inlineData": {"mimeType": "image/png", "data": avatar_b64}}
    ]
}

print("→ Generating 3:4 cover...")
r = requests.post(
    "https://api.marswave.ai/openapi/v1/images/generation",
    headers={"Authorization": f"Bearer {API_KEY}",
             "Content-Type": "application/json",
             "X-Source": "skills"},
    json=payload, timeout=600
)
d = r.json()
try:
    b64 = d["candidates"][0]["content"]["parts"][0]["inlineData"]["data"]
except Exception:
    print("ERROR:", d)
    raise SystemExit(1)

out = f"{PROJ}/outputs/cover-3x4.png"
with open(out, "wb") as f:
    f.write(base64.b64decode(b64))
print(f"✅ Saved → {out} ({len(b64)//1024} KB b64)")
```

### Prompt 四层结构（必须完整）

| Layer | 位置 | 内容 | 关键规格 |
|-------|------|------|---------|
| 1 | TOP | 两行大标题 | thick sans-serif，white + black outline，核心数字用亮黄色 |
| 2 | MIDDLE | 视觉信息元素 | 数据卡片 / 对比图 / 关键符号；匹配视频主题 |
| 3 | BOTTOM-RIGHT | Fenghua 头像 | glasses, olive green zip sweater，占画面 ~30% 宽，`referenceImages` 必传 |
| 4 | BOTTOM-LEFT | 副标签 | 4-6 字黄色小 tag（如「AI 转型真相」「认知升级」）|

### API 参数要点

| 字段 | 值 | 说明 |
|------|-----|------|
| `provider` | `"google"` | |
| `model` | `"gemini-3-pro-image-preview"` | |
| `imageConfig.imageSize` | `"2K"` | |
| `imageConfig.aspectRatio` | `"3:4"` | **必须，否则生成比例错误** |
| `referenceImages[0].inlineData.data` | avatar base64 | **必须，保证人物一致性** |
| `referenceImages[0].inlineData.mimeType` | `"image/png"` | |

### 响应解析

```python
b64 = response["candidates"][0]["content"]["parts"][0]["inlineData"]["data"]
```

### 常见问题

1. **头像 >1MB 会超时**：生成前用 `magick convert avatar.png -resize 500x500 avatar-small.png` 压到 ~300KB
2. **忘记 referenceImages**：人物会变脸，必须传头像
3. **忘记 aspectRatio: "3:4"**：会回退到默认 16:9
4. **底部被视频号 UI 遮挡**：关键视觉元素避免放在最底部 100px 区域

### 设计要求检查清单

- [ ] 严格 3:4 portrait（1080x1440 或 2K 等比）
- [ ] 手机端小图仍清晰可读（主标题占高 20% 以上）
- [ ] 避免视频 UI / 底部横条（视频号会叠加）
- [ ] 配色匹配视频整体 style（tech-blue / minimalist-white / dark-gold）
- [ ] 头像 reference 有效传入（检查 base64 不为空）

### 真实案例

参见 `/Users/fenghua/Library/Mobile Documents/com~apple~CloudDocs/Claude/Fenghua 解说视频/project-ramp-ai-culture/ramp-ai-culture/generate-cover.py` — Ramp AI 文化视频的封面生成脚本（已验证可用）。
