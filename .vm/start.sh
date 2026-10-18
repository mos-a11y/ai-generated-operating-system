#!/usr/bin/env bash
# 云电脑终端启动脚本（Codespace 启动后自动执行）
set -u
cd "$(dirname "$0")" || exit 0
PORT=7681

# 已经在跑就跳过
if curl -sf -o /dev/null --max-time 3 "http://127.0.0.1:${PORT}/health" 2>/dev/null; then
  echo "webterm already running on ${PORT}"
  exit 0
fi

if ! command -v node >/dev/null 2>&1; then
  echo "node not found, skip webterm"
  exit 0
fi

nohup node "$(dirname "$0")/webterm.js" "${PORT}" > /tmp/webterm.log 2>&1 &
echo "webterm started on ${PORT}"
