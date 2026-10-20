#!/bin/bash
# 云面板指令执行器 —— 轮询 .vm-output/commands.json，执行后写回 command-result.json
# 用法: bash cloud-desktop/executor.sh
mkdir -p .vm-output
LAST=""

while true; do
  git pull --rebase -X ours >/dev/null 2>&1
  if [ -f .vm-output/commands.json ]; then
    CID=$(python3 -c 'import json;print(json.load(open(".vm-output/commands.json")).get("id",""))' 2>/dev/null)
    if [ -n "$CID" ] && [ "$CID" != "$LAST" ]; then
      LAST="$CID"
      python3 -c 'import json;d=json.load(open(".vm-output/commands.json"));open("/tmp/_cmd","w").write(d.get("type","")+"\n"+d.get("payload",""))' 2>/dev/null
      TYPE=$(sed -n 1p /tmp/_cmd)
      PAY=$(sed -n 2p /tmp/_cmd)
      echo "{\"id\":\"$CID\",\"status\":\"running\",\"log\":\"开始执行: $TYPE $PAY\\n\"}" > .vm-output/command-result.json
      git add -f .vm-output/command-result.json >/dev/null 2>&1
      git commit -m "cmd start $CID" >/dev/null 2>&1
      git push --force >/dev/null 2>&1

      LOG="\$ $PAY\n"
      if [ "$TYPE" = "install" ]; then
        LOG+="apt-get update ...\n"
        LOG+=$(sudo apt-get update -qq 2>&1 | tail -3)"\n"
        for p in $PAY; do
          LOG+="\n--- 安装 $p ---\n"
          LOG+=$(sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$p" 2>&1 | tail -12)"\n"
        done
      else
        LOG+=$(bash -lc "$PAY" 2>&1 | tail -40)"\n"
      fi
      LOG+="\n===== 完成 =====\n"

      python3 - "$CID" "$LOG" <<'PYEOF'
import sys, json
json.dump({"id": sys.argv[1], "status": "done", "log": sys.argv[2]},
          open(".vm-output/command-result.json", "w"), ensure_ascii=False)
PYEOF
      git add -f .vm-output/command-result.json >/dev/null 2>&1
      git commit -m "cmd done $CID" >/dev/null 2>&1
      git push --force >/dev/null 2>&1
    fi
  fi
  sleep 5
done
