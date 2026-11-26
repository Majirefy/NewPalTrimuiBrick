# NewPal v1.0.0 — 首个正式版本

这是 NewPal 的第一个 Release。此版本只发布 **PortMaster 运行框架**，不包含任何商业游戏数据或 `.ipa` 文件。

## 本版本发布内容

发布资产：`newpal.zip`（另附 `newpal.zip.sha256` 校验文件）。

Zip 内按 PortMaster 规范组织：

```text
NewPal.sh
newpal/
├── newpal.port.json
├── machismo
├── libsword3_*.so / libsystem_shim.so / xj-shim.so
├── libs.aarch64/
├── glibc-libs/
├── licenses/
├── vpad-blank/
└── 配置文件与补丁文件
```

包含：

- PortMaster 启动脚本 `NewPal.sh`，端口 ID 为 `newpal`
- machismo iOS Mach-O 加载器与桥接库
- aarch64 运行库（SDL2 / SDL2_mixer / FFmpeg / libpng / zlib / libc++ 等）
- 首次运行 `.ipa` 自动解压、进度显示、校验与自动删除逻辑
- gptokeyb 按键映射，跟随 PortMaster / CFW 控制器配置
- `select + start` 使用 PortMaster 标准退出机制
- 虚拟按键提示隐藏资源（`XJ_HIDE_VPAD`，可用 `XJ_HIDE_VPAD=0` 还原）
- 封面自动放置逻辑（NX-Redux `.media/`）
- 依赖许可证文件 `newpal/licenses/LICENSE.*.txt`

仓库中同时提供 PortMaster 元数据：`port.json`、`README.md`、`screenshot.jpg`、`cover.png`、`gameinfo.xml`。

## 明确不包含

- iOS 版《新仙剑奇侠传》的 `.ipa` 文件
- `Payload/NewPAL.app` 及任何游戏资源
- 存档、日志、运行时生成的 `conf/`

用户需自行准备合法拥有的 `.ipa`，放入 `newpal/` 目录后首次启动安装。

## 已知范围

- 目标设备：TrimUI Brick / NX-Redux（aarch64 + glibc）
- 端口元数据中 `reqs` 标记为 `trimui-brick`，其他设备不会在 PortMaster 中显示
- 视频驱动使用 `SDL_VIDEODRIVER=mali`，分辨率为 1024x768 面板适配

## 校验

下载后可用以下命令校验：

```sh
sha256sum -c newpal.zip.sha256
```
