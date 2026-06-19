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

$required = @("tsqlformatterndd.dll", "PoorMansTSqlFormatterFmtCli.exe")
$fmtCliArtifacts = @(
    "PoorMansTSqlFormatterFmtCli.dll",
    "PoorMansTSqlFormatterFmtCli.deps.json",
    "PoorMansTSqlFormatterFmtCli.runtimeconfig.json",
    "PoorMansTSqlFormatterLib.dll"
)

foreach ($name in $required) {
    $path = Join-Path $BundleDir $name
    if (-not (Test-Path $path)) {
        Write-Error "Missing: $path`nRun .\scripts\build-all.ps1 first."
    }
}

if (-not (Test-Path $NotepadPluginDir)) {
    New-Item -ItemType Directory -Force -Path $NotepadPluginDir | Out-Null
}

$deployed = @()
foreach ($name in ($required + $fmtCliArtifacts)) {
    $path = Join-Path $BundleDir $name
    if (Test-Path $path) {
        Copy-Item -Force $path (Join-Path $NotepadPluginDir $name)
        $deployed += $name
    }
}

Write-Host "Deployed to $NotepadPluginDir"
foreach ($name in $deployed) {
    Write-Host "  $name"
}
Write-Host ""
Write-Host "Requires .NET 8 runtime: https://dotnet.microsoft.com/download/dotnet/8.0"
Write-Host "Restart Notepad--. Menu: Plugins -> T-SQL Formatter -> Format T-SQL (Ctrl+Alt+F)"
