#!/bin/bash
# 云面板监控快照采集器 —— 每 3 秒从本地面板取数据，写入 .vm-output/panel-stats.json
# 用法: bash cloud-desktop/snapshot.sh
mkdir -p .vm-output

PT=$(curl -s -m 10 -X POST -H 'Content-Type: application/json' \
     -d '{"password":"123456"}' http://localhost:8899/api/login \
     | python3 -c 'import sys,json;print(json.load(sys.stdin).get("token",""))')
echo "token_len=${#PT}" > .vm-output/snap.info

while true; do
  D=$(curl -s -m 8 "http://localhost:8899/api/stats?token=$PT")
  P=$(curl -s -m 8 "http://localhost:8899/api/processes?token=$PT")
  if [ -n "$D" ] && echo "$D" | grep -q cpu_info; then
    echo "$D" > /tmp/_d.json
    echo "$P" > /tmp/_p.json
    python3 /dev/stdin <<'PYEOF'
import json, time
try:
    d = json.load(open('/tmp/_d.json'))
    try:
        p = json.load(open('/tmp/_p.json')).get('list', [])
    except Exception:
        p = []
    d['processes'] = p
    d['ts'] = time.strftime('%H:%M:%S')
    json.dump(d, open('.vm-output/panel-stats.json', 'w'), ensure_ascii=False)
except Exception as e:
    open('/tmp/snap.err', 'w').write(str(e))
PYEOF
  fi
  sleep 3
done
