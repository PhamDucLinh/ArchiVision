# Windows Setup Automation

## Neu ban KHONG co may Windows

Ban van co the build app Windows bang GitHub Actions.

### Cach dung GitHub Actions de build goi portable

1. Push code len nhanh `main`.
2. Vao tab `Actions` tren GitHub repo.
3. Chon workflow `Build Windows Portable`.
4. Bam `Run workflow`, hoac chi can push moi len `main` de workflow tu chay.
5. Doi workflow build xong.
6. Tai artifact ten dang `archivision-windows-portable-<run_number>`.
7. Gui file artifact zip do cho nguoi dung Windows.

Luu y:

- Artifact hien dang duoc giu 14 ngay.
- Neu repo la private, nguoi dung cuoi thuong se khong tu tai duoc artifact neu khong co quyen doc repo.
- Cach de don gian nhat la ban tai artifact ve roi gui lai cho nguoi dung qua Drive, Dropbox, Zalo, v.v.

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
