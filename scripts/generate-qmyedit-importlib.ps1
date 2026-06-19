# Build qmyedit_qt5.lib import library from an installed Notepad-- (plugin edition).
# Required because the plugin must link the shared qmyedit_qt5.dll, NOT a static qscint .lib.
param(
    [string]$NotepadRoot = "C:\Program Files\Notepad--",
    [string]$OutDir = ""
)

$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $projectRoot "third_party\ndd_importlib"
}

$dll = Join-Path $NotepadRoot "qmyedit_qt5.dll"
if (-not (Test-Path $dll)) {
    Write-Error "Not found: $dll"
    exit 1
}

$dumpbin = Get-ChildItem "${env:ProgramFiles(x86)}\Microsoft Visual Studio" -Recurse -Filter dumpbin.exe -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match 'Hostx64\\x64\\dumpbin.exe' } |
    Select-Object -First 1 -ExpandProperty FullName
$libexe = Get-ChildItem "${env:ProgramFiles(x86)}\Microsoft Visual Studio" -Recurse -Filter lib.exe -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match 'Hostx64\\x64\\lib.exe' } |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $dumpbin -or -not $libexe) {
    Write-Error "dumpbin/lib.exe not found. Install VS Build Tools with C++ workload."
    exit 1
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$defPath = Join-Path $OutDir "qmyedit_qt5.def"
$libPath = Join-Path $OutDir "qmyedit_qt5.lib"

$defLines = @("LIBRARY qmyedit_qt5", "EXPORTS")
& $dumpbin /exports $dll | ForEach-Object {
    if ($_ -match '^\s+\d+\s+[0-9A-Fa-f]+\s+[0-9A-Fa-f]+\s+(\S+)\s*$') {
        $defLines += "    $($matches[1])"
    }
}
$defLines | Set-Content -Path $defPath -Encoding ascii
Push-Location $OutDir
& $libexe /def:qmyedit_qt5.def /out:qmyedit_qt5.lib /machine:x64 | Out-Null
Pop-Location

Write-Host "Created $libPath"
Write-Host "Rebuild plugin: .\scripts\build.ps1"
