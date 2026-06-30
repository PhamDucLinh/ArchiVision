# Windows Setup Automation

## Máy chỉ chạy app đã build

Copy toàn bộ thư mục release/package sang máy Windows, rồi mở PowerShell trong thư mục đó:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\setup_windows_runtime.ps1
.\archi_vision.exe
```

Nếu máy chưa có Python và có `winget`:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\setup_windows_runtime.ps1 -InstallPythonWithWinget
```

Nếu chỉ xử lý `.skp/.skb` preview, có thể bỏ ODA:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\setup_windows_runtime.ps1 -SkipOda
```

Nếu có installer ODA đã tải:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\setup_windows_runtime.ps1 -OdaInstallerPath "C:\Users\You\Downloads\ODAFileConverter.exe"
```

Nếu chưa có ODA và muốn mở trang tải:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\setup_windows_runtime.ps1 -OpenOdaDownloadPage
```

## Máy dùng để build Windows app

Cách tự động nhất: mở PowerShell trong root project và chạy:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\setup_windows_dev.ps1
```

Script sẽ cài bằng `winget`:

- Git
- Python 3
- Flutter SDK
- Visual Studio 2022 Community
- Visual Studio workload `Desktop development with C++`
- Python packages trong `requirements.txt`

Nếu Windows hiện hộp thoại UAC, chọn **Yes**.

Sau khi script xong, đóng PowerShell rồi mở lại để PATH mới có hiệu lực.

Build:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1
```

Build và đóng gói thư mục runtime:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Package
```

Output package mặc định:

```text
dist\archi_vision_windows_runtime
```

Mang toàn bộ thư mục này sang máy Windows khác rồi chạy `setup_windows_runtime.ps1`.
