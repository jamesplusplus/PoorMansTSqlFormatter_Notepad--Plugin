# Build Release and create a distributable zip under dist/.
param(
    [string]$Version = "",
    [string]$QtRoot = "C:\Qt\5.15.2\msvc2019_64",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$versionFile = Join-Path $projectRoot "src\version.h"

if ([string]::IsNullOrWhiteSpace($Version)) {
    $versionLine = Get-Content $versionFile -Raw
    if ($versionLine -match 'NDD_TSQL_FORMATTER_VERSION\s+"([^"]+)"') {
        $Version = $matches[1].TrimStart('v')
    } else {
        Write-Error "Could not parse version from $versionFile"
    }
}

$versionTag = if ($Version -match '^v') { $Version } else { "v$Version" }

if (-not $SkipBuild) {
    & (Join-Path $PSScriptRoot "build-all.ps1") -QtRoot $QtRoot -Configuration Release
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$bundleDir = Join-Path $projectRoot "out\plugin"
$required = @(
    "tsqlformatterndd.dll",
    "PoorMansTSqlFormatterFmtCli.exe",
    "PoorMansTSqlFormatterFmtCli.dll",
    "PoorMansTSqlFormatterFmtCli.deps.json",
    "PoorMansTSqlFormatterFmtCli.runtimeconfig.json"
)

foreach ($name in $required) {
    if (-not (Test-Path (Join-Path $bundleDir $name))) {
        Write-Error "Missing build output: $(Join-Path $bundleDir $name)"
    }
}

$optional = @("PoorMansTSqlFormatterLib.dll")

$distRoot = Join-Path $projectRoot "dist"
$stageDir = Join-Path $distRoot "PoorMansTSqlFormatter-Notepad--Plugin-$versionTag-win-x64"
if (Test-Path $stageDir) {
    Remove-Item -Recurse -Force $stageDir
}
New-Item -ItemType Directory -Force -Path $stageDir | Out-Null

foreach ($name in $required) {
    Copy-Item -Force (Join-Path $bundleDir $name) $stageDir
}
foreach ($name in $optional) {
    $path = Join-Path $bundleDir $name
    if (Test-Path $path) {
        Copy-Item -Force $path $stageDir
    }
}

Copy-Item -Force (Join-Path $projectRoot "LICENSE.txt") $stageDir
Copy-Item -Force (Join-Path $projectRoot "README.md") $stageDir

$installText = @"
Poor Man's T-SQL Formatter — Notepad-- Plugin $versionTag (Windows x64)
======================================================================

Requirements
  - Notepad-- with plugin support (plugin edition)
  - .NET 8 runtime (https://dotnet.microsoft.com/download/dotnet/8.0)

Install
  1. Close Notepad--.
  2. Copy all files from this folder into your Notepad-- plugin directory:
       C:\Program Files\Notepad--\plugin\
     (Use an elevated shell if installing under Program Files.)
  3. Restart Notepad--.

Usage
  Menu:   Plugins -> T-SQL Formatter -> Format T-SQL
  Shortcut: Ctrl+Alt+F
  Options:  %APPDATA%\ndd-tsqlformatter\formatter.ini

Files
  tsqlformatterndd.dll                        Notepad-- plugin
  PoorMansTSqlFormatterFmtCli.exe             Formatter launcher
  PoorMansTSqlFormatterFmtCli.dll             Formatter (.NET 8)
  PoorMansTSqlFormatterFmtCli.deps.json
  PoorMansTSqlFormatterFmtCli.runtimeconfig.json
  PoorMansTSqlFormatterLib.dll                Formatter library

License: GNU AGPL v3 — see LICENSE.txt
"@
Set-Content -Path (Join-Path $stageDir "INSTALL.txt") -Value $installText -Encoding UTF8

$zipName = "PoorMansTSqlFormatter-Notepad--Plugin-$versionTag-win-x64.zip"
$zipPath = Join-Path $distRoot $zipName
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($stageDir, $zipPath)

$releaseDate = Get-Date -Format "yyyy-MM-dd"
$releasesDir = Join-Path $projectRoot "releases"
New-Item -ItemType Directory -Force -Path $releasesDir | Out-Null

$releaseEn = @"
# Poor Man's T-SQL Formatter — Notepad-- Plugin $versionTag

**Platform:** Windows x64  
**Date:** $releaseDate

T-SQL formatting plugin for [Notepad--](https://github.com/cxasm/notepad--) (plugin edition), based on [Poor Man's T-SQL Formatter](https://github.com/TaoK/PoorMansTSqlFormatter).

## Download

| Asset | Description |
|-------|-------------|
| ``PoorMansTSqlFormatter-Notepad--Plugin-$versionTag-win-x64.zip`` | Prebuilt plugin + formatter |

## What's included

| File | Description |
|------|-------------|
| ``tsqlformatterndd.dll`` | Notepad-- plugin (Qt/C++) |
| ``PoorMansTSqlFormatterFmtCli.exe`` | T-SQL formatter CLI (stdin/stdout) |
| ``PoorMansTSqlFormatterLib.dll`` | Core formatting library |
| ``INSTALL.txt`` | Installation instructions |
| ``LICENSE.txt`` | GNU AGPL v3 |

## Features

- Format the **entire document** or **selected text only**
- Menu: **Plugins → T-SQL Formatter → Format T-SQL**
- Shortcut: **Ctrl+Alt+F**
- Formatter options: ``%APPDATA%\ndd-tsqlformatter\formatter.ini``

## Requirements

- [Notepad--](https://github.com/cxasm/notepad--) with **plugin support** (plugin edition, includes ``qmyedit_qt5.dll``)
- [.NET Framework 4.8](https://dotnet.microsoft.com/download/dotnet-framework/net48) runtime

## Installation

1. Close Notepad--.
2. Extract the zip.
3. Copy **all files** into ``C:\Program Files\Notepad--\plugin\`` (elevated shell if needed).
4. Restart Notepad--.

## Usage

Press **Ctrl+Alt+F** or use **Plugins → T-SQL Formatter → Format T-SQL**.

## License

GNU **AGPL v3** — see [LICENSE.txt](../LICENSE.txt). Formatter library: Copyright © 2011–2017 Tao Klerks.

See [CHANGELOG.md](../CHANGELOG.md) for full changelog.
"@

$releaseEnPath = Join-Path $releasesDir "$versionTag.md"
$releaseEnDist = Join-Path $distRoot "RELEASE-$versionTag.md"
Set-Content -Path $releaseEnPath -Value $releaseEn -Encoding UTF8
Set-Content -Path $releaseEnDist -Value $releaseEn -Encoding UTF8

Write-Host ""
Write-Host "Release $versionTag ready:"
Write-Host "  Folder: $stageDir"
Write-Host "  Zip:    $zipPath"
Write-Host "  Notes:  $releaseEnPath"
Write-Host "          $releaseEnDist"
Get-ChildItem $stageDir | ForEach-Object {
    $kb = [math]::Round($_.Length / 1KB, 1)
    Write-Host ("  {0,-40} {1,6} KB" -f $_.Name, $kb)
}
$zipKb = [math]::Round((Get-Item $zipPath).Length / 1KB, 1)
Write-Host ""
Write-Host "Zip size: $zipKb KB"
