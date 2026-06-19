# Poor Man's T-SQL Formatter — Notepad-- Plugin

[中文说明](README.zh-CN.md)

A T-SQL formatting plugin for [Notepad--](https://github.com/cxasm/notepad--): a Qt/C++ plugin shell plus a cross-platform C# formatter CLI (FmtCli on **.NET 8**).

## Features

- Menu: **Plugins → T-SQL Formatter → Format T-SQL**
- Shortcut: **Ctrl+Alt+F**
- No selection → format the entire document; with a selection → format selected text only
- Options: `formatter.ini` under the app config directory (see [Configuration](#configuration))

## Platform support

| Component | Windows | Linux |
|-----------|---------|-------|
| FmtCli formatter | ✅ | ✅ |
| Notepad-- plugin (`tsqlformatterndd`) | ✅ | 🔜 (FmtCli ready; plugin `.pro` / packaging pending) |

**End users (Windows):** install Notepad-- (plugin edition), [.NET 8 runtime](https://dotnet.microsoft.com/download/dotnet/8.0), and copy the build output into the Notepad-- plugin folder.

## Repository layout

```
├── src/                          Notepad-- plugin (C++/Qt)
├── include/pluginGl.h            Notepad-- plugin API
├── fmtcli/                       Formatter (.NET 8)
│   ├── PoorMansTSqlFormatterFmtCli/
│   ├── PoorMansTSqlFormatterLib/
│   └── PoorMansTSqlFormatterLibShared/
├── third_party/
│   ├── qscint/                   QScintilla headers (compile-time only)
│   └── ndd_importlib/            qmyedit_qt5 import library (Windows)
├── scripts/
│   ├── build-all.ps1             Build FmtCli + plugin (Windows)
│   ├── build-fmtcli.ps1          Build FmtCli (Windows)
│   ├── build-fmtcli.sh           Build FmtCli (Linux)
│   ├── build.ps1                 Build plugin only
│   ├── deploy.ps1                Deploy to Notepad-- (Windows)
│   ├── package-release.ps1       Create release zip
│   └── generate-qmyedit-importlib.ps1
├── global.json                   .NET SDK pin
├── PoorMansTSqlFormatter-Notepad--Plugin.sln
├── tsqlformatterndd.pro
├── releases/                     Release notes (Markdown)
└── out/plugin/                   Build output (git-ignored)
```

## Requirements

### Build

| Component | Notes |
|-----------|--------|
| Notepad-- (plugin edition) | Provides `qmyedit_qt5.dll` / `libqmyedit_qt5.so` for linking |
| Qt 5.15.x | MSVC 2019 64-bit on Windows; distro packages on Linux |
| Visual Studio Build Tools | C++ workload (Windows plugin) |
| [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) | Build FmtCli |

### Run (end users)

| Component | Notes |
|-----------|--------|
| Notepad-- with plugin support | |
| [.NET 8 runtime](https://dotnet.microsoft.com/download/dotnet/8.0) | Required for framework-dependent FmtCli (recommended) |

## Build

### Windows — full build

```powershell
cd PoorMansTSqlFormatter-Notepad--Plugin
.\scripts\build-all.ps1
```

Optional:

```powershell
.\scripts\build-all.ps1 -QtRoot "D:\Qt\5.15.2\msvc2019_64"
.\scripts\build-all.ps1 -RegenerateImportLib   # after upgrading Notepad--
```

### FmtCli only

Framework-dependent (small; requires .NET 8 runtime on the target machine):

```powershell
.\scripts\build-fmtcli.ps1
```

Self-contained single-file (larger; no separate runtime install):

```powershell
.\scripts\build-fmtcli.ps1 -Runtime win-x64 -SelfContained -SingleFile
```

Linux:

```bash
chmod +x scripts/build-fmtcli.sh
./scripts/build-fmtcli.sh Release
# RUNTIME=linux-x64 SELF_CONTAINED=false ./scripts/build-fmtcli.sh
```

### Verify plugin linking (Windows)

```powershell
dumpbin /imports out\plugin\tsqlformatterndd.dll | findstr qmyedit
```

Expect `qmyedit_qt5.dll`. If the plugin is ~1.2 MB instead of ~60 KB, it was likely linked against a static library by mistake.

## Deploy output

After `build-all.ps1`, `out\plugin\` contains:

| File | Description |
|------|-------------|
| `tsqlformatterndd.dll` | Notepad-- plugin (~60 KB) |
| `PoorMansTSqlFormatterFmtCli.exe` | Formatter launcher |
| `PoorMansTSqlFormatterFmtCli.dll` | Formatter assembly (.NET 8) |
| `PoorMansTSqlFormatterFmtCli.deps.json` | Dependency manifest |
| `PoorMansTSqlFormatterFmtCli.runtimeconfig.json` | Runtime config |
| `PoorMansTSqlFormatterLib.dll` | Core formatting library |

Copy **all of these** into the Notepad-- plugin directory. On Linux, the executable has no `.exe` extension (`PoorMansTSqlFormatterFmtCli`).

### Install (Windows)

Close Notepad-- first. Use an elevated shell if installing under `Program Files`:

```powershell
.\scripts\deploy.ps1
```

Default target: `C:\Program Files\Notepad--\plugin\`

## Release package

```powershell
.\scripts\package-release.ps1
.\scripts\package-release.ps1 -SkipBuild   # if out\plugin\ is already current
```

Output (version from `src/version.h`):

- `dist\PoorMansTSqlFormatter-Notepad--Plugin-v1.7.0-win-x64\`
- `dist\PoorMansTSqlFormatter-Notepad--Plugin-v1.7.0-win-x64.zip`

Release descriptions: `releases/v1.7.0.md`. See [CHANGELOG.md](CHANGELOG.md).

## Configuration

Formatter options are stored in `formatter.ini`:

| OS | Typical path |
|----|----------------|
| Windows | `%APPDATA%\ndd-tsqlformatter\formatter.ini` |
| Linux | `~/.config/ndd-tsqlformatter/formatter.ini` (via Qt `AppConfigLocation`) |

Format: `OptionsSerialized=UppercaseKeywords=True,...`

## Architecture

```
Notepad--  →  tsqlformatterndd.dll / .so  →  PoorMansTSqlFormatterFmtCli
              (Qt/C++ plugin)                 (stdin/stdout, .NET 8)
                                                ↓
                                         PoorMansTSqlFormatterLib.dll
```

- The plugin calls FmtCli in a **subprocess** (Win32 pipes on Windows, `QProcess` on Linux), so .NET is not loaded inside the editor process.
- Editor I/O uses Scintilla messages (`SendScintilla`).
- The plugin links **dynamically** to Notepad--'s shared editor library (`qmyedit_qt5.dll` / `.so`).

## License

- **fmtcli/** — derived from [Poor Man's T-SQL Formatter](https://github.com/TaoK/PoorMansTSqlFormatter), [GNU AGPL v3](LICENSE.txt) (© 2011–2017 Tao Klerks)
- **src/** — Notepad-- plugin shell, AGPL v3
- **third_party/qscint/** — QScintilla headers (their respective licenses)
- **include/pluginGl.h** — Notepad-- plugin API

## Acknowledgements

- [Poor Man's T-SQL Formatter](https://github.com/TaoK/PoorMansTSqlFormatter) — Tao Klerks
- [Notepad--](https://github.com/cxasm/notepad--) — cxasm
