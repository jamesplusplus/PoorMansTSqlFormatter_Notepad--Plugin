# Poor Man's T-SQL Formatter — Notepad-- Plugin

[中文说明](README.zh-CN.md)

A T-SQL formatting plugin for [Notepad--](https://github.com/cxasm/notepad--): a Qt/C++ plugin shell plus a C# command-line formatter (FmtCli).

## Features

- Menu: **Plugins → T-SQL Formatter → Format T-SQL**
- Shortcut: **Ctrl+Alt+F**
- No selection: format the entire document; with a selection: format the selected text only
- Options file: `%APPDATA%\ndd-tsqlformatter\formatter.ini`

## Repository layout

```
├── src/                          Notepad-- plugin (C++/Qt)
├── include/pluginGl.h            Notepad-- plugin API header
├── fmtcli/                       Formatter (C# / .NET Framework 4.8)
│   ├── PoorMansTSqlFormatterFmtCli/
│   ├── PoorMansTSqlFormatterLib/
│   └── PoorMansTSqlFormatterLibShared/
├── third_party/
│   ├── qscint/                   QScintilla headers (compile-time only)
│   └── ndd_importlib/            qmyedit_qt5.dll import library
├── scripts/
│   ├── build-all.ps1             Build everything
│   ├── build-fmtcli.ps1          Build FmtCli only
│   ├── build.ps1                 Build FmtCli + plugin
│   ├── deploy.ps1                Deploy to Notepad--
│   └── generate-qmyedit-importlib.ps1
├── PoorMansTSqlFormatter-Notepad--Plugin.sln
├── tsqlformatterndd.pro
└── out/plugin/                   Build output for deployment (git-ignored)
```

## Requirements

| Component | Version / notes |
|-----------|-----------------|
| Notepad-- (plugin edition) | Installed, includes `qmyedit_qt5.dll` |
| Qt | 5.15.x, MSVC 2019 64-bit |
| Visual Studio Build Tools | C++ workload + .NET Framework 4.8 targeting pack |
| .NET 8 runtime | Required to run FmtCli ([download](https://dotnet.microsoft.com/download/dotnet/8.0)) |

## Build

```powershell
cd PoorMansTSqlFormatter-Notepad--Plugin
.\scripts\build-all.ps1
```

Output goes to `out\plugin\`:

| File | Description |
|------|-------------|
| `tsqlformatterndd.dll` | Notepad-- plugin (~60 KB, dynamically links `qmyedit_qt5.dll`) |
| `PoorMansTSqlFormatterFmtCli.exe` | stdin/stdout formatter |
| `PoorMansTSqlFormatterLib.dll` | Core formatting library (framework-dependent build) |

FmtCli targets **.NET 8** and runs on Windows and Linux. Build with `dotnet` 8 SDK:

```powershell
.\scripts\build-fmtcli.ps1                     # Windows, framework-dependent
.\scripts\build-fmtcli.ps1 -Runtime win-x64 -SelfContained -SingleFile   # optional single-file
```

Linux:

```bash
./scripts/build-fmtcli.sh Release
# or: RUNTIME=linux-x64 ./scripts/build-fmtcli.sh
```

Optional flags:

```powershell
.\scripts\build-all.ps1 -QtRoot "D:\Qt\5.15.2\msvc2019_64"
.\scripts\build-all.ps1 -RegenerateImportLib   # After upgrading Notepad--
.\scripts\build-fmtcli.ps1                     # C# projects only
```

Verify the plugin links against the shared editor DLL:

```powershell
dumpbin /imports out\plugin\tsqlformatterndd.dll | findstr qmyedit
```

You should see `qmyedit_qt5.dll`. If the plugin DLL is much larger (~1.2 MB), it was likely linked statically by mistake.

## Deploy

Close Notepad-- first. Use an **elevated** PowerShell if deploying under `Program Files`:

```powershell
.\scripts\deploy.ps1
```

By default, files are copied to `C:\Program Files\Notepad--\plugin\`.

## Release package

Build and create a distributable zip (version from `src/version.h`):

```powershell
.\scripts\package-release.ps1
```

Output:

- `dist\PoorMansTSqlFormatter-Notepad--Plugin-v1.7.0-win-x64\` — folder to upload or copy
- `dist\PoorMansTSqlFormatter-Notepad--Plugin-v1.7.0-win-x64.zip` — GitHub Release asset

Skip rebuild if `out\plugin\` is already up to date:

```powershell
.\scripts\package-release.ps1 -SkipBuild
```

See [CHANGELOG.md](CHANGELOG.md) for release notes.

## Architecture

```
Notepad--  →  tsqlformatterndd.dll  →  PoorMansTSqlFormatterFmtCli.exe
              (Qt plugin)                (stdin/stdout, .NET 4.8)
                                           ↓
                                    PoorMansTSqlFormatterLib.dll
```

The plugin invokes FmtCli through Win32 pipes, avoiding .NET inside the Qt plugin process. Editor reads/writes use Scintilla messages (`SendScintilla`) and dynamic linking to Notepad--'s bundled `qmyedit_qt5.dll`.

## License

- **fmtcli/** (`PoorMansTSqlFormatterLib*`, `PoorMansTSqlFormatterFmtCli`): derived from [Poor Man's T-SQL Formatter](https://github.com/TaoK/PoorMansTSqlFormatter), [GNU AGPL v3](LICENSE.txt) (Copyright © 2011–2017 Tao Klerks).
- **src/** (Notepad-- plugin shell): same AGPL v3, distributed with the formatter library.
- **third_party/qscint/**: QScintilla headers, subject to their respective licenses.
- **include/pluginGl.h**: derived from the Notepad-- plugin API.

## Publish to GitHub

```powershell
cd PoorMansTSqlFormatter-Notepad--Plugin
git init
git add .
git commit -m "Initial commit: Notepad-- T-SQL formatter plugin with FmtCli"
git branch -M main
git remote add origin https://github.com/YOUR_USER/YOUR_REPO.git
git push -u origin main
```

Mention in the repository description that users need Notepad-- (plugin edition) and the .NET 8 runtime.

## Acknowledgements

- [Poor Man's T-SQL Formatter](https://github.com/TaoK/PoorMansTSqlFormatter) — Tao Klerks
- [Notepad--](https://github.com/cxasm/notepad--) — cxasm
