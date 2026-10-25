# ==================================================================
#  Windows Terminal 便携版注册卸载脚本
#  删除 install.ps1 写入的全部注册表项（右键菜单 + Win+R wt 命令），
#  不删除、不修改 Windows Terminal 本体。
#  注意：本文件必须保存为 UTF-8 with BOM 编码，否则中文会乱码
# ==================================================================

$ErrorActionPreference = 'Stop'

# ---- 检查管理员权限，没有则自动申请 ----
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host '需要管理员权限，正在请求（请在弹出的 UAC 窗口中点“是”）...' -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-NoExit', '-File', "`"$PSCommandPath`""
    )
    exit
}

$keys = @(
    'Registry::HKEY_CLASSES_ROOT\Directory\shell\OpenInWT',
    'Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\OpenInWT',
    'Registry::HKEY_CLASSES_ROOT\Drive\shell\OpenInWT',
    'Registry::HKEY_CLASSES_ROOT\Drive\Background\shell\OpenInWT',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\wt.exe'
)

try {
    Write-Host '正在删除右键菜单项与 wt 命令...' -ForegroundColor Cyan
    foreach ($key in $keys) {
        if (Test-Path $key) {
            Remove-Item -Path $key -Recurse -Force
            Write-Host "  已删除: $key"
        }
    }
}
catch {
    Write-Host ""
    Write-Host "[失败] $($_.Exception.Message)" -ForegroundColor Red
    return
}

Write-Host ''
Write-Host '==================== 卸载完成 ====================' -ForegroundColor Green
Write-Host ' 右键菜单与 wt 命令已移除（Windows Terminal 本体不受影响）。'
Write-Host ' 若菜单项仍显示，重启资源管理器或注销一次即可。'
Write-Host '=================================================='
