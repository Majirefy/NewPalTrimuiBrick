# NewPal — 新仙剑奇侠传 (TrimUI Brick / NX-Redux)

在 **TrimUI Brick（NX-Redux 固件）** 上运行 iOS 版《新仙剑奇侠传》的 PortMaster 移植框架。

> ⚠️ 本仓库和 Release 只包含运行框架，**不含游戏数据、不含 `.ipa`**。
> 请自行准备合法拥有的 iOS 版游戏文件。

## 安装

1. 从 [Releases](../../releases) 下载最新 `newpal.zip`。
2. 用 PortMaster 安装该 zip，或手动解压到 `Roms/Ports (PORTS)/.ports/newpal/`，
   并把 `NewPal.sh` 放到 `Roms/Ports (PORTS)/` 根目录。
3. 把你合法拥有的 `.ipa` 文件拷进 `newpal/` 目录。
4. 从 Ports 菜单启动。首次运行会显示解压进度；校验通过后自动删除 `.ipa`。

详细按键、存档、音频、虚拟按键隐藏说明见 [`ports/newpal/README.md`](ports/newpal/README.md)。

## 仓库结构

```text
ports/newpal/
├── NewPal.sh              # PortMaster 启动器
├── port.json              # PortMaster 端口元数据
├── README.md              # 面向用户的安装/按键说明
├── screenshot.jpg
├── cover.png
├── gameinfo.xml
├── RELEASE_NOTES.md       # Release 正文；发版前修改这里
└── newpal/                # 随 zip 安装的框架内容
    ├── newpal.port.json   # 打包时自动从 port.json 同步
    ├── machismo
    ├── libs.aarch64/
    ├── glibc-libs/
    ├── licenses/
    └── vpad-blank/
```

## 发布新版本

仓库使用 GitHub Actions 自动生成 Release：

1. 修改 `ports/newpal/RELEASE_NOTES.md`，写清楚本次版本内容。
2. 提交并推送一个新 tag：

   ```sh
   git tag v1.0.1
   git push origin v1.0.1
   ```

3. GitHub Actions 会自动构建 `newpal.zip`、生成 `newpal.zip.sha256`，
   并创建同名 Release。

也可以在 Actions 页面手动触发 `Build and publish NewPal release`，填入已有 tag。

本地预构建：

```sh
./tools/build_release.sh
shasum -a 256 newpal.zip
```

## 技术说明

- machismo 在 aarch64 Linux 上加载 iOS arm64 Mach-O。
- 桥接层把 SDL2 / OpenGLES / Foundation / AVFoundation 调用接到宿主系统。
- 运行时库全部放在端口目录内，不修改系统库。
- 音频默认使用系统 ALSA dmix 的双路输出，避免视频/音乐采样率不一致导致变调。
- 按键映射跟随 PortMaster / CFW 的 `SDL_GAMECONTROLLERCONFIG_FILE`；退出使用
  gptokeyb 标准的 `select + start`。

## 致谢

- 原始 machismo 移植与桥接层：H700 掌机社区移植者
- PortMaster 生态与运行时库
- NX-Redux / NextUI 固件

## 许可

- 本仓库中的框架部分按 `ports/newpal/newpal/licenses/` 内各许可证分发。
- 《新仙剑奇侠传》游戏数据版权归其权利人所有，本仓库不提供任何游戏资源。
