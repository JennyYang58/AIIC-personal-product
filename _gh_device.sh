#!/bin/bash
# 等待设备授权 → 建仓 → 推送 → 开启 Pages（token 仅存在于本进程内存）
CLIENT_ID="178c6fc778ccc68e1d6a"
DEVICE_CODE="7b41c3e4e45d3d066cc43de80db472c37f01387a"
OWNER="jennyyang58"
cd /d/zcode/nebulalab

echo "[1/5] 等待你在浏览器完成授权（在页面输入框 Ctrl+V 粘贴 655E-7826 → Continue → Authorize）…"
TOKEN=""
for i in $(seq 1 170); do
  R=$(curl -s -X POST https://github.com/oauth/access_token -H "Accept: application/json" \
      -d "client_id=$CLIENT_ID&device_code=$DEVICE_CODE&grant_type=urn:ietf:params:oauth:grant-type:device_code")
  T=$(echo "$R" | python -c "import sys,json;d=json.load(sys.stdin);print(d.get('access_token',''))" 2>/dev/null)
  if [ -n "$T" ]; then TOKEN="$T"; echo "      授权成功（第 $((i*5)) 秒）"; break; fi
  ERR=$(echo "$R" | python -c "import sys,json;print(json.load(sys.stdin).get('error',''))" 2>/dev/null)
  if [ "$ERR" = "expired_token" ]; then echo "!! 授权码过期，请重新发起"; exit 1; fi
  sleep 5
done
if [ -z "$TOKEN" ]; then echo "!! 超时未授权"; exit 1; fi

echo "[2/5] 创建仓库 AIIC personal product …"
CREATE=$(curl -s -X POST -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github+json" \
  https://api.github.com/user/repos \
  -d '{"name":"AIIC personal product","description":"研擎 NebulaLab —— AI 驱动的下一代科研经营体系（RBAC 角色化 MVP + 产品官网）","has_issues":true,"has_wiki":false}')
echo "$CREATE" | python -c "import sys,json;d=json.load(sys.stdin);print('      API full_name =',d.get('full_name') or d.get('errors') or d.get('message'))"
REPO=$(echo "$CREATE" | python -c "import sys,json;d=json.load(sys.stdin);print(d.get('name',''))")
if [ -z "$REPO" ]; then
  echo "      创建失败，尝试获取已存在仓库…"
  for cand in "AIIC-personal-product" "aiic-personal-product" "AIIC_personal_product"; do
    CODE=$(curl -s -o /tmp/gh_repo.json -w "%{http_code}" -H "Authorization: token $TOKEN" https://api.github.com/repos/$OWNER/$cand)
    if [ "$CODE" = "200" ]; then REPO=$(python -c "import json;print(json.load(open('/tmp/gh_repo.json'))['name'])"); echo "      已存在: $REPO"; break; fi
  done
fi
if [ -z "$REPO" ]; then echo "!! 无法确定仓库"; exit 1; fi
echo "      最终仓库名: $OWNER/$REPO"

echo "[3/5] 推送代码 …"
git remote remove origin 2>/dev/null
git remote add origin "https://x-access-token:$TOKEN@github.com/$OWNER/$REPO.git"
git push -u origin main 2>&1 | sed 's|x-access-token:[^@]*@|***@|g'
git remote set-url origin "https://github.com/$OWNER/$REPO.git"

echo "[4/5] 开启 GitHub Pages …"
P=$(curl -s -X POST -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/$OWNER/$REPO/pages -d '{"source":{"branch":"main","path":"/"}}')
echo "$P" | python -c "import sys,json;d=json.load(sys.stdin);print('      Pages:',d.get('html_url') or d.get('message'))"

echo "[5/5] 完成 ✓"
rm -f _gh_device.sh
