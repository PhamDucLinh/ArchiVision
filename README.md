# ArchiVision

Flutter Desktop app chuyển đổi bản vẽ sang PNG.

## macOS Build

```bash
scripts/check_build_env.sh
scripts/build_macos.sh
```

## Windows Runtime Automation

Máy Windows dùng để build app lần đầu:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\setup_windows_dev.ps1
```

Trên máy Windows chỉ chạy app đã build, mở PowerShell trong thư mục chứa
`archi_vision.exe` và chạy:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\setup_windows_runtime.ps1
```

Nếu máy chưa có Python và có `winget`:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\setup_windows_runtime.ps1 -InstallPythonWithWinget
```

Nếu chỉ xử lý `.skp/.skb` preview và không cần `.dwg`:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\setup_windows_runtime.ps1 -SkipOda
```

Chi tiết: [scripts/WINDOWS_SETUP.md](scripts/WINDOWS_SETUP.md)
