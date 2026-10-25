# IDM Alt+Tab Fix

修复 Internet Download Manager (IDM) 开机自启后，每次按 **Alt+Tab** 都会出现一个多余 IDM 窗口的问题。

## 原因

IDM 以托盘方式自启时，如果主窗口从未被创建过，Windows 的 Alt+Tab 会枚举到它的隐藏窗口。
只要打开一次主窗口再正常关闭，问题即消失。

## 使用方法

1. 按 `Win+R`，运行 `shell:startup`，打开启动文件夹。
2. 在文件夹中新建一个快捷方式，目标填写：

   ```
   powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\path\to\idm-alt-tab-fix.ps1"
   ```

   （把路径换成脚本的实际位置。）

3. 如果 IDM 没装在默认位置，追加参数指定 `IDMan.exe` 的完整路径（**便携版建议直接指定**）：

   ```
   ... -File "C:\path\to\idm-alt-tab-fix.ps1" -ExePath "D:\TEMP\IDM\IDMan.exe"
   ```

不指定 `-ExePath` 时，脚本按以下顺序从注册表自动查找 IDM 位置：

1. `HKCU\SOFTWARE\DownloadManager\ExePath` — IDM 的配置主键，安装版和多数便携版都会写；
2. `App Paths\IDMan.exe` — 浏览器集成依赖此键，你的浏览器能自动装 IDM 插件通常就意味着它存在；
3. `HKLM\SOFTWARE\Internet Download Manager\ExePath` — 仅安装版。

不确定自己的便携版写没写注册表？运行以下命令验证，任一有输出即可自动识别：

```
reg query "HKCU\Software\DownloadManager" /v ExePath
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\IDMan.exe"
```

## 行为说明

- 启动 IDM 主窗口（IDM 托盘进程已在运行时，再次启动会把已运行实例的主窗口打开）；
- 等待主窗口出现（最多 10 秒）；
- 向主窗口发送 `WM_CLOSE` 正常关闭——**不依赖焦点、不模拟按键**，不会误关其他窗口；IDM 进程仍驻留托盘，不影响后台下载。

## 要求

- Windows 10 / 11，PowerShell 5.1 及以上（系统自带）。
