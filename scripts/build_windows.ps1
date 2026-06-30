param(
    [string]$Flutter = "flutter",
    [switch]$SkipTests,
    [switch]$Package,
    [string]$PackageOutput = "dist\archi_vision_windows_runtime"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "== $Message ==" -ForegroundColor Cyan
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Set-Location $projectRoot

Write-Step "Flutter pub get"
& $Flutter pub get

Write-Step "Flutter analyze"
& $Flutter analyze

if (-not $SkipTests) {
    Write-Step "Flutter tests"
    & $Flutter test
}

Write-Step "Flutter Windows release build"
& $Flutter build windows

$releaseDir = Join-Path $projectRoot "build\windows\x64\runner\Release"
if (-not (Test-Path $releaseDir)) {
    throw "Release folder not found: $releaseDir"
}

Write-Host "Built app: $releaseDir" -ForegroundColor Green

if ($Package) {
    Write-Step "Package runtime folder"
    $outputDir = Join-Path $projectRoot $PackageOutput
    if (Test-Path $outputDir) {
        Remove-Item $outputDir -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    Copy-Item -Path (Join-Path $releaseDir "*") -Destination $outputDir -Recurse -Force
    Copy-Item -Path (Join-Path $projectRoot "requirements.txt") -Destination $outputDir -Force
    Copy-Item -Path (Join-Path $projectRoot "scripts\setup_windows_runtime.ps1") -Destination $outputDir -Force

    Write-Host "Packaged: $outputDir" -ForegroundColor Green
    Write-Host "On the target Windows machine, run:"
    Write-Host "  PowerShell -ExecutionPolicy Bypass -File .\setup_windows_runtime.ps1"
    Write-Host "  .\archi_vision.exe"
}
