param(
    [switch]$CreateDesktopShortcut,
    [switch]$LaunchAfterSetup
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "== $Message ==" -ForegroundColor Cyan
}

function Test-AppPackage {
    param([string]$AppRoot)

    $requiredPaths = @(
        (Join-Path $AppRoot "archi_vision.exe"),
        (Join-Path $AppRoot "data"),
        (Join-Path $AppRoot "data\flutter_assets")
    )

    foreach ($path in $requiredPaths) {
        if (-not (Test-Path $path)) {
            throw "Package is incomplete. Missing: $path"
        }
    }
}

function Create-DesktopShortcut {
    param(
        [string]$TargetPath,
        [string]$WorkingDirectory
    )

    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "ArchiVision Studio.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $TargetPath
    $shortcut.WorkingDirectory = $WorkingDirectory
    $shortcut.IconLocation = "$TargetPath,0"
    $shortcut.Save()
    return $shortcutPath
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Step "Validate portable package"
Test-AppPackage -AppRoot $scriptDir

$exePath = Join-Path $scriptDir "archi_vision.exe"
Write-Host "App OK: $exePath" -ForegroundColor Green

if ($CreateDesktopShortcut) {
    Write-Step "Create desktop shortcut"
    $shortcutPath = Create-DesktopShortcut -TargetPath $exePath -WorkingDirectory $scriptDir
    Write-Host "Shortcut created: $shortcutPath" -ForegroundColor Green
}

Write-Step "Done"
Write-Host "To open the app, double-click Run_ArchiVision.bat or archi_vision.exe." -ForegroundColor Green

if ($LaunchAfterSetup) {
    Write-Step "Launch ArchiVision Studio"
    Start-Process -FilePath $exePath -WorkingDirectory $scriptDir
}
