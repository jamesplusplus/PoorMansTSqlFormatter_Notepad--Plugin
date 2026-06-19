# Copy out/plugin/* into Notepad-- plugin folder (requires admin if under Program Files).
param(
    [string]$NotepadPluginDir = "C:\Program Files\Notepad--\plugin",
    [string]$BundleDir = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($BundleDir)) {
    $BundleDir = Join-Path $projectRoot "out\plugin"
}

$files = @(
    "tsqlformatterndd.dll",
    "PoorMansTSqlFormatterFmtCli.exe",
    "PoorMansTSqlFormatterLib.dll"
)

foreach ($name in $files) {
    $path = Join-Path $BundleDir $name
    if (-not (Test-Path $path)) {
        Write-Error "Missing: $path`nRun .\scripts\build-all.ps1 first."
    }
}

if (-not (Test-Path $NotepadPluginDir)) {
    New-Item -ItemType Directory -Force -Path $NotepadPluginDir | Out-Null
}

foreach ($name in $files) {
    Copy-Item -Force (Join-Path $BundleDir $name) (Join-Path $NotepadPluginDir $name)
}

Write-Host "Deployed to $NotepadPluginDir"
foreach ($name in $files) {
    Write-Host "  $name"
}
Write-Host ""
Write-Host "Restart Notepad--. Menu: Plugins -> T-SQL Formatter -> Format T-SQL (Ctrl+Alt+F)"
