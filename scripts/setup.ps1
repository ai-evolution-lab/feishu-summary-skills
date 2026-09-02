# Windows PowerShell 版一键配置(与 setup.sh 等价)
# 用法:  powershell -ExecutionPolicy Bypass -File scripts/setup.ps1  [-ChatID oc_xxx] [-ChatName 群名] [-Sender bot]
param(
  [string]$ChatID = "",
  [string]$ChatName = "",
  [string]$Sender = "bot",
  [string]$Profile = ""
)
$ErrorActionPreference = "Stop"
Write-Host "== feishu-summary-skills 一键配置 (Windows) =="

# 1 依赖
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) { Write-Host "!! 缺少 node。安装 Node.js 18+ 后重试。" -ForegroundColor Red; exit 1 }
$lark = Get-Command lark-cli -ErrorAction SilentlyContinue
if (-not $lark) { Write-Host "!! 缺少 lark-cli。执行: npm install -g @larksuite/cli" -ForegroundColor Red; exit 1 }

# 2 登录
Write-Host "[1/4] 检查 lark-cli 登录"
& lark-cli auth login --format json 2>$null | Out-Null
Write-Host "  完成授权(未登录会弹出设备码/二维码)。"

# 3 收集 chat_id
Write-Host "[2/4] 收集接收群"
if (-not $ChatID) {
  Write-Host "  1) 在飞书创建/选择一个群,并把对应应用机器人拉进群。"
  Write-Host "  2) 运行: lark-cli im +chats-list --as user --format json"
  $ChatID = Read-Host " 粘贴群的 chat_id(oc_ 开头)"
}
if (-not $ChatID) { Write-Host "!! 未提供 chat_id" -ForegroundColor Red; exit 1 }
if (-not $ChatName) { $ChatName = Read-Host "  群名(人读标签,可留空)" }

# 4 写配置
Write-Host "[3/4] 写入配置"
$dir = Join-Path $env:USERPROFILE ".config\feishu-skills"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$cfg = [ordered]@{
  chat_id          = $ChatID
  chat_name        = $ChatName
  sender_identity  = $Sender
  profile          = $Profile
  lark_cli_path    = ""
  message_format   = "link"
}
$file = Join-Path $dir "config.json"
$cfg | ConvertTo-Json | Set-Content -Path $file -Encoding UTF8
Write-Host "  已写入: $file"
Write-Host "[4/4] 完成。迁移到其他机器时可复制本文件。"
Write-Host "  验证: scripts\check-setup.ps1"