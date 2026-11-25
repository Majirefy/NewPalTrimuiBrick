# 新仙剑奇侠传 (NewPAL) — TrimUI Brick / NX-Redux Port

在 **TrimUI Brick（NX-Redux 固件）** 上运行 iOS 版《新仙剑奇侠传》的 PortMaster 移植框架。
原理：machismo 加载器把 iOS arm64 的 Mach-O 程序加载进 Linux aarch64 进程，
由桥接层把游戏的 SDL2 / OpenGLES / Foundation / AVFoundation 调用接到宿主系统。

> ⚠️ **本仓库只包含运行框架，不含游戏数据。**
> 《新仙剑奇侠传》是商业游戏，请使用你合法拥有的一份游戏文件；仓库不提供、也不接受任何游戏资源的请求。

---

## 一、本框架包含什么 / 不包含什么

**包含（全部自包含，无需系统库替换，不修改系统任何文件）：**

| 内容 | 说明 |
|---|---|
| `machismo` | iOS Mach-O 加载器（aarch64） |
| `libsword3_host.so` / `libsword3_ios_shim.so` / `libsword3_objc_shim.so` / `libsword3_gl_bridge.so` | iOS 框架桥接层 |
| `libsystem_shim.so` | libSystem 兼容层 |
| `xj-shim.so` | 本机补丁层（画面等比铺满；音频混音默认关闭，见「已知说明」） |
| `libs.aarch64/` | mali-fbdev 版 SDL2 2.26.1 + SDL2_mixer + libpng16 + libz + ffmpeg(58) + libstdc++ |
| `glibc-libs/` | SDL2_image / SDL2_ttf 及 jpeg/tiff/webp 等解码库 |
| `new-xianjian.sh` + `port.json` | PortMaster 启动脚本与元数据 |
| `newpal.gptk` / `patches.conf` / `dylib_map.conf` / `machismo*.conf` / `address-hooks.conf` / `mask.bmp` | 按键映射与引擎配置 |

**不包含（需要你自己准备）：**

- iOS 版《新仙剑奇侠传》的游戏数据（含主程序 `NewPAL`、`Music/`、`Video/`、`zh-Hans/StringDB.txt` 等全部资源）
- 交付形式二选一：
  - **`.ipa` 文件（推荐）**——直接拷进 port 目录，首次启动自动解压；
  - 或手动解压出的 `Payload/NewPAL.app/` 目录

**运行时自动生成（无需打包，也请勿从旧安装中拷贝）：** `conf/`（XDG 配置）、`saves/`（存档）、`logs/`（日志）。

## 二、安装步骤（TrimUI Brick / NX-Redux）

1. **安装框架**，二选一：
   - 用 PortMaster 安装 `new-xianjian-PM-portmaster.zip`（推荐）；
   - 或把本仓库全部文件拷到 SD 卡的
     `Roms/Ports (PORTS)/.ports/new-xianjian/`，
     并把 `new-xianjian.sh` 复制一份到 `Roms/Ports (PORTS)/` 根目录、改名为 `新仙剑奇侠传.sh`
     （若用 PortMaster 安装 zip 会自动完成这步）。
2. **放入游戏数据（.ipa）**：把你合法拥有的 iOS 版《新仙剑奇侠传》`.ipa` 文件拷到
   port 目录里（`…/.ports/new-xianjian/`，文件名任意、扩展名必须是 `.ipa`）。
   **首次启动时会自动解压**（约 1.7G，需要几分钟）：
   - 屏幕上会显示**解压进度界面**（百分比 + 文件计数），解压完成后显示
     「解压完成，正在清理安装包…」；
   - 校验通过（主程序存在且文件数完整）后会**自动删除 `.ipa`** 腾出空间，
     无需手动删除；
   - 若解压/校验失败，屏幕会提示，`.ipa` 会**保留**以便重试或手动解压；
   - 若没有找到 `.ipa`，屏幕会提示「未找到游戏数据」。
   解压成功后 SD 卡上会生成 `game/Payload/NewPAL.app/`（以 `NewPAL` 主程序存在为准）。
   - 也可以不拷 `.ipa`，改为手动解压 ipa，把其中的 `Payload/NewPAL.app`
     整个目录放到 `…/game/Payload/NewPAL.app`。
3. 回到主界面 → **Ports (PORTS)** → **新仙剑奇侠传** 启动。
4. 首次启动会自动创建 `conf/ saves/ logs/`。

其他 aarch64 + glibc 掌机理论上也能跑（本包不修改系统），但视频驱动按
`SDL_VIDEODRIVER=mali`（fbdev）适配，分辨率参数在启动脚本顶部的 `XJ_OUT_W/XJ_OUT_H`
里调整（默认 1024x768，游戏原生 640x480 会等比铺满）。

## 三、按键操作

按键名（A/B/X/Y…）经 **SDL_GameController** 解析：PortMaster 启动时已把
`SDL_GAMECONTROLLERCONFIG_FILE` 指向 PM 自带的 `gamecontrollerdb.txt`，本包**不覆盖**
按键布局 —— 若你的 CFW 定义了不同的 ABXY 排布，映射会自动跟随该 CFW 的配置。

| 掌机键 | 映射 |
|---|---|
| 方向键 / 摇杆 | 方向键 |
| **A** | **鼠标左键**（标题菜单、触屏式界面必须用鼠标点击确认） |
| B | ESC |
| X | Space |
| START | Enter |
| L1 / R1 | RightShift / RightCtrl |
| R3 | 鼠标左键 |
| 右摇杆 | 鼠标移动 |

**退出游戏**（两种方式，均由 PortMaster 标准机制提供，本包未做任何自定义热键）：
- **select + start**：gptokeyb 自带的 kill switch，强制结束游戏；
- 固件的全局退出热键（如 NX-Redux 的系统菜单）同样有效；
- 游戏内也有退出选项；原 H700 移植内置的组合键（Y+B+select）为温和退出，随移植层保留。

## 四、已知说明

- **音频**：游戏音效（22050Hz）与音乐/视频（44100Hz）走两条独立的 ALSA 流，
  依赖系统 asound.conf 的 dmix（NX-Redux 自带）。若你的固件不支持 dmix，
  可在启动脚本里改 `XJ_AUDIO_SHARE=1` 启用进程内混音（可能变调，仅作回退）。
- **存档**：位于 port 目录的 `saves/`，与游戏数据无关，可自由备份。
- **日志排错**：`logs/local.log`（引擎）、`logs/shim.log`（补丁层）。
- **画面**：游戏原生 640x480，以 1.6 倍等比铺满 1024x768 面板；
  更换 `XJ_FILL=mask|crop|off` 可切换铺屏策略。

## 五、致谢

- 原始 machismo 移植与桥接层：来自 H700 掌机社区的移植者（本包的 shim/引擎配置即基于其成果）
- PortMaster 生态与运行时库
- NX-Redux / NextUI 固件

（如你是原作者、希望署名或调整授权，请提 Issue。）

## 六、许可

- 框架部分：仅供学习研究，随 PortMaster 生态自由分发；
- 《新仙剑奇侠传》游戏数据版权归其权利人所有，请自行准备。
