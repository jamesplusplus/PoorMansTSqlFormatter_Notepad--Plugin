# Poor Man's T-SQL Formatter — Notepad-- 插件

[English README](README.md)

为 [Notepad--](https://github.com/cxasm/notepad--) 提供的 T-SQL 格式化插件：Qt/C++ 插件壳 + C# 命令行格式化器（FmtCli）。

## 功能

- 菜单：**Plugins → T-SQL Formatter → Format T-SQL**
- 快捷键：**Ctrl+Alt+F**
- 无选区：格式化整篇文档；有选区：仅格式化选中部分
- 选项文件：`%APPDATA%\ndd-tsqlformatter\formatter.ini`

## 仓库结构

```
├── src/                          Notepad-- 插件 (C++/Qt)
├── include/pluginGl.h            Notepad-- 插件 API
├── fmtcli/                       格式化器 (C# / .NET Framework 4.8)
│   ├── PoorMansTSqlFormatterFmtCli/
│   ├── PoorMansTSqlFormatterLib/
│   └── PoorMansTSqlFormatterLibShared/
├── third_party/
│   ├── qscint/                   QScintilla 头文件（仅编译期）
│   └── ndd_importlib/            qmyedit_qt5.dll import library
├── scripts/
│   ├── build-all.ps1             一键编译全部
│   ├── build-fmtcli.ps1          仅编译 FmtCli
│   ├── build.ps1                 编译 FmtCli + 插件
│   ├── deploy.ps1                部署到 Notepad--
│   └── generate-qmyedit-importlib.ps1
├── PoorMansTSqlFormatter-Notepad--Plugin.sln
├── tsqlformatterndd.pro
└── out/plugin/                   编译产物（部署用，git 忽略）
```

## 依赖

| 组件 | 版本 / 说明 |
|------|-------------|
| Notepad--（插件版） | 已安装，含 `qmyedit_qt5.dll` |
| Qt | 5.15.x，MSVC 2019 64-bit |
| Visual Studio Build Tools | C++ 工作负载 + .NET Framework 4.8 开发包 |
| .NET Framework 4.8 运行时 | 运行 FmtCli（Windows 通常已预装） |

## 编译

```powershell
cd PoorMansTSqlFormatter-Notepad--Plugin
.\scripts\build-all.ps1
```

产物位于 `out\plugin\`：

| 文件 | 说明 |
|------|------|
| `tsqlformatterndd.dll` | Notepad-- 插件（约 60 KB，动态链接 `qmyedit_qt5.dll`） |
| `PoorMansTSqlFormatterFmtCli.exe` | stdin/stdout 格式化器 |
| `PoorMansTSqlFormatterLib.dll` | 格式化核心库 |

可选参数：

```powershell
.\scripts\build-all.ps1 -QtRoot "D:\Qt\5.15.2\msvc2019_64"
.\scripts\build-all.ps1 -RegenerateImportLib   # 升级 Notepad-- 后重新生成 import lib
.\scripts\build-fmtcli.ps1                     # 仅编译 C# 部分
```

验证插件是否正确动态链接：

```powershell
dumpbin /imports out\plugin\tsqlformatterndd.dll | findstr qmyedit
```

## 部署

先退出 Notepad--。若目标在 `Program Files`，需**管理员** PowerShell：

```powershell
.\scripts\deploy.ps1
```

默认复制到 `C:\Program Files\Notepad--\plugin\`。

## 架构

```
Notepad--  →  tsqlformatterndd.dll  →  PoorMansTSqlFormatterFmtCli.exe
              (Qt 插件)                  (stdin/stdout, .NET 4.8)
                                           ↓
                                    PoorMansTSqlFormatterLib.dll
```

插件通过 Win32 管道调用 FmtCli，避免在 Qt 插件进程内加载 .NET。编辑器读写使用 Scintilla 消息（`SendScintilla`），与 Notepad-- 自带的 `qmyedit_qt5.dll` 动态链接。

## 许可证

- **fmtcli/**（`PoorMansTSqlFormatterLib*`、`PoorMansTSqlFormatterFmtCli`）：基于 [Poor Man's T-SQL Formatter](https://github.com/TaoK/PoorMansTSqlFormatter)，[GNU AGPL v3](LICENSE.txt)（Copyright © 2011–2017 Tao Klerks）。
- **src/**（Notepad-- 插件壳）：同上 AGPL v3，与格式化库一并分发。
- **third_party/qscint/**：QScintilla 头文件，遵循其各自许可证。
- **include/pluginGl.h**：源自 Notepad-- 插件 API。

## 发布到 GitHub

```powershell
cd PoorMansTSqlFormatter-Notepad--Plugin
git init
git add .
git commit -m "Initial commit: Notepad-- T-SQL formatter plugin with FmtCli"
git branch -M main
git remote add origin https://github.com/YOUR_USER/YOUR_REPO.git
git push -u origin main
```

建议在 GitHub 仓库描述中注明：需要 Notepad-- 插件版 + .NET Framework 4.8。

## 致谢

- [Poor Man's T-SQL Formatter](https://github.com/TaoK/PoorMansTSqlFormatter) — Tao Klerks
- [Notepad--](https://github.com/cxasm/notepad--) — cxasm
