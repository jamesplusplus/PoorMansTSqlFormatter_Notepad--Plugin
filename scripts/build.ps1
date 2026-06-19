param(
    [string]$QtRoot = "C:\Qt\5.15.2\msvc2019_64",
    [ValidateSet("Release", "Debug")]
    [string]$Configuration = "Release",
    [switch]$RegenerateImportLib,
    [string]$NotepadRoot = "C:\Program Files\Notepad--",
    [switch]$SkipFmtCli
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot

if (-not $SkipFmtCli) {
    & (Join-Path $PSScriptRoot "build-fmtcli.ps1") -Configuration $Configuration
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$qmake = Join-Path $QtRoot "bin\qmake.exe"
if (-not (Test-Path $qmake)) {
    Write-Error "qmake not found: $qmake`nSet -QtRoot to your Qt 5.15 msvc2019_64 install."
}

$vcvars = Get-ChildItem "${env:ProgramFiles(x86)}\Microsoft Visual Studio" -Recurse -Filter vcvars64.bat -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $vcvars) {
    Write-Error "vcvars64.bat not found. Install Visual Studio Build Tools (C++)."
}

if ($RegenerateImportLib) {
    & (Join-Path $PSScriptRoot "generate-qmyedit-importlib.ps1") -NotepadRoot $NotepadRoot
}

$importLib = Join-Path $projectRoot "third_party\ndd_importlib\qmyedit_qt5.lib"
if (-not (Test-Path $importLib)) {
    Write-Host "Import library missing; generating from $NotepadRoot ..."
    & (Join-Path $PSScriptRoot "generate-qmyedit-importlib.ps1") -NotepadRoot $NotepadRoot
}

$configFlag = if ($Configuration -eq "Debug") { "CONFIG+=debug" } else { "CONFIG+=release" }
$buildCmd = "`"$vcvars`" && cd /d `"$projectRoot`" && `"$qmake`" tsqlformatterndd.pro $configFlag && nmake"

Write-Host "Building plugin ($Configuration) ..."
cmd.exe /c $buildCmd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$dll = Join-Path $projectRoot "out\plugin\tsqlformatterndd.dll"
if (Test-Path $dll) {
    $sizeKb = [math]::Round((Get-Item $dll).Length / 1KB, 1)
    Write-Host "OK: $dll ($sizeKb KB)"
    if ($sizeKb -gt 200) {
        Write-Warning "DLL is larger than expected (~60 KB). It may be statically linked; run dumpbin /imports on the DLL."
    }
} else {
    Write-Error "Build finished but DLL not found: $dll"
}

Write-Host ""
Write-Host "Deploy bundle in: $(Join-Path $projectRoot 'out\plugin')"
