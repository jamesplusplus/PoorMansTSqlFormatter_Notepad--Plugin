# Build FmtCli + Notepad-- plugin; output everything under out/plugin/.
param(
    [string]$QtRoot = "C:\Qt\5.15.2\msvc2019_64",
    [ValidateSet("Release", "Debug")]
    [string]$Configuration = "Release",
    [switch]$RegenerateImportLib,
    [string]$NotepadRoot = "C:\Program Files\Notepad--"
)

& (Join-Path $PSScriptRoot "build.ps1") `
    -QtRoot $QtRoot `
    -Configuration $Configuration `
    -RegenerateImportLib:$RegenerateImportLib `
    -NotepadRoot $NotepadRoot
