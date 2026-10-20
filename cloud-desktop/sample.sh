#!/bin/bash
# 采样本机面板数据 -> .vm-output/panel-stats.json
export PATH=/usr/bin:/bin:/usr/local/bin:$PATH
mkdir -p .vm-output
PT=$(curl -s -m 10 -X POST -H 'Content-Type: application/json' -d '{"password":"123456"}' http://localhost:8899/api/login | python3 -c 'import sys,json;print(json.load(sys.stdin).get("token",""))' 2>/dev/null)
curl -s -m 8 "http://localhost:8899/api/stats?token=$PT" > /tmp/_d.json
curl -s -m 8 "http://localhost:8899/api/processes?token=$PT" > /tmp/_p.json
python3 - <<'PY'
import json, time
try:
    d = json.load(open('/tmp/_d.json'))
    if 'cpu_info' not in d:
        raise ValueError('bad stats')
    try:
        p = json.load(open('/tmp/_p.json')).get('list', [])
    except Exception:
        p = []
    d['processes'] = p
    d['ts'] = time.strftime('%H:%M:%S')
    json.dump(d, open('.vm-output/panel-stats.json', 'w'), ensure_ascii=False)
    print('ok')
except Exception as e:
    open('/tmp/sample.err', 'w').write(str(e))
    print('err', e)
PY
