# Poor Man's T-SQL Formatter — Notepad-- 插件

[English README](README.md)

为 [Notepad--](https://github.com/cxasm/notepad--) 提供的 T-SQL 格式化插件：Qt/C++ 插件壳 + 跨平台 C# 命令行格式化器（FmtCli，**.NET 8**）。

## 功能

- 菜单：**Plugins → T-SQL Formatter → Format T-SQL**
- 快捷键：**Ctrl+Alt+F**
- 无选区 → 格式化整篇文档；有选区 → 仅格式化选中部分
- 选项：应用配置目录下的 `formatter.ini`（见 [配置](#配置)）

## 平台支持

| 组件 | Windows | Linux |
|------|---------|-------|
| FmtCli 格式化器 | ✅ | ✅ |
| Notepad-- 插件（`tsqlformatterndd`） | ✅ | 🔜（FmtCli 已就绪，插件 `.pro` / 打包待完善） |

**Windows 用户：** 安装 Notepad-- 插件版、[.NET 8 运行时](https://dotnet.microsoft.com/download/dotnet/8.0)，将编译产物复制到 Notepad-- 的 plugin 目录即可。

## 仓库结构

```
├── src/                          Notepad-- 插件 (C++/Qt)
├── include/pluginGl.h            Notepad-- 插件 API
├── fmtcli/                       格式化器 (.NET 8)
│   ├── PoorMansTSqlFormatterFmtCli/
│   ├── PoorMansTSqlFormatterLib/
│   └── PoorMansTSqlFormatterLibShared/
├── third_party/
│   ├── qscint/                   QScintilla 头文件（仅编译期）
│   └── ndd_importlib/            qmyedit_qt5 import library（Windows）
├── scripts/
│   ├── build-all.ps1             编译 FmtCli + 插件（Windows）
│   ├── build-fmtcli.ps1          仅编译 FmtCli（Windows）
│   ├── build-fmtcli.sh           仅编译 FmtCli（Linux）
│   ├── build.ps1                 仅编译插件
│   ├── deploy.ps1                部署到 Notepad--（Windows）
│   ├── package-release.ps1       生成发布 zip
│   └── generate-qmyedit-importlib.ps1
├── global.json                   .NET SDK 版本
├── PoorMansTSqlFormatter-Notepad--Plugin.sln
├── tsqlformatterndd.pro
├── releases/                     发布说明（Markdown）
└── out/plugin/                   编译产物（git 忽略）
```

## 依赖

### 编译

| 组件 | 说明 |
|------|------|
| Notepad--（插件版） | 提供 `qmyedit_qt5.dll` / `libqmyedit_qt5.so` 用于链接 |
| Qt 5.15.x | Windows：MSVC 2019 64-bit；Linux：系统 Qt 开发包 |
| Visual Studio Build Tools | C++ 工作负载（Windows 插件） |
| [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) | 编译 FmtCli |

### 运行（最终用户）

| 组件 | 说明 |
|------|------|
| 支持插件的 Notepad-- | |
| [.NET 8 运行时](https://dotnet.microsoft.com/download/dotnet/8.0) | 框架依赖版 FmtCli 需要（推荐） |

## 编译

### Windows — 完整编译

```powershell
cd PoorMansTSqlFormatter-Notepad--Plugin
.\scripts\build-all.ps1
```

可选参数：

```powershell
.\scripts\build-all.ps1 -QtRoot "D:\Qt\5.15.2\msvc2019_64"
.\scripts\build-all.ps1 -RegenerateImportLib   # 升级 Notepad-- 后
```

### 仅编译 FmtCli

框架依赖（体积小，目标机器需安装 .NET 8 运行时）：

```powershell
.\scripts\build-fmtcli.ps1
```

自包含单文件（体积大，无需单独安装运行时）：

```powershell
.\scripts\build-fmtcli.ps1 -Runtime win-x64 -SelfContained -SingleFile
```

Linux：

```bash
chmod +x scripts/build-fmtcli.sh
./scripts/build-fmtcli.sh Release
```

### 验证插件动态链接（Windows）

```powershell
dumpbin /imports out\plugin\tsqlformatterndd.dll | findstr qmyedit
```

应看到 `qmyedit_qt5.dll`。若插件约 1.2 MB 而非 ~60 KB，可能误链了静态库。

## 部署文件

执行 `build-all.ps1` 后，`out\plugin\` 包含：

| 文件 | 说明 |
|------|------|
| `tsqlformatterndd.dll` | Notepad-- 插件（约 60 KB） |
| `PoorMansTSqlFormatterFmtCli.exe` | 格式化器启动程序 |
| `PoorMansTSqlFormatterFmtCli.dll` | 格式化器主程序集（.NET 8） |
| `PoorMansTSqlFormatterFmtCli.deps.json` | 依赖清单 |
| `PoorMansTSqlFormatterFmtCli.runtimeconfig.json` | 运行时配置 |
| `PoorMansTSqlFormatterLib.dll` | 格式化核心库 |

**以上文件需全部复制**到 Notepad-- 的 plugin 目录。Linux 下可执行文件无 `.exe` 后缀（`PoorMansTSqlFormatterFmtCli`）。

### 安装（Windows）

先退出 Notepad--。若目标在 `Program Files`，需**管理员** PowerShell：

```powershell
.\scripts\deploy.ps1
```

默认目标：`C:\Program Files\Notepad--\plugin\`

## 发布包

```powershell
.\scripts\package-release.ps1
.\scripts\package-release.ps1 -SkipBuild   # out\plugin\ 已是最新时可跳过编译
```

输出（版本号来自 `src/version.h`）：

- `dist\PoorMansTSqlFormatter-Notepad--Plugin-v1.7.0-win-x64\`
- `dist\PoorMansTSqlFormatter-Notepad--Plugin-v1.7.0-win-x64.zip`

发布说明见 `releases/v1.7.0.md`，完整日志见 [CHANGELOG.md](CHANGELOG.md)。

## 配置

格式化选项保存在 `formatter.ini`：

| 系统 | 典型路径 |
|------|----------|
| Windows | `%APPDATA%\ndd-tsqlformatter\formatter.ini` |
| Linux | `~/.config/ndd-tsqlformatter/formatter.ini` |

格式：`OptionsSerialized=UppercaseKeywords=True,...`

## 架构

```
Notepad--  →  tsqlformatterndd.dll / .so  →  PoorMansTSqlFormatterFmtCli
              (Qt/C++ 插件)                   (stdin/stdout, .NET 8)
                                                ↓
                                         PoorMansTSqlFormatterLib.dll
```

- 插件通过**子进程**调用 FmtCli（Windows：Win32 管道；Linux：`QProcess`），不在编辑器进程内加载 .NET。
- 编辑器读写使用 Scintilla 消息（`SendScintilla`）。
- 插件与 Notepad-- 自带的编辑器库**动态链接**（`qmyedit_qt5.dll` / `.so`）。

## 许可证

- **fmtcli/** — 基于 [Poor Man's T-SQL Formatter](https://github.com/TaoK/PoorMansTSqlFormatter)，[GNU AGPL v3](LICENSE.txt)（© 2011–2017 Tao Klerks）
- **src/** — Notepad-- 插件壳，AGPL v3
- **third_party/qscint/** — QScintilla 头文件
- **include/pluginGl.h** — Notepad-- 插件 API

## 致谢

- [Poor Man's T-SQL Formatter](https://github.com/TaoK/PoorMansTSqlFormatter) — Tao Klerks
- [Notepad--](https://github.com/cxasm/notepad--) — cxasm
