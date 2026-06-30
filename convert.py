#!/usr/bin/env python3
"""
Backend convert DWG -> PNG cho ArchiVision.

Cách chạy thủ công:
    python3 convert.py /path/input.dwg /path/output.png

Yêu cầu:
    pip install ezdxf matplotlib
    Cài ODA File Converter trên máy.
"""

from __future__ import annotations

import argparse
import glob
import os
import platform
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


ODA_OUTPUT_VERSION = "ACAD2018"
ODA_OUTPUT_TYPE = "DXF"
ODA_RECURSIVE = "0"
ODA_AUDIT = "1"
PNG_DPI = 300


class ConversionError(RuntimeError):
    """Lỗi nghiệp vụ khi convert DWG sang PNG."""


def find_oda_converter() -> Path:
    """Tự nhận diện hệ điều hành và trả về đường dẫn ODAFileConverter."""
    env_path = os.environ.get("ODA_FILE_CONVERTER")
    if env_path:
        candidate = Path(env_path)
        if candidate.exists():
            return candidate
        raise ConversionError(
            f"Biến môi trường ODA_FILE_CONVERTER không hợp lệ: {candidate}"
        )

    system_name = platform.system()

    if system_name == "Darwin":
        candidate = Path(
            "/Applications/ODAFileConverter.app/Contents/MacOS/ODAFileConverter"
        )
        if candidate.exists():
            return candidate
        raise ConversionError(
            "Không tìm thấy ODAFileConverter trên macOS tại "
            "/Applications/ODAFileConverter.app/Contents/MacOS/ODAFileConverter"
        )

    if system_name == "Windows":
        patterns = [
            r"C:\Program Files\ODA\ODAFileConverter*\ODAFileConverter.exe",
            r"C:\Program Files (x86)\ODA\ODAFileConverter*\ODAFileConverter.exe",
        ]
        candidates: list[Path] = []
        for pattern in patterns:
            candidates.extend(Path(path) for path in glob.glob(pattern))

        if candidates:
            return sorted(candidates, key=lambda path: str(path).lower())[-1]

        raise ConversionError(
            "Không tìm thấy ODAFileConverter.exe. Đường dẫn thường gặp là "
            r"C:\Program Files\ODA\ODAFileConverter X.X.X\ODAFileConverter.exe. "
            "Bạn cũng có thể đặt biến môi trường ODA_FILE_CONVERTER trỏ tới file exe."
        )

    raise ConversionError(f"Hệ điều hành chưa được hỗ trợ: {system_name}")


def run_oda_converter(oda_path: Path, input_dir: Path, output_dir: Path) -> None:
    """Gọi ODA File Converter để chuyển toàn bộ DWG trong input_dir sang DXF."""
    command = [
        str(oda_path),
        str(input_dir),
        str(output_dir),
        ODA_OUTPUT_VERSION,
        ODA_OUTPUT_TYPE,
        ODA_RECURSIVE,
        ODA_AUDIT,
    ]

    print("Đang gọi ODA File Converter...", flush=True)
    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
        check=False,
    )

    if result.stdout.strip():
        print(result.stdout.strip(), flush=True)
    if result.stderr.strip():
        print(result.stderr.strip(), file=sys.stderr, flush=True)

    if result.returncode != 0:
        raise ConversionError(
            f"ODA File Converter thất bại với mã lỗi {result.returncode}."
        )


def find_generated_dxf(output_dir: Path, input_stem: str) -> Path:
    """Tìm file DXF do ODA sinh ra trong thư mục output tạm."""
    dxf_files = [
        path
        for path in output_dir.rglob("*")
        if path.is_file() and path.suffix.lower() == ".dxf"
    ]

    if not dxf_files:
        raise ConversionError("ODA đã chạy xong nhưng không sinh ra file DXF.")

    same_name = [
        path for path in dxf_files if path.stem.lower() == input_stem.lower()
    ]
    return same_name[0] if same_name else dxf_files[0]


def render_dxf_to_png(dxf_path: Path, png_path: Path) -> None:
    """Render DXF sang PNG bằng ezdxf và matplotlib với DPI cao."""
    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        from ezdxf import recover
        from ezdxf.addons.drawing import Frontend, RenderContext
        from ezdxf.addons.drawing.matplotlib import MatplotlibBackend
    except ImportError as exc:
        raise ConversionError(
            "Thiếu thư viện Python. Hãy chạy: pip install ezdxf matplotlib"
        ) from exc

    print("Đang đọc DXF và render PNG...", flush=True)

    doc, auditor = recover.readfile(dxf_path)
    if auditor.has_errors:
        print(
            "Cảnh báo: DXF có lỗi nội bộ, ezdxf sẽ cố gắng render phần đọc được.",
            file=sys.stderr,
            flush=True,
        )

    png_path.parent.mkdir(parents=True, exist_ok=True)

    figure = plt.figure(figsize=(16, 12), dpi=PNG_DPI)
    axis = figure.add_axes((0, 0, 1, 1))
    axis.set_axis_off()
    axis.set_aspect("equal")
    axis.set_facecolor("white")
    figure.patch.set_facecolor("white")

    context = RenderContext(doc)
    backend = MatplotlibBackend(axis)
    Frontend(context, backend).draw_layout(doc.modelspace(), finalize=True)

    figure.savefig(
        png_path,
        dpi=PNG_DPI,
        bbox_inches="tight",
        pad_inches=0,
        facecolor="white",
    )
    plt.close(figure)

    if not png_path.exists() or png_path.stat().st_size == 0:
        raise ConversionError("Render hoàn tất nhưng file PNG không hợp lệ.")


def convert_dwg_to_png(input_dwg: Path, output_png: Path) -> None:
    """Luồng chính: DWG -> DXF tạm bằng ODA -> PNG bằng ezdxf/matplotlib."""
    if not input_dwg.exists():
        raise ConversionError(f"File DWG không tồn tại: {input_dwg}")
    if input_dwg.suffix.lower() != ".dwg":
        raise ConversionError("File đầu vào phải có phần mở rộng .dwg")

    oda_path = find_oda_converter()
    print(f"ODA File Converter: {oda_path}", flush=True)

    with tempfile.TemporaryDirectory(prefix="archivision_") as temp_root:
        temp_root_path = Path(temp_root)
        oda_input_dir = temp_root_path / "dwg_in"
        oda_output_dir = temp_root_path / "dxf_out"
        oda_input_dir.mkdir(parents=True, exist_ok=True)
        oda_output_dir.mkdir(parents=True, exist_ok=True)

        # ODA CLI làm việc theo thư mục, nên copy DWG vào folder tạm riêng.
        temp_dwg = oda_input_dir / input_dwg.name
        shutil.copy2(input_dwg, temp_dwg)

        run_oda_converter(oda_path, oda_input_dir, oda_output_dir)
        temp_dxf = find_generated_dxf(oda_output_dir, input_dwg.stem)
        render_dxf_to_png(temp_dxf, output_png)

    print(f"Hoàn tất: {output_png}", flush=True)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert file DWG sang PNG chất lượng cao."
    )
    parser.add_argument("input_dwg", help="Đường dẫn file .dwg đầu vào")
    parser.add_argument("output_png", help="Đường dẫn file .png đầu ra")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)

    try:
        convert_dwg_to_png(
            Path(args.input_dwg).expanduser().resolve(),
            Path(args.output_png).expanduser().resolve(),
        )
        return 0
    except Exception as exc:
        print(f"Lỗi: {exc}", file=sys.stderr, flush=True)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
