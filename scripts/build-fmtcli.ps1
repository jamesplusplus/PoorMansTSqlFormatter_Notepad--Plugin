param(
    [ValidateSet("Release", "Debug")]
    [string]$Configuration = "Release",
    [switch]$SkipStage
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$sln = Join-Path $projectRoot "PoorMansTSqlFormatter-Notepad--Plugin.sln"

$msbuild = Get-ChildItem "${env:ProgramFiles(x86)}\Microsoft Visual Studio" -Recurse -Filter MSBuild.exe -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match 'MSBuild\\Current\\Bin\\MSBuild.exe' -or $_.FullName -match 'MSBuild\\Current\\Bin\\amd64\\MSBuild.exe' } |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $msbuild) {
    $msbuild = Get-Command msbuild -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}
if (-not $msbuild) {
    Write-Error "MSBuild not found. Install Visual Studio Build Tools with .NET Framework 4.8 targeting pack."
}

Write-Host "Building FmtCli ($Configuration) ..."
& $msbuild $sln /t:PoorMansTSqlFormatterFmtCli /p:Configuration=$Configuration /v:m
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$fmtOut = Join-Path $projectRoot "fmtcli\PoorMansTSqlFormatterFmtCli\bin\$Configuration"
$exe = Join-Path $fmtOut "PoorMansTSqlFormatterFmtCli.exe"
$lib = Join-Path $fmtOut "PoorMansTSqlFormatterLib.dll"

if (-not (Test-Path $exe)) {
    Write-Error "Build succeeded but exe not found: $exe"
}
if (-not (Test-Path $lib)) {
    $lib = Join-Path $projectRoot "fmtcli\PoorMansTSqlFormatterLib\bin\$Configuration\PoorMansTSqlFormatterLib.dll"
}
if (-not (Test-Path $lib)) {
    Write-Error "PoorMansTSqlFormatterLib.dll not found next to FmtCli output."
}

Write-Host "OK: $exe"

if (-not $SkipStage) {
    $stageDir = Join-Path $projectRoot "out\plugin"
    New-Item -ItemType Directory -Force -Path $stageDir | Out-Null
    Copy-Item -Force $exe (Join-Path $stageDir "PoorMansTSqlFormatterFmtCli.exe")
    Copy-Item -Force $lib (Join-Path $stageDir "PoorMansTSqlFormatterLib.dll")
    Write-Host "Staged FmtCli to $stageDir"
}
