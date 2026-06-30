param(
    [switch]$InstallPythonWithWinget,
    [string]$PythonWingetId = "Python.Python.3.12",
    [string]$OdaInstallerPath = "",
    [switch]$SkipOda,
    [switch]$OpenOdaDownloadPage
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "== $Message ==" -ForegroundColor Cyan
}

function Find-PythonCommand {
    $py = Get-Command py -ErrorAction SilentlyContinue
    if ($py) {
        return @("py", "-3")
    }

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        return @("python")
    }

    return $null
}

function Invoke-Python {
    param(
        [string[]]$PythonCommand,
        [string[]]$Arguments
    )

    $exe = $PythonCommand[0]
    $prefixArgs = @()
    if ($PythonCommand.Count -gt 1) {
        $prefixArgs = $PythonCommand[1..($PythonCommand.Count - 1)]
    }

    & $exe @prefixArgs @Arguments
}

function Find-OdaFileConverter {
    $candidates = @()
    $roots = @(
        "${env:ProgramFiles}\ODA",
        "${env:ProgramFiles(x86)}\ODA"
    ) | Where-Object { $_ -and (Test-Path $_) }

    foreach ($root in $roots) {
        $candidates += Get-ChildItem -Path $root -Filter "ODAFileConverter.exe" -Recurse -ErrorAction SilentlyContinue
    }

    if ($env:ODA_FILE_CONVERTER -and (Test-Path $env:ODA_FILE_CONVERTER)) {
        return (Resolve-Path $env:ODA_FILE_CONVERTER).Path
    }

    if ($candidates.Count -gt 0) {
        return $candidates[0].FullName
    }

    return $null
}

Write-Step "Python"
$pythonCommand = Find-PythonCommand
if (-not $pythonCommand) {
    if ($InstallPythonWithWinget) {
        Write-Host "Python not found. Installing with winget package: $PythonWingetId"
        winget install --id $PythonWingetId --exact --source winget
        $pythonCommand = Find-PythonCommand
    }
}

if (-not $pythonCommand) {
    throw "Python 3 not found. Install Python 3 from https://www.python.org/downloads/windows/ and enable 'Add python.exe to PATH', or rerun with -InstallPythonWithWinget."
}

Invoke-Python $pythonCommand @("--version")

Write-Step "Python packages"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$requirementsCandidates = @(
    (Join-Path $scriptDir "requirements.txt"),
    (Join-Path $projectRoot "requirements.txt")
)
$requirementsPath = $requirementsCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $requirementsPath) {
    throw "requirements.txt not found next to the setup script or in the project root."
}

Invoke-Python $pythonCommand @("-m", "pip", "install", "--upgrade", "pip")
Invoke-Python $pythonCommand @("-m", "pip", "install", "-r", $requirementsPath)
Invoke-Python $pythonCommand @("-c", "import ezdxf, matplotlib, PIL; print('Python packages OK')")

if (-not $SkipOda) {
    Write-Step "ODA File Converter"
    $odaPath = Find-OdaFileConverter
    if (-not $odaPath -and $OdaInstallerPath) {
        if (-not (Test-Path $OdaInstallerPath)) {
            throw "ODA installer not found: $OdaInstallerPath"
        }

        Write-Host "Starting ODA installer: $OdaInstallerPath"
        Write-Host "Follow the installer UI, then return here."
        Start-Process -FilePath $OdaInstallerPath -Wait
        $odaPath = Find-OdaFileConverter
    }

    if (-not $odaPath -and $OpenOdaDownloadPage) {
        Start-Process "https://www.opendesign.com/guestfiles/oda_file_converter"
    }

    if ($odaPath) {
        Write-Host "ODA OK: $odaPath" -ForegroundColor Green
    } else {
        Write-Warning "ODA File Converter not found. DWG conversion will fail until ODA is installed."
        Write-Host "Download: https://www.opendesign.com/guestfiles/oda_file_converter"
        Write-Host "If installed in a custom path, set:"
        Write-Host '  setx ODA_FILE_CONVERTER "C:\Path\To\ODAFileConverter.exe"'
    }
}

Write-Step "Done"
Write-Host "Runtime setup complete."
