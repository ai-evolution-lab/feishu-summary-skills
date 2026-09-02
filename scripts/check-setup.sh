#!/usr/bin/env bash
# 体检:校验配置文件、登录态、必要权限、bot 是否在群、发送演练(不真正发送)
# 用法: ./scripts/check-setup.sh

set -euo pipefail

CONFIG_FILE="$HOME/.config/feishu-skills/config.json"
PASS=0; FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS+1)); }
bad()  { echo "  ✗ $1"; FAIL=$((FAIL+1)); }

echo "== feishu-summary-skills 体检 =="

echo "[1] 配置文件"
if [ ! -f "$CONFIG_FILE" ]; then
  bad "未找到 $CONFIG_FILE — 运行 ./scripts/setup.sh 或复制 config.example.json 手改"
  exit 1
fi
ok "找到 $CONFIG_FILE"
CHAT_ID=$(jq -r '.chat_id // empty' "$CONFIG_FILE")
SENDER=$(jq -r '.sender_identity // "bot"' "$CONFIG_FILE")
PROFILE=$(jq -r '.profile // empty' "$CONFIG_FILE")
[ -n "$CHAT_ID" ] && { case "$CHAT_ID" in oc_*) ok "chat_id: $CHAT_ID";; *) bad "chat_id 看起来不是 oc_ 开头: $CHAT_ID";; esac; } || bad "chat_id 为空"
[ "$SENDER" = "bot" ] || [ "$SENDER" = "user" ] || bad "sender_identity 必须是 bot 或 user (当前: $SENDER)"

echo "[2] lark-cli 与登录"
command -v lark-cli >/dev/null || bad "未找到 lark-cli — 执行 npm install -g @larksuite/cli"
BASE=(lark-cli); [ -n "$PROFILE" ] && BASE=(lark-cli --profile "$PROFILE")
if "${BASE[@]}" auth status 2>/dev/null | jq -e '.identities.user.available==true' >/dev/null 2>&1; then
  ok "用户身份可用"
else
  bad "用户身份不可用 — 执行 ${BASE[*]} auth login"
fi
if "${BASE[@]}" auth status 2>/dev/null | jq -e '.identities.bot.available==true' >/dev/null 2>&1; then
  ok "bot 身份可用"
else
  bad "bot 身份不可用(发送角色) — 在开放平台确认应用已启用 robot"
fi

echo "[3] 权限 scope(创建文档/设权限/发消息)"
"${BASE[@]}" auth check --scope "docx:document:create" >/dev/null 2>&1 && ok "docx:document:create" || bad "缺少 docx:document:create — 开放平台开通后重新授权"
"${BASE[@]}" auth check --scope "docs:permission.setting:write_only" >/dev/null 2>&1 && ok "docs:permission.setting:write_only" || echo "  ~ 无 write_only,按需授权(仅在要设文档权限时需要)"
if [ "$SENDER" = "bot" ]; then
  echo "  (bot 发消息权限在开放平台配置,不走 auth)"
else
  "${BASE[@]}" auth check --scope "im:message.send_as_user" >/dev/null 2>&1 && ok "im:message.send_as_user" || bad "缺少 im:message.send_as_user"
fi

if [ -n "$CHAT_ID" ]; then
  echo "[4] bot 是否在目标群"
  if LARK_CLI_NO_PROXY=1 "${BASE[@]}" im +chat-members-list --as bot --chat-id "$CHAT_ID" >/dev/null 2>&1; then
    ok "bot 在群 $CHAT_ID"
  else
    bad "bot 不在群(或群不存在) — 把应用机器人添加进目标群"
  fi
  echo "[5] 发送演练(dry-run,不真正发送)"
  if LARK_CLI_NO_PROXY=1 "${BASE[@]}" im +messages-send --as "$SENDER" --chat-id "$CHAT_ID" --text "check-setup 演练" --dry-run >/dev/null 2>&1; then
    ok "发送参数校验通过"
  else
    bad "发送演练失败,检查 sender_identity / chat_id / 机器人权限"
  fi
fi

echo ""
echo "== 结果: $PASS 通过 / $FAIL 失败 =="
[ "$FAIL" -eq 0 ] || { echo "按上面 ✗ 项修复后重新运行。"; exit 1; }
echo "全部就绪,可以开始使用了。"