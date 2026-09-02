#!/usr/bin/env bash
# 安装 feishu-summary-skills 到本地 Agent 客户端
# 用法: ./install.sh [--target opencode|claude|codex|agents|all]  (默认 opencode)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

declare -A TARGETS=(
  [opencode]="$HOME/.config/opencode/skills"
  [claude]="$HOME/.claude/skills"
  [codex]="$HOME/.codex/skills"
  [agents]="$HOME/.agents/skills"
)

pick=("${1:-opencode}")
[ "${1:-}" = "all" ] && pick=("opencode" "claude" "codex" "agents")

installed=false
for name in "${pick[@]}"; do
  dir="${TARGETS[$name]:-}"
  if [ -z "$dir" ]; then
    echo "!! 未知目标: $name (可选: opencode claude codex agents all)" >&2
    continue
  fi
  mkdir -p "$dir"
  cp -R "$SCRIPT_DIR/skills/"* "$dir/"
  echo "=> 已安装到 $dir"
  installed=true
done

$installed || { echo "!! 未安装任何 skill" >&2; exit 1; }
echo "安装完成。下一步: ./scripts/setup.sh 生成配置（或手动编辑 config.json，见 README）"