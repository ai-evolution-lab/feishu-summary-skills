# Windows PowerShell 版体检:校验配置、登录态与发送演练
# 用法: powershell -ExecutionPolicy Bypass -File scripts/check-setup.ps1
$ErrorActionPreference = "Continue"
$cfgFile = Join-Path $env:USERPROFILE '.config\feishu-skills\config.json'

Write-Host "== feishu-summary-skills 体检 (Windows) =="
if (-not (Test-Path $cfgFile)) {
  Write-Host "!! 未找到 $cfgFile — 运行 scripts\setup.ps1" -ForegroundColor Red; exit 1
}
$cfg = Get-Content $cfgFile -Raw | ConvertFrom-Json
Write-Host "  ✓ 配置文件: $cfgFile"
Write-Host "  chat_id: $($cfg.chat_id)  sender: $($cfg.sender_identity)"

$lark = Get-Command lark-cli -ErrorAction SilentlyContinue
if (-not $lark) { Write-Host "!! 未找到 lark-cli: npm install -g @larksuite/cli" -ForegroundColor Red; exit 1 }
$base = @("lark-cli"); if ($cfg.profile) { $base = @("lark-cli", "--profile", $cfg.profile) }

Write-Host "[1] 登录状态"
& $base auth status --format json | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Host "  ✓ auth 可用" } else { Write-Host "  ✗ 需重新授权: lark-cli auth login" -ForegroundColor Yellow }

Write-Host "[2] bot 是否在群"
& $base im +chat-members-list --as bot --chat-id $cfg.chat_id 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Host "  ✓ bot 在群" } else { Write-Host "  ✗ bot 不在群,请把应用机器人加入目标群" -ForegroundColor Yellow }

Write-Host "[3] 发送演练(dry-run)"
& $base im +messages-send --as $cfg.sender_identity --chat-id $cfg.chat_id --text "check-setup 演练" --dry-run 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Host "  ✓ 发送参数通过" } else { Write-Host "  ✗ 发送演练失败" -ForegroundColor Yellow }