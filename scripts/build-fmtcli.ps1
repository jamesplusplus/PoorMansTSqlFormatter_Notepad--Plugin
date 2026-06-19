param(
    [ValidateSet("Release", "Debug")]
    [string]$Configuration = "Release",
    [string]$Runtime = "",
    [switch]$SelfContained,
    [switch]$SingleFile,
    [switch]$SkipStage
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$fmtCliProject = Join-Path $projectRoot "fmtcli\PoorMansTSqlFormatterFmtCli\PoorMansTSqlFormatterFmtCli.csproj"

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Error ".NET SDK not found. Install .NET 8 SDK: https://dotnet.microsoft.com/download/dotnet/8.0"
}

Write-Host "Building FmtCli ($Configuration, .NET 8) ..."

if ($Runtime -or $SelfContained -or $SingleFile) {
    if ([string]::IsNullOrWhiteSpace($Runtime)) {
        $Runtime = "win-x64"
    }
    $publishArgs = @(
        "publish", $fmtCliProject,
        "-c", $Configuration,
        "-r", $Runtime,
        "--self-contained", ($(if ($SelfContained) { "true" } else { "false" }))
    )
    if ($SingleFile) {
        $publishArgs += "-p:PublishSingleFile=true"
    }
    & dotnet @publishArgs
} else {
    & dotnet publish $fmtCliProject -c $Configuration --self-contained false
}

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($Runtime) {
    $fmtOut = Join-Path $projectRoot "fmtcli\PoorMansTSqlFormatterFmtCli\bin\$Configuration\net8.0\$Runtime\publish"
    if (-not (Test-Path $fmtOut)) {
        $fmtOut = Join-Path $projectRoot "fmtcli\PoorMansTSqlFormatterFmtCli\bin\$Configuration\net8.0\$Runtime"
    }
} else {
    $fmtOut = Join-Path $projectRoot "fmtcli\PoorMansTSqlFormatterFmtCli\bin\$Configuration\net8.0\publish"
    if (-not (Test-Path $fmtOut)) {
        $fmtOut = Join-Path $projectRoot "fmtcli\PoorMansTSqlFormatterFmtCli\bin\$Configuration\net8.0"
    }
}

$exe = Join-Path $fmtOut "PoorMansTSqlFormatterFmtCli.exe"
if (-not (Test-Path $exe)) {
    $exe = Join-Path $fmtOut "PoorMansTSqlFormatterFmtCli"
}
if (-not (Test-Path $exe)) {
    Write-Error "Build succeeded but executable not found under: $fmtOut"
}

Write-Host "OK: $exe"

if (-not $SkipStage) {
    $stageDir = Join-Path $projectRoot "out\plugin"
    New-Item -ItemType Directory -Force -Path $stageDir | Out-Null

    $stagePatterns = @(
        "PoorMansTSqlFormatterFmtCli.exe",
        "PoorMansTSqlFormatterFmtCli",
        "PoorMansTSqlFormatterFmtCli.dll",
        "PoorMansTSqlFormatterFmtCli.deps.json",
        "PoorMansTSqlFormatterFmtCli.runtimeconfig.json",
        "PoorMansTSqlFormatterLib.dll"
    )

    foreach ($pattern in $stagePatterns) {
        $source = Join-Path $fmtOut $pattern
        if (Test-Path $source) {
            Copy-Item -Force $source (Join-Path $stageDir $pattern)
        }
    }

    Write-Host "Staged FmtCli artifacts to $stageDir"
}
