#!/bin/bash
# 云电脑应用商店（中文图形/终端双模式）
export LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 LANGUAGE=zh_CN:zh
export DISPLAY=:1
export DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/dbus-sock
export DEBIAN_FRONTEND=noninteractive

CATS=(
"浏览器|Chromium 开源浏览器|chromium-browser"
"浏览器|Epiphany 简洁浏览器|epiphany-browser"
"浏览器|Midori 轻量浏览器|midori"
"办公|LibreOffice 办公套件|libreoffice"
"办公|PDF 阅读器 Evince|evince"
"办公|词典 GoldenDict|goldendict"
"图形|GIMP 图像处理|gimp"
"图形|Inkscape 矢量绘图|inkscape"
"图形|截图工具 Flameshot|flameshot"
"影音|VLC 播放器|vlc"
"影音|Audacity 音频编辑|audacity"
"影音|MP3 编码 lame|lame"
"系统|htop 任务管理器|htop"
"系统|neofetch 系统信息|neofetch"
"系统|GParted 分区工具|gparted"
"开发|Python 包管理 pip|python3-pip"
"开发|Git 版本控制|git"
"开发|Vim 编辑器|vim"
"开发|Node.js 运行环境|nodejs npm"
"工具|7zip 压缩工具|p7zip-full"
"工具|Wget/Curl 下载工具|wget curl"
"工具|Wine 运行 Windows 程序|wine"
"工具|文件搜索 Recoll|recoll"
"聊天|Pidgin 即时通讯|pidgin"
"聊天|Thunderbird 邮件|thunderbird"
)

install_pkgs() {
  echo "== 开始安装: $* =="
  sudo apt-get update -qq
  for p in "$@"; do
    echo "--- $p ---"
    sudo apt-get install -y -qq "$p" 2>&1 | tail -3
  done
  echo "== 全部完成 =="
}

if command -v zenity >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
  ARGS=()
  for c in "${CATS[@]}"; do
    IFS='|' read -r cat name pkg <<< "$c"
    ARGS+=(FALSE "$cat" "$name" "$pkg")
  done
  PKGS=$(zenity --list --checklist --title="应用商店" \
    --text="勾选要安装的应用，点确定开始安装（约需几分钟）" \
    --column="装" --column="分类" --column="应用" --column="包名" \
    --width=680 --height=520 "${ARGS[@]}" 2>/dev/null)
  [ -z "$PKGS" ] && exit 0
  LIST=$(echo "$PKGS" | tr '|' ' ')
  zenity --question --title="应用商店" --text="即将安装：\n$LIST\n\n是否继续？" || exit 0
  xfce4-terminal -T "应用商店 - 安装中" -x bash -c "$(declare -f install_pkgs); install_pkgs $LIST; echo; echo '安装完成，按回车关闭'; read"
else
  echo "=============================="
  echo "        云电脑 应用商店"
  echo "=============================="
  i=0
  for c in "${CATS[@]}"; do
    i=$((i+1))
    IFS='|' read -r cat name pkg <<< "$c"
    printf "%2d) [%-4s] %s\n" "$i" "$cat" "$name"
  done
  echo "=============================="
  read -rp "输入编号（空格分隔多个，直接回车退出）: " SEL
  [ -z "$SEL" ] && exit 0
  LIST=""
  for n in $SEL; do
    [ "$n" -ge 1 ] && [ "$n" -le "${#CATS[@]}" ] && LIST="$LIST $(echo "${CATS[$((n-1))]}" | cut -d'|' -f3)"
  done
  [ -z "$LIST" ] && exit 0
  install_pkgs $LIST
  echo "安装完成，按回车关闭"; read
fi
