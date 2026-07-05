param(
    [string]$Flutter = "flutter",
    [switch]$SkipTests,
    [switch]$Package,
    [string]$PackageOutput = "dist\archivision_windows_portable",
    [switch]$SkipBundleVCRuntime
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "== $Message ==" -ForegroundColor Cyan
}

function Get-VcRuntimeSourceDirectory {
    $candidates = @()

    if ($env:VCToolsRedistDir) {
        $candidates += Join-Path $env:VCToolsRedistDir "x64\Microsoft.VC143.CRT"
    }

    $visualStudioRoots = @(
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\VC\Redist\MSVC",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional\VC\Redist\MSVC",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\VC\Redist\MSVC",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\BuildTools\VC\Redist\MSVC"
    ) | Where-Object { $_ -and (Test-Path $_) }

    foreach ($root in $visualStudioRoots) {
        $latest = Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            Select-Object -First 1

        if ($latest) {
            $candidates += Join-Path $latest.FullName "x64\Microsoft.VC143.CRT"
        }
    }

    $candidates += "$env:WINDIR\System32"

    return $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}

function Copy-VcRuntimeLibraries {
    param([string]$DestinationDirectory)

    $runtimeSource = Get-VcRuntimeSourceDirectory
    if (-not $runtimeSource) {
        Write-Warning "Could not locate Visual C++ runtime source directory. Package will be created without bundled VC runtime."
        return
    }

    $dlls = @(
        "concrt140.dll",
        "msvcp140.dll",
        "msvcp140_1.dll",
        "msvcp140_2.dll",
        "msvcp140_atomic_wait.dll",
        "vcruntime140.dll",
        "vcruntime140_1.dll"
    )

    Write-Host "Bundling VC runtime from: $runtimeSource" -ForegroundColor DarkGray

    foreach ($dll in $dlls) {
        $sourcePath = Join-Path $runtimeSource $dll
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $DestinationDirectory -Force
        }
    }
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
    Write-Step "Package portable Windows app"
    $outputDir = Join-Path $projectRoot $PackageOutput
    if (Test-Path $outputDir) {
        Remove-Item $outputDir -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    Copy-Item -Path (Join-Path $releaseDir "*") -Destination $outputDir -Recurse -Force

    if (-not $SkipBundleVCRuntime) {
        Copy-VcRuntimeLibraries -DestinationDirectory $outputDir
    }

    Copy-Item -Path (Join-Path $scriptDir "setup_windows_runtime.ps1") -Destination $outputDir -Force
    Copy-Item -Path (Join-Path $scriptDir "Run_ArchiVision.bat") -Destination $outputDir -Force

    $readmePath = Join-Path $outputDir "README_WINDOWS.txt"
    @"
ArchiVision Studio - Windows Portable Package

1. Giai nen toan bo thu muc nay.
2. Double click Run_ArchiVision.bat de mo app.
3. Neu muon tao shortcut Desktop, chuot phai setup_windows_runtime.ps1 > Run with PowerShell
   hoac chay:
      PowerShell -ExecutionPolicy Bypass -File .\setup_windows_runtime.ps1 -CreateDesktopShortcut -LaunchAfterSetup

Luu y:
- Khong can cai Flutter de dung goi portable nay.
- Neu Windows bao thieu VC++ runtime, hay chay setup_windows_runtime.ps1.
"@ | Set-Content -Path $readmePath -Encoding ASCII

    Write-Host "Packaged: $outputDir" -ForegroundColor Green
    Write-Host "Ship this whole folder (or zip it) to the Windows end user." -ForegroundColor Green
    Write-Host "End user can simply double-click: Run_ArchiVision.bat"
}
