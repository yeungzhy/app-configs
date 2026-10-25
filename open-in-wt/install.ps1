# ==================================================================
#  Windows Terminal 便携版（解压版）一键注册脚本
#  功能：
#    1. 右键文件夹           -> 在终端中打开
#    2. 右键文件夹空白处     -> 在终端中打开（桌面空白处同样生效）
#    3. 右键磁盘/磁盘空白处  -> 在终端中打开（附加）
#    4. Win+R 输入 wt 回车   -> 启动 Windows Terminal（与 cmd 同机制）
#  用法：右键本文件，选择“使用 PowerShell 运行”；或直接双击 install.bat
#  注意：本文件必须保存为 UTF-8 with BOM 编码，否则中文会乱码
# ==================================================================

# ---------------- 以下配置可按需修改 ----------------
$WtDir    = 'E:\lib\WindowsTerminal'   # Windows Terminal 解压目录
$WtExe    = Join-Path $WtDir 'WindowsTerminal.exe'  # 右键菜单调用
$WtAlias  = Join-Path $WtDir 'wt.exe'               # Win+R 调用
$MenuText = '在终端中打开'                          # 右键菜单文字
# ----------------------------------------------------

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

if (-not (Test-Path -LiteralPath $WtExe)) {
    Write-Host ""
    Write-Host "[错误] 未找到: $WtExe" -ForegroundColor Red
    Write-Host "       请编辑本脚本顶部，把 WtDir 改成实际的 Windows Terminal 解压目录后重试。"
    return
}

# 写一个右键菜单键：默认值=菜单文字，Icon=图标，command=执行命令
function Set-MenuKey {
    param([string]$KeyPath, [string]$Command)
    New-Item -Path "$KeyPath\command" -Force | Out-Null
    Set-Item  -Path $KeyPath -Value $MenuText
    Set-ItemProperty -Path $KeyPath -Name 'Icon' -Value $WtExe
    Set-ItemProperty -Path "$KeyPath\command" -Name '(default)' -Value $Command
}

$dirCmd  = "`"$WtExe`" -d `"%V`""   # 文件夹/空白处：路径可能带空格，加引号
$driveCmd = "`"$WtExe`" -d %V"      # 磁盘：盘符尾部有 \，加引号会被误解析，不加

try {
    Write-Host '正在写入注册表...' -ForegroundColor Cyan
    Write-Host "  [1/5] 右键文件夹           HKCR\Directory\shell\OpenInWT"
    Set-MenuKey -KeyPath 'Registry::HKEY_CLASSES_ROOT\Directory\shell\OpenInWT' -Command $dirCmd

    Write-Host "  [2/5] 右键文件夹空白处     HKCR\Directory\Background\shell\OpenInWT"
    Set-MenuKey -KeyPath 'Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\OpenInWT' -Command $dirCmd

    Write-Host "  [3/5] 右键磁盘             HKCR\Drive\shell\OpenInWT"
    Set-MenuKey -KeyPath 'Registry::HKEY_CLASSES_ROOT\Drive\shell\OpenInWT' -Command $driveCmd

    Write-Host "  [4/5] 右键磁盘根目录空白处 HKCR\Drive\Background\shell\OpenInWT"
    Set-MenuKey -KeyPath 'Registry::HKEY_CLASSES_ROOT\Drive\Background\shell\OpenInWT' -Command $driveCmd

    Write-Host "  [5/5] Win+R 的 wt 命令     HKLM\...\App Paths\wt.exe"
    $appPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\wt.exe'
    New-Item -Path $appPath -Force | Out-Null
    # 优先用解压目录自带的 wt.exe，没有则用主程序
    $aliasTarget = if (Test-Path -LiteralPath $WtAlias) { $WtAlias } else { $WtExe }
    Set-Item -Path $appPath -Value $aliasTarget
    Set-ItemProperty -Path $appPath -Name 'Path' -Value $WtDir
}
catch {
    Write-Host ""
    Write-Host "[失败] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host '请右键以管理员身份运行本脚本后重试。'
    return
}

Write-Host ''
Write-Host '==================== 安装完成 ====================' -ForegroundColor Green
Write-Host " - 右键任意文件夹 / 文件夹空白处 / 磁盘，即可看到【$MenuText】"
Write-Host ' - Win+R 输入 wt 回车，即可启动 Windows Terminal'
Write-Host ' - 若右键菜单未立即出现，重启资源管理器或注销一次即可'
Write-Host '=================================================='
