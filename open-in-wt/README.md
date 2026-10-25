# open-in-wt

> 为**便携版（解压版）**Windows Terminal 补上系统级集成：右键【在终端中打开】+ Win+R 输入 `wt` 直接启动。
>
> Add an "Open in Windows Terminal" context menu and a `wt` command for the Run dialog (Win+R) to **portable / unzipped** Windows Terminal on Windows 10/11.

## 为什么需要这个项目

从 Microsoft Store 安装的 Windows Terminal（1.1+）会自动注册右键菜单；但**解压即用**的便携版不会向系统注册任何信息，导致：

- 右键文件夹 / 文件夹空白处，没有【在终端中打开】
- Win+R 输入 `wt` 无法启动（而 `cmd` 可以，因为系统在 `App Paths` 里登记过）

本项目用一个纯注册表脚本把这两件事补上，机制与系统对 `cmd` 的处理完全一致。

## 功能特性

- ✅ 右键【文件夹】【文件夹空白处】【磁盘】【磁盘空白处】→ 在终端中打开（带终端图标）
- ✅ Win+R 输入 `wt` 回车 → 启动 Windows Terminal，支持参数（如 `wt -d E:\project`）
- ✅ 纯注册表方案：不联网、不修改终端本体、卸载即完全还原
- ✅ 无乱码：主脚本为 UTF-8 with BOM 的 PowerShell，启动器为纯 ASCII 批处理，任何语言区域的 Windows 上都正常显示

## 快速开始

```bat
git clone https://github.com/<你的用户名>/open-in-wt.git
```

或直接在 GitHub 页面点 **Code → Download ZIP** 下载解压。然后：

1. **双击 `install.bat`** → UAC 窗口点"是" → 看到"安装完成"即可（可重复运行，幂等）
2. 验证：
   - 右键任意**文件夹** → 【在终端中打开】→ 点击后在该目录打开终端
   - 打开文件夹，在**空白处**右键 → 同样出现该菜单（桌面空白处也生效）
   - **Win+R** 输入 `wt` 回车 → 启动 Windows Terminal

不想双击？右键 `install.ps1` → 选择"使用 PowerShell 运行"，效果相同。

**卸载**：双击 `uninstall.bat`。

## 工作原理

| 注册表键 | 作用 |
|----------|------|
| `HKCR\Directory\shell\OpenInWT` | 右键【文件夹】时显示菜单 |
| `HKCR\Directory\Background\shell\OpenInWT` | 文件夹窗口【空白处】右键（含桌面空白处） |
| `HKCR\Drive\shell\OpenInWT` | 右键【磁盘分区】图标 |
| `HKCR\Drive\Background\shell\OpenInWT` | 磁盘根目录【空白处】右键 |
| `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\wt.exe` | 让 `wt` 成为系统可识别的命令 |

菜单命令的本质是一行注册表字符串：

```text
"E:\lib\WindowsTerminal\WindowsTerminal.exe" -d "%V"
```

- `%V` 是资源管理器在右键时替换进去的目录（所选文件夹或当前所在目录）
- `-d` 是 Windows Terminal 的参数，指定起始目录
- 磁盘（Drive）两处用的是**不加引号**的 `%V`：盘符路径没有空格，且自带尾部 `\`，
  放进引号会被参数解析器误认为转义引号导致目录失效，所以特意不加引号

Win+R 之所以能运行 `cmd`，正是因为 `App Paths` 下登记了 `cmd.exe`；本脚本给
`wt.exe` 做了同样的登记（优先使用解压目录里自带的 `wt.exe`）。

## 文件说明

| 文件 | 作用 |
|------|------|
| `install.ps1` | 安装脚本主体（UTF-8 with BOM，中文提示，自动申请管理员权限） |
| `uninstall.ps1` | 卸载脚本主体 |
| `install.bat` | 双击启动器（纯 ASCII），调用 `install.ps1` |
| `uninstall.bat` | 双击启动器（纯 ASCII），调用 `uninstall.ps1` |

## 自定义

编辑 `install.ps1` 顶部配置区后重新运行（可重复执行）：

- `$WtDir`：Windows Terminal 解压目录（换了位置就改这里）
- `$MenuText`：右键菜单文字，如改成 `'通过 WT 打开'`

## 常见问题

- **双击 .ps1 打开的是记事本？** 系统默认行为，请改用双击 .bat 启动器，或右键
  .ps1 选"使用 PowerShell 运行"。
- **右键菜单没出现？** 注销重新登录，或在任务管理器里重启"Windows 资源管理器"。
- **cmd / PowerShell 里直接敲 `wt` 没反应？** `App Paths` 只被 Win+R、资源管理器
  地址栏、`start` 命令等使用，cmd 内部不查询它。cmd 里用 `start wt`，PowerShell
  里用 `start wt` 或 `Start-Process wt`。想随处直接敲 `wt`，把解压目录加入系统
  环境变量 `Path` 即可（解压目录里本就带有 wt.exe）。
- **wt 想带参数？** Win+R 里同样支持，例如 `wt -d E:\project`（指定目录）、
  `wt -p "PowerShell"`（指定配置文件）等。
- **Windows 11 注意**：本脚本在 Win10 上菜单直接显示；Win11 需点"显示更多选项"
  （Shift+F10）才能看到经典菜单项。
- **脚本里有中文会不会乱码？** 不会。ps1 是 UTF-8 with BOM，PowerShell 在任何
  语言区域都能正确解析；bat 启动器是纯 ASCII，无编码依赖。

## 给修改后再分享的网友

- `install.ps1` / `uninstall.ps1` **必须保存为 UTF-8 with BOM 编码**（记事本
  "另存为"选择"UTF-8 (BOM)"），否则 PowerShell 会在部分语言区域解析出乱码。
- `install.bat` / `uninstall.bat` 是纯 ASCII 启动器，请勿往里添加中文。
- 本脚本仅写注册表，不联网、不修改终端本体，可随时用 uninstall 完全还原。

## 许可证

[MIT](LICENSE)
