# Windows Setup Automation

## Cho nguoi dung Windows khong ky thuat

Khuyen nghi phat hanh goi `portable` da build san thay vi bat nguoi dung cai Flutter.

### Cach dung goi portable

1. Nhan file zip `archivision_windows_portable`.
2. Giai nen ra 1 thu muc bat ky.
3. Double click `Run_ArchiVision.bat`.

Neu muon tao shortcut Desktop, mo PowerShell trong thu muc package va chay:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\setup_windows_runtime.ps1 -CreateDesktopShortcut -LaunchAfterSetup
```

Nguoi dung cuoi KHONG can:

- Flutter SDK
- Visual Studio
- Python
- ODA

## Cho may Windows dung de build package

### 1. Cai moi truong build

Mo PowerShell voi quyen admin trong root project:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\setup_windows_dev.ps1
```

Script se cai:

- Git
- Flutter SDK
- Visual Studio 2022 Community
- workload `Desktop development with C++`

### 2. Build va dong goi portable

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Package
```

Output mac dinh:

```text
dist\archivision_windows_portable
```

Thu muc nay da bao gom:

- `archi_vision.exe`
- cac file `.dll`
- thu muc `data`
- `Run_ArchiVision.bat`
- `setup_windows_runtime.ps1`

Neu muon bo qua test:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -SkipTests -Package
```

Neu muon dong goi ma khong kem VC++ runtime local:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Package -SkipBundleVCRuntime
```

## Kich ban de xuat

1. Ban build package tren 1 may Windows co moi truong dev.
2. Nen file `dist\archivision_windows_portable`.
3. Gui zip cho nguoi dung.
4. Nguoi dung giai nen va double click `Run_ArchiVision.bat`.
