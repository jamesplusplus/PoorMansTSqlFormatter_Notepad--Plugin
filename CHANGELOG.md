# Release notes

## Unreleased

### Changed

- **FmtCli migrated to .NET 8** — cross-platform (Windows / Linux); requires [.NET 8 runtime](https://dotnet.microsoft.com/download/dotnet/8.0) for framework-dependent builds.
- Build with `dotnet` SDK 8 instead of .NET Framework 4.8 MSBuild.

## v1.7.0 — 2026-06-19

Initial release for Notepad-- (plugin edition).

### Included

- `tsqlformatterndd.dll` — Notepad-- plugin (Qt/C++, dynamically links `qmyedit_qt5.dll`)
- `PoorMansTSqlFormatterFmtCli.exe` — T-SQL formatter CLI (stdin/stdout)
- `PoorMansTSqlFormatterLib.dll` — formatting library

### Features

- Format entire document or selection only
- Menu: **Plugins → T-SQL Formatter → Format T-SQL**
- Shortcut: **Ctrl+Alt+F**
- Options stored in `%APPDATA%\ndd-tsqlformatter\formatter.ini`

### Requirements

- Notepad-- with plugin support
- .NET Framework 4.8 runtime (Windows)

### Build from source

```powershell
.\scripts\build-all.ps1
.\scripts\package-release.ps1
```

Output: `dist\PoorMansTSqlFormatter-Notepad--Plugin-v1.7.0-win-x64.zip`
