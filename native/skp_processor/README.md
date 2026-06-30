# skp_processor

Native CLI xử lý `.skp`/`.skb` bằng SketchUp C API SDK.

## Trạng thái chức năng

- `thumbnail`: đã triển khai. Tool mở model bằng SketchUp C API, lấy thumbnail nhúng trong file và lưu PNG.
- `render`: chưa triển khai renderer thật. SketchUp C API chạy headless và đọc geometry được, nhưng không cung cấp viewport renderer headless để xuất camera perspective thành PNG. Muốn có render thật, cần tự dựng renderer từ geometry hoặc dùng SketchUp/Ruby API trong môi trường có SketchUp desktop.

## Tải SketchUp C API SDK

Vào SketchUp Developer Center và request/download SketchUp Desktop SDK:

https://developer.sketchup.com/

Trang này ghi rõ Desktop SDK dùng để đọc/ghi file SKP. Sau khi tải và giải nén, đặt biến môi trường:

```bash
export SKETCHUP_SDK_ROOT=/path/to/SketchUp-SDK
```

Windows PowerShell:

```powershell
$env:SKETCHUP_SDK_ROOT="C:\SDKs\SketchUp-SDK"
```

## Build trên macOS

```bash
cd native/skp_processor
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DSKETCHUP_SDK_ROOT="$SKETCHUP_SDK_ROOT"
cmake --build build --config Release
./build/skp_processor --mode thumbnail input.skp output.png
```

Nếu runtime library của SketchUp không được copy tự động, copy các `.dylib`/`.framework` cần thiết từ thư mục `binaries` của SDK vào cạnh executable hoặc cấu hình `DYLD_LIBRARY_PATH`.

## Build trên Windows

Chạy trong Developer PowerShell for Visual Studio:

```powershell
cd native\skp_processor
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 -DSKETCHUP_SDK_ROOT="$env:SKETCHUP_SDK_ROOT"
cmake --build build --config Release
.\build\Release\skp_processor.exe --mode thumbnail input.skp output.png
```

Nếu DLL runtime của SketchUp không được copy tự động, copy các `.dll` từ `binaries\sketchup\x64` của SDK vào thư mục chứa `skp_processor.exe`.

## CLI

```bash
skp_processor input.skp output.png
skp_processor --mode thumbnail input.skp output.png
skp_processor --mode render input.skp output.png
```

`thumbnail` là mode mặc định. `render` hiện trả exit code `4` với thông báo giải thích vì SketchUp C API không có renderer headless.

## Python wrapper

Từ root project:

```bash
python3 skp_wrapper.py input.skp output.png --processor native/skp_processor/build/skp_processor
```

Trong code Python:

```python
from skp_wrapper import convert_skp_to_png

png_path = convert_skp_to_png(
    "input.skp",
    "output.png",
    processor_path="native/skp_processor/build/skp_processor",
    mode="thumbnail",
)
print(png_path)
```
