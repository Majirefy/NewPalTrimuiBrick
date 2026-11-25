#!/usr/bin/env bash
# PORTMASTER: new-xianjian.zip, 新仙剑奇侠传.sh
#
# 新仙剑奇侠传 (NewPAL) —— iOS 版二进制经 machismo 加载器在 aarch64 Linux 上运行。
# machismo 把 iOS arm64 Mach-O (game/Payload/NewPAL.app/NewPAL) 加载进进程，
# libsword3_host.so 将其 SDL2 / OpenGLES / Foundation / AVFoundation 调用桥到宿主。
# dylib_map.conf 里路径均为 ./ 相对路径，因此必须 cd 到 $gamedir 再启动。
#
# 自包含依赖（均在包内，无需系统库替换）：
#   libs.aarch64/  libSDL2 2.26.1 (TrimUI mali-fbdev 构建) + SDL2_mixer + libpng16
#                  + ffmpeg 58 + libstdc++
#   glibc-libs/    SDL2_image / SDL2_ttf 及 jpeg/tiff/webp/deflate/jbig 解码库
#   libc++.so.1    glibc 补丁版 libc++
#
# 显示：面板 1024x768，游戏原生 640x480（同为 4:3），xj-shim 以 RenderSetScale
#       1.6x 等比铺满（XJ_FILL=off），无需 mask/裁切。
# 音频：系统 /etc/asound.conf 自带 dmix，游戏音效(22050Hz)与 SDL2_mixer 音乐
#       两路可同时打开，无需额外配置。
# 输入：newpal.gptk 交由 gptokeyb（标题菜单只认鼠标点击，A 键映射为鼠标左键）。

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/mnt/SDCARD/Emus/shared/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
source $controlfolder/tasksetter
get_controls

export gamedir="/$directory/ports/new-xianjian"
cd "$gamedir" || exit 1

mkdir -p "$gamedir/logs" "$gamedir/conf" "$gamedir/saves"
exec >> "$gamedir/logs/local.log" 2>&1
echo "=== launch $(date) ==="

APPDIR="$gamedir/game/Payload/NewPAL.app"
BINARY="$APPDIR/NewPAL"
if [ ! -f "$BINARY" ]; then
    echo "newpal: game executable missing: $BINARY" >&2
    exit 1
fi
chmod +x "$gamedir/machismo" 2>/dev/null

# ---- 运行时库路径（全部相对包内目录；系统仅提供 alsa/z/GLES/EGL） ----
# exFAT 卡上不能建软链：libc++.so.1 的 DT_NEEDED 是无版本号的 libc.so / libm.so /
# libdl.so，在 /tmp(tmpfs) 里搭一份别名软链（设备 glibc 2.33，路径为 /lib/...）
STAGE=/tmp/xj-stage
rm -rf "$STAGE"; mkdir -p "$STAGE"
for pair in "libc.so.6:libc.so" "libm.so.6:libm.so" "libdl.so.2:libdl.so"; do
    real=${pair%%:*}; alias=${pair##*:}
    if [ -e "/lib/$real" ]; then ln -sf "/lib/$real" "$STAGE/$alias"
    elif [ -e "/usr/lib/$real" ]; then ln -sf "/usr/lib/$real" "$STAGE/$alias"; fi
done
export LD_LIBRARY_PATH="$STAGE:$gamedir/libs.aarch64:$gamedir/glibc-libs:$gamedir:/usr/lib:/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
unset LD_PRELOAD

# ---- 补丁层：等比铺满（xj-shim 的混音部分默认关闭） ----
# XJ_AUDIO_SHARE=1 是原作者为 H700 机器做的进程内音频混音（那台机 codec 不支持
# dmix）。TrimUI Brick 的系统 asound.conf 自带 dmix，可真正双路 ALSA 共存；
# 开 share=1 反而会让视频/BGM 音频被按主设备 22050Hz 错误混音（变调+爆音），
# 故本机默认 0：游戏音效(22050)与音乐桥(44100)各开各的真实设备。
# XJ_SHIM_OFF=1 关补丁；XJ_FILL=crop|off 换铺法；XJ_AUDIO_SHARE=1 强制开混音
XJ_SHIM="$gamedir/xj-shim.so"
if [ -f "$XJ_SHIM" ] && [ "${XJ_SHIM_OFF:-0}" != "1" ]; then
    export XJ_FILL="${XJ_FILL:-off}"
    export XJ_AUDIO_SHARE="${XJ_AUDIO_SHARE:-0}"
    export XJ_OUT_W="${XJ_OUT_W:-1024}" XJ_OUT_H="${XJ_OUT_H:-768}"
    export XJ_BASE_W=640 XJ_BASE_H=480
    export XJ_SHIM_LOG="$gamedir/logs/shim.log"
    export XJ_MASK="$gamedir/mask.bmp"
    export LD_PRELOAD="$XJ_SHIM"
    echo "=== shim enabled fill=$XJ_FILL share=$XJ_AUDIO_SHARE ==="
fi

# ---- 引擎 / 资源路径 ----
CONFDIR="$gamedir/conf"
export XDG_CONFIG_HOME="$CONFDIR"
export XDG_DATA_HOME="$CONFDIR"
export MACHISMO_CONFIG="$gamedir/machismo-partial-sdl.conf"
# 不要开 MACHISMO_STRICT_BINDS：NewPAL 会导入 4 个 shim 未提供的符号，
# strict 会在 dylib load 阶段直接 abort。
export SWORD3_PORT=newpal
export SWORD3_BUNDLE_DIR="$APPDIR"
export SWORD3_DATA_DIR="$gamedir/saves"

# ---- 图形：TrimUI mali-fbdev SDL（包内 libs.aarch64 自带） ----
unset WAYLAND_DISPLAY XDG_RUNTIME_DIR
export SDL_VIDEODRIVER=mali
# host 桥覆盖开关（SWORD3_RES / SWORD3_LOGICAL）默认不写死，便于对比测试
[ -n "${XJ_RES:-}" ]     && export SWORD3_RES="$XJ_RES"
[ -n "${XJ_LOGICAL:-}" ] && export SWORD3_LOGICAL="$XJ_LOGICAL"

# ---- 音频：系统 asound.conf 已带 dmix，两路音频天然共存 ----
export SDL_AUDIODRIVER=alsa
unset AUDIODEV

# ---- 输入：gptokeyb 读取包内 newpal.gptk ----
# 标题菜单只认鼠标点击：A=左键；MENU 键（gptokeyb hotkey）可退出映射
$GPTOKEYB "machismo" -c "$gamedir/newpal.gptk" &

echo "=== exec machismo $BINARY ==="
$TASKSET "$gamedir/machismo" "$BINARY" "$@"

echo "=== exited ==="
# 补丁层只对游戏进程生效；退出后解除，避免污染 pm_finish 的子 shell
unset LD_PRELOAD
pm_finish
