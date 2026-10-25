#Requires -Version 5.1
<#
.SYNOPSIS
    修复 Internet Download Manager (IDM) 开机自启后 Alt+Tab 出现多余窗口的问题。

.DESCRIPTION
    IDM 以托盘方式自启时，如果主窗口从未被打开过，每次按 Alt+Tab 都会多出一个
    IDM 的幽灵窗口。本脚本启动一次 IDM 主窗口，等待其出现后发送 WM_CLOSE 正常
    关闭（不依赖焦点、不模拟按键），然后退出。请将本脚本的快捷方式放入启动文件夹
    （Win+R 运行 shell:startup），并放在 IDM 自启之后执行。
    兼容安装版和便携版：路径按 参数 > HKCU\DownloadManager > App Paths > HKLM 依次查找。

.PARAMETER ExePath
    IDMan.exe 的完整路径（便携版建议直接指定）。不指定时按以下顺序自动查找注册表：
    1. HKCU:\SOFTWARE\DownloadManager\ExePath          （IDM 配置主键，安装版/多数便携版都会写）
    2. App Paths\IDMan.exe                              （浏览器集成依赖此键，便携版常写）
    3. HKLM:\SOFTWARE\Internet Download Manager\ExePath （仅安装版）

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\idm-alt-tab-fix.ps1
#>
[CmdletBinding()]
param(
    [string]$ExePath
)

$ErrorActionPreference = 'Stop'

if (-not $ExePath) {
    # 依次尝试：HKCU 配置主键（安装版和多数便携版都写）→ App Paths（浏览器集成用）→ HKLM 安装键
    $candidates = @(
        'HKCU:\SOFTWARE\DownloadManager'
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\IDMan.exe'
        'HKLM:\SOFTWARE\Internet Download Manager'
        'HKLM:\SOFTWARE\WOW6432Node\Internet Download Manager'
    )
    foreach ($key in $candidates) {
        try {
            $ExePath = (Get-ItemProperty -Path $key -ErrorAction Stop).ExePath
            if ($ExePath) { break }
        } catch { }
    }
}

if (-not $ExePath -or -not (Test-Path -LiteralPath $ExePath)) {
    Write-Warning "未找到 IDMan.exe，请用 -ExePath 参数指定完整路径。"
    exit 1
}

# IDM 通常是开机自启的托盘程序，此时主窗口从未被创建过（这正是 Alt+Tab 幽灵窗口的来源）。
# 所以即使进程已在运行，也要再启动一次 IDMan.exe —— 已运行实例收到命令后会把主窗口打开。
Start-Process -FilePath $ExePath -WindowStyle Normal | Out-Null

# 等待主窗口出现，最多 10 秒
$deadline = (Get-Date).AddSeconds(10)
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 200
    $idm = Get-Process -Name IDMan -ErrorAction SilentlyContinue
    if ($idm -and $idm.MainWindowHandle -ne 0) { break }
}

if (-not $idm -or $idm.MainWindowHandle -eq 0) {
    Write-Warning "未能检测到 IDM 主窗口，跳过。"
    exit 1
}

Start-Sleep -Milliseconds 200

Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class Win32 {
    [DllImport("user32.dll")]
    public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
}
'@

# WM_CLOSE = 0x10：与点击窗口关闭按钮等效，IDM 会正常处理
[Win32]::PostMessage($idm.MainWindowHandle, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
Write-Host "已打开并关闭 IDM 主窗口。"
