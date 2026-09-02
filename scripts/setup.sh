#!/usr/bin/env bash
# 一站式引导:检查依赖 -> 授权 lark-cli -> 生成 ~/.config/feishu-skills/config.json
# 用法: ./scripts/setup.sh [--chat-id oc_xxx] [--chat-name 群名] [--sender bot|user] [--profile 名] [--non-interactive]

set -euo pipefail

DBG="${DEBUG:-}"

echo "=================================================="
echo " feishu-summary-skills 一键配置"
echo "=================================================="

# ---------- 参数 ----------
CHAT_ID=""; CHAT_NAME=""; SENDER="bot"; PROFILE=""; NON_INTERACTIVE=false
while [ $# -gt 0 ]; do
  case "$1" in
    --chat-id) CHAT_ID="$2"; shift 2;;
    --chat-name) CHAT_NAME="$2"; shift 2;;
    --sender) SENDER="$2"; shift 2;;
    --profile) PROFILE="$2"; shift 2;;
    --non-interactive) NON_INTERACTIVE=true; shift;;
    *) echo "未知参数: $1" >&2; exit 1;;
  esac
done

need() { command -v "$1" >/dev/null 2>&1; }

echo ""
echo "[1/5] 检查依赖"
need node        || { echo "!! 缺少 node。请先安装 Node.js 18+ (https://nodejs.org)"; exit 1; }
need lark-cli    || { echo "!! 缺少 lark-cli。执行: npm install -g @larksuite/cli"; exit 1; }
need jq          || { echo "!! 缺少 jq。macOS: brew install jq | Windows: winget install jq | Linux: apt install jq"; exit 1; }
! need summarize || echo "  (提示) 若要用『总结+发送』,请安装 summarize CLI: npm install --global @steipete/summarize (Node 24+)"
echo "  OK"

echo ""
echo "[2/5] 检查 lark-cli 登录"
if lark-cli auth status 2>/dev/null | jq -e '.identities.user.status=="ready" or .identities.user.available==true' >/dev/null 2>&1; then
  echo "  已登录(用户身份可用)。若需换号: lark-cli auth login"
else
  echo "  需要用户授权。运行下面命令,按提示用飞书扫码/设备码登录:"
  echo "    lark-cli auth login"
  if [ "$NON_INTERACTIVE" = "true" ]; then read -rp "  完成登录后按回车继续..." _; else lark-cli auth login; fi
fi

echo ""
echo "[3/5] 确认 profile(可选)"
if need lark-cli; then
  echo "  当前 profile 列表:"
  lark-cli profile list 2>/dev/null | jq -r '.[] | "    - \(.name)   [\(.appId)]  active=\(.active)"' 2>/dev/null \
    || lark-cli profile list 2>&1 | grep -E 'name|active' || echo "    (无)"
fi
[ -z "$PROFILE" ] && [ "$NON_INTERACTIVE" = "false" ] && read -rp "  输入要使用的 profile 名(留空用当前默认): " PROFILE

echo ""
echo "[4/5] 收集接收群 chat_id"
if [ -z "$CHAT_ID" ]; then
  echo "  在飞书里:创建一个群 -> 群设置里把『机器人』(lark-cli 对应的飞书应用 Bot)加入群。"
  echo "  然后运行下面命令之一拿到群 ID:"
  echo "    lark-cli im +chats-list --as user --format json | jq -r '.data.items[] | .name+\" -> \"+.chat_id'"   # 列所有群
  echo "    或在群里 @机器人 发一条消息后: lark-cli im +chats-list --as bot --format json"
  [ "$NON_INTERACTIVE" = "false" ] && read -rp "  粘贴群的 chat_id(oc_ 开头): " CHAT_ID
fi
if [ -z "$CHAT_ID" ]; then echo "!! 未提供 chat_id,中止。可稍后编辑配置文件补上。" >&2; exit 1; fi

[ -z "$CHAT_NAME" ] && [ "$NON_INTERACTIVE" = "false" ] && read -rp "  群名(仅作人读标签,可留空): " CHAT_NAME

echo ""
echo "[5/5] 写入配置文件"
CONFIG_DIR="$HOME/.config/feishu-skills"
mkdir -p "$CONFIG_DIR"
CONFIG_FILE="$CONFIG_DIR/config.json"
jq -n \
  --arg chat_id "$CHAT_ID" \
  --arg chat_name "$CHAT_NAME" \
  --arg sender "$SENDER" \
  --arg profile "$PROFILE" \
  '{chat_id:$chat_id, chat_name:$chat_name, sender_identity:$sender, profile:$profile, lark_cli_path:"", message_format:"link"}' \
  > "$CONFIG_FILE"
chmod 600 "$CONFIG_FILE"

echo "  已写入: $CONFIG_FILE"
echo ""
echo "=================================================="
echo " 配置完成!验证: ./scripts/check-setup.sh"
echo " 用例:   总结后发飞书 -> 使用 summary-to-feishu"
echo "=================================================="