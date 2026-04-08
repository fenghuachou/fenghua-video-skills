**中文 | [English](./README.md)**

# Fenghua 解说视频 Skill

一套用于 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 的模块化 Skill 流水线，可将文章、链接或原始内容转化为精致的解说短视频 —— 包含 AI 配音、分镜图、字幕和品牌化包装。

## 概览

本流水线编排 10 个专用 Skill，生产约 2 分钟的竖版解说视频，适用于视频号、抖音、YouTube Shorts 等平台。

```
文章 / 链接 / 文本
       |
       v
+----------------+     +----------------+     +------------------------+
|    内容分析     | --> |    文案撰写     | --> |      分镜设计           |
|  content-      |     |  script-       |     |  storyboard-           |
|  analyzer      |     |  writer        |     |  designer              |
+----------------+     +----------------+     +------------------------+
                                                      |
                            +-------------------------+
                            v                         v
                    +----------------+     +--------------------+
                    |    语音合成     |     |     图片生成        |
                    |  voice-        |     |  image-            |
                    |  synthesizer   |     |  producer          |
                    +-------+--------+     +-------+------------+
                            |                      |
                            |    +-----------------+
                            |    v
                            |  +----------------+
                            |  |    质量审核     |
                            |  |  quality-      |
                            |  |  reviewer      |
                            |  +-------+--------+
                            |          |
                            v          v
                    +------------------------+
                    |      视频合成           |
                    |  video-assembler       |
                    |  (Remotion + ffmpeg)   |
                    +-----------+------------+
                                |
                                v
                      最终视频输出
                      +-- 16:9 横版母带
                      +-- 3:4 竖版（含字幕）
                      +-- 封面图 + 社交文案
```

## Skill 列表

| Skill | 说明 |
|-------|------|
| **fenghua-video-master** | 端到端编排器 —— 给它一篇文章，自动协调所有其他 Skill |
| **fenghua-content-analyzer** | 从文章/链接/文本中提取核心论点、关键引述、数据点 |
| **fenghua-scriptwriter** | 生成播音级解说文案（钩子 -> 痛点 -> 论点 -> 转折 -> 收束） |
| **fenghua-storyboard-designer** | 将文案转化为逐帧分镜方案，含图片生成提示词 |
| **fenghua-image-producer** | 通过 Listenhub marswave API 批量生成带头像的分镜图 |
| **fenghua-voice-synthesizer** | TTS 语音合成，支持声音克隆，基于 Listenhub |
| **fenghua-quality-reviewer** | 对生成图片的自动质检（缺陷检测、风格一致性） |
| **fenghua-video-assembler** | Remotion + ffmpeg 合成：Ken Burns 缩放、交叉淡入、1.1 倍速、3:4 包装、字幕烧录 |
| **fenghua-aesthetics-library** | 共享视觉风格库（HTML 模板定义配色和布局） |
| **fenghua-explainer-video-portable** | 基于环境变量的可移植版本，方便跨机器使用 |

## 环境要求

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Node.js 18+ 和 npm
- Python 3.10+，需安装 Pillow（`pip install Pillow`）
- ffmpeg（macOS 上通过 Homebrew 安装：`brew install ffmpeg`）
- ImageMagick（`brew install imagemagick`）
- [Listenhub](https://listenhub.ai) API Key（用于 TTS 语音合成和图片生成）

## 安装

本仓库已打包为 **Claude Code Plugin**。在 Claude Code 中一行命令安装：

```
/plugin install https://github.com/fenghuachou/fenghua-video-skills
```

安装过程中会提示你输入 `LISTENHUB_API_KEY`。

### 手动安装（备选）

```bash
git clone https://github.com/fenghuachou/fenghua-video-skills.git ~/.claude/plugins/fenghua-video
echo 'export LISTENHUB_API_KEY="your-key-here"' >> ~/.zshrc
source ~/.zshrc
```

### 可选 —— 增强 TTS 助手

```bash
npx skills add marswaveai/skills
```

## 快速开始

在 Claude Code 中输入：

```
/fenghua-video:fenghua-video-master

请根据以下链接创作一条解说短视频：https://example.com/article
```

Master Skill 会自动执行以下流程：
1. 分析文章内容
2. 生成解说文案（等待你确认）
3. 设计分镜方案（等待你确认）
4. 并行生成 TTS 音频 + 分镜图片
5. 图片质量审核
6. 使用 Remotion 合成视频
7. 包装为 3:4 竖版并烧录字幕
8. 生成封面图和社交平台文案

## 输出文件

```
outputs/
+-- video-16x9.mp4          # 16:9 横版母带 (1920x1080)
+-- video-16x9-1.1x.mp4     # 1.1 倍速版本
+-- video-3x4.mp4           # 3:4 竖版，含烧录字幕 (1080x1440)
+-- video-3x4-nosub.mp4     # 3:4 竖版，无字幕
+-- cover.png               # 3:4 封面图
+-- social-copy.txt         # 社交平台视频介绍文案
```

## 自定义

### 头像

使用时提供你的卡通头像（PNG 格式，最好是透明背景）。图片生成器会将头像编码为 base64，在每帧生成请求中引用，确保角色一致性。

### 视觉风格

编辑 `fenghua-aesthetics-library/styles/` 中的 HTML 模板可以新增或修改视觉风格。分镜设计和图片生成会参照这些模板保持视觉一致性。

### 文案结构

文案撰写遵循 5 段式模型：
1. **钩子** (Hook) —— 吸引注意力的开场提问
2. **痛点** (Pain Point) —— 引发共鸣的问题描述
3. **论点** (Arguments x3) —— 核心观点 + 论据支撑
4. **转折** (Twist) —— 出人意料的视角切换
5. **收束** (Closing) —— 令人记住的金句收尾

### 字幕设置

字幕会被预拆分为单行显示（每行最多 25 个中文字符），在 3:4 画面中定位于 y=880（视频底部与 Logo 区域之间）。

两种字幕烧录方式：
- **ffmpeg ASS 滤镜** —— 需要 ffmpeg 编译时包含 libass
- **Python + Pillow** —— macOS Homebrew 版 ffmpeg 的备选方案（Mac 上的默认方式）

## 环境变量

| 变量 | 必需 | 说明 |
|------|------|------|
| `LISTENHUB_API_KEY` | 是 | Listenhub / marswave API Key，用于 TTS 和图片生成 |
| `AI_GATEWAY_API_KEY` | 否 | 可选，AI Gateway 图片生成备选 |
| `OPENROUTER_API_KEY` | 否 | 可选，OpenRouter 额外模型访问 |

## 架构说明

- **图片生成** 采用 4 层提示词架构：角色锚定 -> 站位/表情 -> 焦点内容 -> 背景/风格
- **焦点内容类型**：黄色标签框、信息图、视觉隐喻、前后对比、人物互动、聚光灯文字
- **视频合成流程**：Remotion 渲染 16:9 -> ffmpeg 1.1 倍速 -> 叠加到 3:4 背景 -> 烧录字幕
- **字幕流水线**：TTS 生成 SRT -> 调整 1.1 倍速时间轴 -> 拆分为 <=25 字短句 -> Pillow/ASS 烧录

## 许可证

MIT
