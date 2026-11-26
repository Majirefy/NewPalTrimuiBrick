#!/usr/bin/env bash
# PORTMASTER: newpal.zip, NewPal.sh
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

export gamedir="/$directory/ports/newpal"
cd "$gamedir" || exit 1

mkdir -p "$gamedir/logs" "$gamedir/conf" "$gamedir/saves"
exec >> "$gamedir/logs/local.log" 2>&1
echo "=== launch $(date) ==="

APPDIR="$gamedir/game/Payload/NewPAL.app"
BINARY="$APPDIR/NewPAL"

# ---- 游戏数据：用户把 iOS 版 .ipa 放进 port 目录，首次启动自动解压 ----
# 首次解压用 show2.elf 在屏幕上显示进度条，解压校验通过后自动删除 .ipa
SHOW2="/mnt/SDCARD/.system/bin/show2.elf"
show_text() { # $1=文字 $2=进度(-1 表示不确定的转圈条, 0-100 为进度条)
    [ -x "$SHOW2" ] || return 0
    killall -9 show2.elf >/dev/null 2>&1
    LD_LIBRARY_PATH="$gamedir/libs.aarch64:/mnt/SDCARD/Emus/shared/PortMaster/lib:${LD_LIBRARY_PATH:-}" \
        "$SHOW2" --mode=progress --image=/dev/null --text="$1" --progress="$2" \
        --texty=45 --progressy=55 --fontsize=28 >/dev/null 2>&1 &
}
kill_show() { killall -9 show2.elf >/dev/null 2>&1; }

