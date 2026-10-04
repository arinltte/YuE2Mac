<p align="center">
  <img src="img/logo.png" alt="YuE2Mac 标志" width="64" />
  <br />
  <h1 align="center">YuE2Mac</h1>
  <p align="center">本地 AI 作曲工坊（适用于 Apple Silicon）—— 歌词 + 风格 → 一首完整的歌曲。</p>
  <p align="center">
    <a href="https://github.com/arinltte/YuE2Mac/releases/latest"><img src="https://img.shields.io/github/v/release/arinltte/YuE2Mac?style=flat-square&color=blue" alt="最新版本" /></a>
    <a href="https://github.com/arinltte/YuE2Mac/blob/main/LICENSE.txt"><img src="https://img.shields.io/github/license/arinltte/YuE2Mac?style=flat-square&color=green" alt="许可证" /></a>
    <img src="https://img.shields.io/badge/macOS-14.0%2B-blue?style=flat-square" alt="macOS" />
    <img src="https://img.shields.io/badge/100%25-本地离线-brightgreen?style=flat-square" alt="离线" />
  </p>
</p>

<p align="center">
  <a href="./README.md">English</a> | <a href="./README-ZH.md">中文文档</a>
</p>

## 简介

YuE2Mac 是一款原生 macOS 桌面应用，把开源 [**YuE2**](https://github.com/multimodal-art-projection/YuE) 音乐生成模型（已移植到 **Apple MLX**）带到你的 Apple Silicon Mac 上。输入歌词、选择风格，应用会自动规划编曲、谱写旋律、打磨音色，并渲染出完整的 **48 kHz 立体声歌曲** —— 完全离线运行。

借助在 Apple GPU 上以 8-bit 运行的 YuE2（Mixture-of-Transformers 模型），YuE2Mac **无需联网、无需 API key，所有数据都不离开你的电脑**。你的歌词和歌曲始终留在你的 Mac 上。

> **原始模型与研究：** [YuE 项目主页](https://map-yue2.github.io) · [YuE GitHub](https://github.com/multimodal-art-projection/YuE) · [MERT](https://arxiv.org/abs/2306.00107)

## 🆕 v0.1.2 新增内容

整个工坊围绕两种模式重构，并落地了[生态分析](./ECOSYSTEM_ANALYSIS.md)中的 Tier-1 特性：

*   **两种模式** —— *Lite*（两步操作 + 一个大按钮）与 *Pro*（完整录音棚），工具栏一键切换；你的内容在两种模式间无缝保留。
*   **队列** —— 想排多少首就排多少首；同一时间只渲染一首，并带有实时阶段芯片（Load → Plan → Compose → Refine → Render → Save）与 tokens/s 速度显示。
*   **草稿 → 精修** —— 先用 8 步快速出小样，再按 **Finish at full quality** 以 32 步重渲染**同一版本**（复用已保存的 tokens + 种子）。
*   **歌曲库** —— 每首歌保存到独立的时间戳文件夹，含乐谱、种子与设置；支持搜索、重播、导出 M4A、生成新变体或删除。
*   **ABC 乐谱工坊** —— 编辑 YuE2 为你规划的乐谱、校验修改、把人声改写为纯音乐（官方配方）、用相同种子重新渲染。
*   **高级采样** —— 温度、top-p、top-k、重复惩罚，一键恢复默认。
*   **AI 写词** —— 在支持 Apple Intelligence 的 Mac（macOS 26+）上通过 Apple FoundationModels 在本地起草歌词。不下载模型、不联网。
*   **风格目录** —— 约 40 个分类风格起始（Lite 芯片 / Pro 浏览器），外加“给我惊喜”。
*   **处处有说明** —— 每个控件都会自我解释：悬停 ❓ 显示提示，点击弹出说明卡片。

## ✨ 主要特性

*   🎚 **两种模式，一键切换：** 工具栏开关在 **Lite**（两步操作、一个大按钮——第一首歌的最佳入口）与 **Pro**（队列、采样控制、乐谱编辑、歌曲库工具）之间切换整个工坊。你的内容随你一起切换。
*   🌸 **歌词 + 风格 → 歌曲：** 自己写词或载入内置歌词集，描述音色，就能得到一首完整的歌。在支持 Apple Intelligence 的 Mac（macOS 26+）上，**Write with AI** 按钮会在本地起草一整张歌词——任何数据都不离开你的 Mac。
*   🎛 **风格目录：** 精选的分类风格起始库（Lite 中是芯片，Pro 中是浏览器）—— 从波萨诺瓦到合成器浪潮，还有“给我惊喜”。
*   🌹 **草稿 → 精修：** 生成一个 8 步的快速预览，然后按 **Finish at full quality** —— 它会复用同一个版本（保存的 song tokens + 种子），仅以 32 步做更精细的打磨。
*   📚 **歌曲库：** 每首歌保存到独立的时间戳文件夹，含种子、设置与乐谱。可搜索、重播、导出 **M4A**、生成**新变体**或删除——旧版的散装 `.wav` 文件也会被列出。
*   ⏳ **队列：** 想排多少首排多少首；同一时间渲染一首，带实时阶段芯片（Load → Plan → Compose → Refine → Render → Save）与 tokens/s 读数。排队中的任务可立即取消；停止的任务会被如实标注。
*   🎼 **ABC 乐谱工坊：** YuE2 写出的乐谱会保存在每首歌旁。可以编辑它、校验它、**把歌改成纯音乐**（官方 Vocal→Ins 配方）、或用相同种子重新渲染——全部在应用内完成。
*   🧠 **模型版本选择：** 安装器根据你的 Mac 内存与规格预选一个模型（**8-bit / 4-bit / bf16**），并且只下载这一个。
*   🪗 **编曲规划（COT）：** *Full* 生成带和弦标记的乐谱，*Melody only* 只写旋律大纲，*Off* 直接生成声音（最快）。
*   🎚 **高级采样（Pro）：** 温度、top-p、top-k 与重复惩罚——与引擎生成配置一一对应，一键恢复默认。
*   🎹 **纯音乐模式：** 一个开关注入 *instrumental, no vocals* 并把歌词精简为结构标签——驯服模型的人声偏好。在 Pro 中，乐谱编辑器还能改用更稳健的 Vocal→Ins 乐谱改写。
*   ❓ **帮助图标：** 每个控件都有说明图标（悬停显示提示，点击弹出说明卡片）。
*   🎨 **氛围主题：** Studio / Stage / Vinyl —— 带动画的氛围背景，并随界面自动适配。
*   ⚡ **智能内存管理：** 引擎以子进程方式运行，歌曲结束的瞬间即从内存卸载，保持你的 Mac 流畅。
*   📦 **自包含、一键安装：** 按一个按钮，即可从 Hugging Face 下载引擎 + 模型、建立私有 Python 环境，并全部安装到应用自己的文件夹——你无需挑选任何文件或文件夹。

## ⚙️ 系统要求

应用会自行搭建并安装所需的 Python 环境与依赖。在此之前你需要：

*   **macOS 14.0（Sonoma）** 或更高版本。
*   **Apple Silicon（M1/M2/M3/M4/M4 Pro…）** 芯片的 Mac。
*   **[Homebrew](https://brew.sh/)：** 用于提供引导应用私有虚拟环境的 Python ABI。（若缺失，设置界面会给出具体安装命令。）
*   **网络连接：** 仅首次启动需要，用来一次性下载引擎代码、mlx / numpy / tiktoken 依赖包与模型权重。之后便完全离线运行。

## 📥 安装说明

1.  编译并运行（见[编译与运行](#编译与运行)），或从 [Releases 页面](https://github.com/arinltte/YuE2Mac/releases/latest)下载现成的 `.app`。
2.  首次启动时，**设置界面**会显示你的 Mac 配置（芯片 + 内存），并预选一个**模型版本**：
    *   **8-bit** —— 质量与体积的最佳平衡，推荐 16 GB 及以上内存。
    *   **4-bit** —— 体积最小，更适合 8–12 GB 内存的 Mac。
    *   **bf16** —— 还原度最高，需要 28 GB 以上内存。
3.  点击 **Download & Install**——仅此一步即可。YuE2Mac 会自动完成：
    *   建立私有 Python 虚拟环境（`~/Library/Application Support/YuE2Mac/Python`）并安装 `mlx`、`numpy`、`tiktoken`；
    *   从 Hugging Face 下载 YuE2 引擎代码与所选模型权重（`Models/<variant>/`）；
    *   校验一切就绪，然后直接进入作曲界面。
4.  完成。之后便是完全离线运行。

> **首次下载大小：** 引擎代码很小，但模型权重较大——默认 8-bit 模型约 **4.2 GB**（4-bit 约 3.4 GB，bf16 约 7 GB）。仅需下载一次。

> **关于未公证说明：** 与许多本地大模型工具类似，首次打开可能会被 Gatekeeper 拦截。可运行：
> `xattr -rd com.apple.quarantine /Applications/YuE2Mac.app`

## 🚀 快速上手

顶部的工具栏开关选择你的模式：

*   **Lite** —— 从芯片中挑一个氛围（或让 **Surprise me** 替你选），写歌词（在支持的 Mac 上按 **Write with AI**），然后点大大的 **Generate Song**。可选打开 **Quick preview**，先出一份之后可以*精修*的快速草稿。
*   **Pro** —— 以上全部，外加：一次**排队**多首歌（逐首渲染，各带实时阶段芯片）、**模型/规划**选择器、**质量**（步数 + 草稿开关）、**高级采样**（温度 / top-p / top-k / 重复惩罚）、**歌曲长度**与**种子**输入框。

生成后，每首歌都住在**歌曲库**里自己的文件夹中（`Output/<日期> <标题>/`），含 WAV、ABC 乐谱、保存的 song project，以及记录设置的 `song.json`。从结果面板或歌曲库，你可以**重播**、**把草稿精修到全质量**（同一版本、32 步）、**编辑 ABC 乐谱并重渲染**、**生成新变体**、**导出 M4A** 或**删除**。

## 🧠 功能说明

*   **草稿 → 精修：** *Quick preview* 以 8 步渲染（约快 4 倍）。该版本的语义 tokens 与种子会被保存，因此 **Finish at full quality** 重渲染的是**同一**作品（32 步）——不重新作曲、不出意外。
*   **队列：** 歌曲逐首渲染；排队中的任务可立即取消，运行中的任务在下一步停止，并被如实标注为 *Stopped*（绝不标成 *Failed*）。
*   **风格目录：** 精选的约 40 个分类起始风格（Lite 中是芯片，Pro 中是完整浏览器）——不调用 AI，只提供灵感。
*   **AI 写词（macOS 26+ 且具备 Apple Intelligence）：** 通过 Apple 的 **FoundationModels** 在本地起草结构化歌词——它是 macOS 自带的系统模型（Apple Intelligence 的一部分）。**不下载任何模型、不使用网络**——它与歌曲引擎不同，歌曲引擎才需要从 Hugging Face 一次性下载。每个段落（主歌/副歌/桥段/尾声）都有各自的 guide 生成，避免小型本地模型把段落混在一起或反复重复同一个 hook。不支持的 Mac 上会自动隐藏该按钮。
*   **帮助图标（❓）：** 每个滑块/开关在悬停时显示提示，点击时弹出简短的说明卡片。
*   **Samples（歌词）：** 载入现成的歌词集，其中包含一份 **Instrumental only**（纯音乐）模板。
*   **纯音乐：** 向提示词注入 `instrumental, no vocals`，并仅保留歌词中的结构标签。在 Pro 中，乐谱编辑器还能直接改写 ABC（Vocal → Ins）——这是官方最稳健的 YuE 配方。
*   **乐谱编辑（Pro）：** 每首经过规划的歌曲都会保存 ABC 乐谱。编辑器会校验你的修改（音符/小节/声部），在结构大幅变化时给出警告，并可用相同种子（或新种子）重新渲染。
*   **规划（COT）：** *Full* = 规划和弦+旋律；*Melody only* = 旋律大纲；*Off* = 直接生成声音（最快，但可能失去节拍）。
*   **CFG：** 模型对你风格提示的服从程度。越高越听话，可能也越缺少创造性。
*   **采样（Pro）：** 温度（狂野程度）、top-p/top-k（候选截断）、重复惩罚（防止模型复现记忆中的歌曲）。默认值与引擎自身的配置一致。
*   **种子（Seed）：** 同样的歌词与种子 = 同样的歌曲。留空则随机生成。

## 🔬 实测生成结果（M4 · 16 GB · 8-bit）

在 **M4 MacBook Pro、16 GB 内存**、使用 **8-bit** 引擎、输入如下内容完成了一次真实基准测试：

> **风格：** `English, soft rock, 70s feel, smooth bass, electric piano, brushed drums`

> **歌词：**
> ```
> [Verse]
> I took my time, I took the slow lane
> Learned to love the quiet rain
>
> [Chorus]
> I bloomed when nobody was watching
> Good things come late, and that's okay
>
> [Verse]
> All my once-upons grew roots at last
> I stopped replaying failed takes from the past
>
> [Chorus]
> I bloomed when nobody was watching
> Good things come late, and that's okay
> ```

| 指标 | 结果 |
| :--- | :--- |
| 模型 | YuE2-3B，8-bit MLX |
| 生成期间内存占用 | **约 11.4 GB**（系统共 16 GB） |
| 设备 | Apple M4 · 16 GB 统一内存 |
| 输出 | 48 kHz 立体声 WAV |

由于引擎作为独立的子进程运行，约 11.4 GB 内存会在歌曲**结束的瞬间被全部释放**——不会有任何内容残留在内存中，因此你的 Mac 在生成结束后不会继续卡顿、发热。

## 🔒 数据与隐私

所有生成都在本地 GPU 上进行。无遥测、无云端 API。AI 写词也完全在本地完成（Apple Intelligence 系统模型）。

| 位置 | 内容 |
| :--- | :--- |
| `~/Library/Application Support/YuE2Mac/Python` | 隔离的 Python 虚拟环境 + pip 包（mlx、numpy、tiktoken）。 |
| `~/Library/Application Support/YuE2Mac/Scripts` | `generate.py` 与模型模块（从 Hugging Face 下载），外加应用自带的 `yue2_pro.py` 扩展（草稿/精修、采样、保存的 song project）。 |
| `~/Library/Application Support/YuE2Mac/Models` | 所选模型权重（8-bit/4-bit/bf16，从 Hugging Face 下载）。 |
| `~/Library/Application Support/YuE2Mac/Output` | 你的歌曲——每首一个时间戳文件夹（`song.wav`、`song.abc`、`song.tokens.json`、`song.json`）。 |

## 卸载

```bash
rm -rf /Applications/YuE2Mac.app
rm -rf ~/Library/Application\ Support/YuE2Mac
```

## 编译与运行

```bash
open YuE2Mac.xcodeproj        # 在 Xcode 中点击 Run

# 或直接编译并启动（不带 Xcode 调试器，占用内存更低）：
bash scripts/run_app.sh
```

## 🤝 参与贡献

欢迎一切贡献。方式：Fork 本仓库 → 新建分支 → 清晰提交 → 提交 Pull Request。若反馈 Bug 或功能建议，请到 [Issues](https://github.com/arinltte/YuE2Mac/issues) 提出，并附上你的 macOS 版本与复现步骤。

## 📄 许可证与致谢

YuE2Mac 应用源码以 [MIT 许可证](./LICENSE.txt) 发布。

*   **基础模型：** [**YuE**](https://github.com/multimodal-art-projection/YuE) —— 长篇幅音乐生成的开源基础模型系列，研究主页为 [map-yue2.github.io](https://map-yue2.github.io)。引用时请注明：
    ```bibtex
    @article{li2023mert,
      title = {{MERT}: Acoustic Music Understanding Model with Large-Scale Self-supervised Training},
      author = {Li, Yizhi and Yuan, Ruibin and Zhang, Ge and Ma, Yinghao and Chen, Xingran and Yin, Hanzhi and Xiao, Chenghao and Lin, Chenghua and Ragni, Anton and Benetos, Emmanouil and Gyenge, Norbert and Dannenberg, Roger and Liu, Ruibo and Chen, Wenhu and Xia, Gus and Shi, Yemin and Huang, Wenhao and Wang, Zili and Guo, Yike and Fu, Jie},
      journal = {arXiv preprint arXiv:2306.00107},
      year = {2023},
      eprint = {2306.00107},
      archivePrefix = {arXiv},
      url = {https://arxiv.org/abs/2306.00107}
    }

    @article{yuan2025yue,
      title = {{YuE}: Scaling Open Foundation Models for Long-Form Music Generation},
      author = {Yuan, Ruibin and Lin, Hanfeng and Guo, Shuyue and Zhang, Ge and Pan, Jiahao and Zang, Yongyi and Liu, Haohe and Liang, Yiming and Ma, Wenye and Du, Xingjian and Du, Xinrun and Ye, Zhen and Zheng, Tianyu and Jiang, Zhengxuan and Ma, Yinghao and Liu, Minghao and Tian, Zeyue and Zhou, Ziya and Xue, Liumeng and Qu, Xingwei and Li, Yizhi and Wu, Shangda and Shen, Tianhao and Ma, Ziyang and Zhan, Jun and Wang, Chunhui and Wang, Yatian and Chi, Xiaowei and Zhang, Xinyue and Yang, Zhenzhu and Wang, Xiangzhou and Liu, Shansong and Mei, Lingrui and Li, Peng and Wang, Junjie and Yu, Jianwei and Pang, Guojian and Li, Xu and Wang, Zihao and Zhou, Xiaohuan and Yu, Lijun and Benetos, Emmanouil and Chen, Yong and Lin, Chenghua and Chen, Xie and Xia, Gus and Zhang, Zhaoxiang and Zhang, Chao and Chen, Wenhu and Zhou, Xinyu and Qiu, Xipeng and Dannenberg, Roger and Liu, Jiaheng and Yang, Jian and Huang, Wenhao and Xue, Wei and Tan, Xu and Guo, Yike},
      journal = {arXiv preprint arXiv:2503.08638},
      year = {2025},
      eprint = {2503.08638},
      archivePrefix = {arXiv},
      url = {https://arxiv.org/abs/2503.08638}
    }
    ```
*   **MLX 引擎移植：** 本应用所封装的基础是这个 `YuE2-3B-MLX` 转换工程（`generate.py` 与模型模块）。
*   **计算运行时：** [Apple MLX](https://github.com/ml-explore/mlx)。

感谢开源 AI 社区，让本地音乐生成成为可能。

<p align="center">
  <i>标志由 GUMO 绘制 · https://www.instagram.com/gumoooo._/</i>
</p>

<p align="center">
  <i>由 arinltte 开发 · arinltte00@gmail.com</i>
</p>
