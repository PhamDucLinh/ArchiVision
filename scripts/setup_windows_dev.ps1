param(
    [switch]$NoAdminRelaunch,
    [switch]$SkipFlutter,
    [switch]$SkipVisualStudio,
    [switch]$SkipGit
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "== $Message ==" -ForegroundColor Cyan
}

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-WingetPackage {
    param(
        [string]$Id,
        [string]$Name,
        [string[]]$ExtraArgs = @()
    )

    Write-Step "Install $Name"
    winget install `
        --id $Id `
        --exact `
        --source winget `
        --accept-package-agreements `
        --accept-source-agreements `
        @ExtraArgs
}

if (-not $NoAdminRelaunch -and -not (Test-IsAdmin)) {
    Write-Host "This setup works best as Administrator. Relaunching..." -ForegroundColor Yellow
    $arguments = @(
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$PSCommandPath`"",
        "-NoAdminRelaunch"
    )
    if ($SkipFlutter) { $arguments += "-SkipFlutter" }
    if ($SkipVisualStudio) { $arguments += "-SkipVisualStudio" }
    if ($SkipGit) { $arguments += "-SkipGit" }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments
    exit 0
}

$winget = Get-Command winget -ErrorAction SilentlyContinue
if (-not $winget) {
    throw "winget is not available. Install 'App Installer' from Microsoft Store, then rerun this script."
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

Write-Step "Install core tools"
if (-not $SkipGit) {
    Install-WingetPackage -Id "Git.Git" -Name "Git"
}

if (-not $SkipFlutter) {
    Install-WingetPackage -Id "Google.Flutter" -Name "Flutter SDK"
}

if (-not $SkipVisualStudio) {
    Write-Step "Install Visual Studio 2022 Community + C++ workload"
    winget install `
        --id "Microsoft.VisualStudio.2022.Community" `
        --exact `
        --source winget `
        --accept-package-agreements `
        --accept-source-agreements `
        --override "--wait --quiet --norestart --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended"
}

Write-Step "Refresh PATH for this terminal"
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$machinePath;$userPath"

if (-not $SkipFlutter) {
    Write-Step "Enable Windows desktop"
    flutter config --enable-windows-desktop
}

Write-Step "Verify"
if (-not $SkipGit) {
    git --version
}
if (-not $SkipFlutter) {
    flutter --version
    flutter doctor -v
}

Write-Step "Done"
Write-Host "Close and reopen PowerShell, then run:" -ForegroundColor Green
Write-Host "  cd `"$projectRoot`""
Write-Host "  flutter pub get"
Write-Host "  PowerShell -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Package"