if [ ! -f "$BINARY" ]; then
    IPA=""
    for f in "$gamedir"/*.ipa "$gamedir/game"/*.ipa; do
        [ -f "$f" ] && IPA="$f" && break
    done
    if [ -n "$IPA" ]; then
        echo "newpal: extracting $(basename "$IPA") -> game/ （首次解压约 1.7G，需要几分钟）"
        mkdir -p "$gamedir/game"

        # 解压器：优先 unzip；回退 PortMaster 自带 7zzs。
        # 注意 7zzs 用新版语法 l/x（不支持 -l/-o），统计文件数用 "....." 文件行计数。
        if command -v unzip >/dev/null 2>&1; then
            UNZIPPER=unzip
            TOTAL=$("$UNZIPPER" -l "$IPA" 2>/dev/null | tail -1 | awk '{print $1}')
        elif [ -x "$controlfolder/7zzs.aarch64" ] || [ -x "$controlfolder/bin/7zzs" ] \
             || [ -x "/mnt/SDCARD/Emus/shared/PortMaster/7zzs.aarch64" ]; then
            for _cand in "$controlfolder/7zzs.aarch64" "$controlfolder/bin/7zzs" \
                         "/mnt/SDCARD/Emus/shared/PortMaster/7zzs.aarch64"; do
                if [ -x "$_cand" ]; then UNZIPPER="$_cand"; break; fi
            done
            TOTAL=$("$UNZIPPER" l "$IPA" 2>/dev/null | grep -c '\.\.\.\.\.')
        else
            show_text "缺少解压工具，无法安装" -1
            echo "newpal: 系统中没有 unzip/7zzs，无法解压 .ipa；请手动解压 Payload/NewPAL.app 到 game/Payload/" >&2
            kill_show
            exit 1
        fi
        case "$TOTAL" in ''|*[!0-9]*) TOTAL="" ;; esac

        show_text "正在解压游戏数据（首次启动，请勿关机）…" -1
        if [ "$UNZIPPER" = "unzip" ]; then
            ( cd "$gamedir/game" && "$UNZIPPER" -o -q "$IPA" >/dev/null 2>&1 ) &
        else
            ( cd "$gamedir/game" && "$UNZIPPER" x -y "$IPA" >/dev/null 2>&1 ) &
        fi
        UNZIP_PID=$!
        while kill -0 "$UNZIP_PID" 2>/dev/null; do
            if [ -n "$TOTAL" ]; then
                DONE=$(find "$gamedir/game" -type f 2>/dev/null | wc -l)
                PCT=$(( DONE * 100 / TOTAL )); [ "$PCT" -gt 100 ] && PCT=100
                show_text "首次启动：正在解压游戏数据 $PCT%（$DONE/$TOTAL）" "$PCT"
            fi
            sleep 2
        done
        wait "$UNZIP_PID" 2>/dev/null
        rm -rf "$gamedir/game/__MACOSX"
        find "$gamedir/game" -name '._*' -exec rm -f {} \; 2>/dev/null

        # 校验：主程序存在且解压文件数合理，通过后删除 .ipa 腾出空间
        show_text "正在校验解压结果…" -1
        DONE=$(find "$gamedir/game" -type f 2>/dev/null | wc -l)
        if [ -f "$BINARY" ] && { [ -z "$TOTAL" ] || [ "$DONE" -ge "$TOTAL" ]; }; then
            show_text "解压完成，正在清理安装包…" 100
            echo "newpal: extraction verified ($DONE files), removing ipa"
            rm -f "$IPA"
            sleep 1
        else
            show_text "解压/校验失败！保留 .ipa，请重试或手动解压" -1
            echo "newpal: extraction FAILED (binary=$([ -f "$BINARY" ] && echo ok || echo missing), files=$DONE/$TOTAL), keeping ipa" >&2
            sleep 3
            kill_show
            exit 1
        fi
    else
        show_text "未找到游戏数据！请把 iOS 版 .ipa 拷到本目录" -1
        echo "newpal: 游戏数据缺失。" >&2
        echo "newpal: 请把 iOS 版《新仙剑奇侠传》的 .ipa 文件拷到 port 目录（$gamedir/）后重新启动，" >&2
        echo "newpal: 或手动解压得到 game/Payload/NewPAL.app/NewPAL。" >&2
        sleep 3
        kill_show
        exit 1
    fi
fi
kill_show
chmod +x "$gamedir/machismo" 2>/dev/null

# ---- 隐藏 iOS 版自带的虚拟按键 / 摇杆提示（默认开；XJ_HIDE_VPAD=0 还原） ----
# iOS 触屏版检测到触摸拖动时会显示虚拟方向键和 A 键（Resource/dpad*.png）。
# 本移植把十字键/摇杆映射成"鼠标拖拽"，游戏会误以为在触屏，屏幕上因此浮出
# 虚拟摇杆/按键提示（通常在指针初始位置，即左上角）。用包内 vpad-blank/ 的
# 同尺寸全透明 PNG 覆盖即可隐藏；原图备份为同名 .xjbak，随时可还原。
VPAD_RES="$gamedir/game/Payload/NewPAL.app/Resource"
VPAD_FILES="dpad.png dpad_u.png dpad_d.png dpad_l.png dpad_r.png dpad_ul.png dpad_ur.png dpad_dl.png dpad_dr.png dpad_A.png dpad_A_click.png dpad_sw.png dpad_sw_click.png"
if [ "${XJ_HIDE_VPAD:-1}" = "1" ] && [ -d "$VPAD_RES" ]; then
    for f in $VPAD_FILES; do
        orig="$VPAD_RES/$f"
        blank="$gamedir/vpad-blank/$f"
        [ -f "$orig" ] && [ -f "$blank" ] || continue
        [ -f "$orig.xjbak" ] || cp "$orig" "$orig.xjbak"
        cmp -s "$orig" "$blank" 2>/dev/null || cp -f "$blank" "$orig"
    done
    echo "=== vpad hidden (XJ_HIDE_VPAD=1) ==="
elif [ -d "$VPAD_RES" ]; then
    for f in $VPAD_FILES; do
        [ -f "$VPAD_RES/$f.xjbak" ] && mv -f "$VPAD_RES/$f.xjbak" "$VPAD_RES/$f"
    done
    echo "=== vpad restored (XJ_HIDE_VPAD=0) ==="
fi

# ---- 封面：若固件的 Ports 封面目录存在，自动放置（供 NX-Redux 列表显示） ----
# 路径为 TrimUI Brick / NX-Redux 专用；其他固件不存在该目录则静默跳过。
COVER_SRC="$gamedir/cover.png"
ROMS_MEDIA="/mnt/SDCARD/Roms/Ports (PORTS)/.media"
if [ -f "$COVER_SRC" ] && [ -d "/mnt/SDCARD/Roms/Ports (PORTS)" ]; then
    mkdir -p "$ROMS_MEDIA"
    cmp -s "$COVER_SRC" "$ROMS_MEDIA/NewPal.png" 2>/dev/null || cp -f "$COVER_SRC" "$ROMS_MEDIA/NewPal.png"
fi

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
    # xj-shim 需要 dlsym@GLIBC_2.17：glibc < 2.34 时该符号在 libdl.so.2（本机 2.33）。
    # 包内 SDL2(mali) 的视频驱动会经 system()/execlp() 派生 /bin/sh 子进程，这类
    # 子进程不链接 libdl，若只 preload shim，子进程加载 shim 时会报
    # "symbol lookup error: dlsym, version GLIBC_2.17"（出现在启动/退出日志里）。
    # 把 libdl.so.2 排在 shim 前一并预加载即可（glibc >= 2.34 的 libdl 是转发壳，无害）。
    XJ_LIBDL=""
    [ -e "/lib/libdl.so.2" ] && XJ_LIBDL="/lib/libdl.so.2"
    [ -z "$XJ_LIBDL" ] && [ -e "/usr/lib/libdl.so.2" ] && XJ_LIBDL="/usr/lib/libdl.so.2"
    if [ -n "$XJ_LIBDL" ]; then
        export LD_PRELOAD="$XJ_LIBDL:$XJ_SHIM"
    else
        export LD_PRELOAD="$XJ_SHIM"
    fi
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

# ---- PortMaster runtime: per-CFW controller mapping and platform helper ----
[ -n "${sdl_controllerconfig:-}" ] && export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
command -v pm_platform_helper >/dev/null 2>&1 && pm_platform_helper "$gamedir/machismo"

# ---- 输入：gptokeyb 读取包内 newpal.gptk ----
# 按键名（a/b/x/y...）经 SDL_GameController 解析：PortMaster 的 control.txt 已把
# SDL_GAMECONTROLLERCONFIG_FILE 指向 PM 自带 gamecontrollerdb.txt，因此映射跟随
# 各 CFW 的按键布局（某 CFW 若交换了 ABXY，这里也自动一致），本包不做覆盖。
# 退出按 PortMaster 标准机制：gptokeyb 的 kill switch（默认 start+select 组合，
# 由 PM 自带 gptokeyb 决定，本包不定义/不覆盖热键）；CFW 的全局退出热键同样有效。
# 标题菜单只认鼠标点击：A=左键。
$GPTOKEYB "machismo" -c "$gamedir/newpal.gptk" &

echo "=== exec machismo $BINARY ==="
$TASKSET "$gamedir/machismo" "$BINARY" "$@"

echo "=== exited ==="
# 补丁层只对游戏进程生效；退出后解除，避免污染 pm_finish 的子 shell
unset LD_PRELOAD
pm_finish
