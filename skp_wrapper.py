#!/usr/bin/env python3
"""
Python wrapper gọi native CLI skp_processor.

Ví dụ:
    python3 skp_wrapper.py input.skp output.png
"""

from __future__ import annotations

import argparse
import platform
import subprocess
from io import BytesIO
from pathlib import Path
from typing import Optional, Union


class SkpProcessorError(RuntimeError):
    """Lỗi khi gọi skp_processor."""


def default_processor_path() -> Path:
    executable_name = "skp_processor.exe" if platform.system() == "Windows" else "skp_processor"
    return (
        Path(__file__).resolve().parent
        / "native"
        / "skp_processor"
        / "build"
        / executable_name
    )


def convert_skp_to_png(
    input_path: Union[str, Path],
    output_path: Union[str, Path],
    processor_path: Optional[Union[str, Path]] = None,
    mode: str = "thumbnail",
) -> Path:
    """Gọi CLI tool để xử lý .skp/.skb và trả về path PNG."""
    input_file = Path(input_path).expanduser().resolve()
    output_file = Path(output_path).expanduser().resolve()
    executable = (
        Path(processor_path).expanduser().resolve()
        if processor_path
        else default_processor_path()
    )

    if not input_file.exists():
        raise SkpProcessorError(f"Input file does not exist: {input_file}")

    output_file.parent.mkdir(parents=True, exist_ok=True)

    if not executable.exists():
        if mode != "thumbnail":
            raise SkpProcessorError(f"skp_processor executable not found: {executable}")
        return extract_embedded_preview_to_png(input_file, output_file)

    command = [
        str(executable),
        "--mode",
        mode,
        str(input_file),
        str(output_file),
    ]
    result = subprocess.run(command, capture_output=True, text=True, check=False)

    if result.returncode != 0:
        details = "\n".join(
            line
            for line in [result.stdout.strip(), result.stderr.strip()]
            if line
        )
        raise SkpProcessorError(
            f"skp_processor failed with exit code {result.returncode}.\n{details}"
        )

    return output_file


def extract_embedded_preview_to_png(input_file: Path, output_file: Path) -> Path:
    """
    Fallback không cần SDK: quét các ảnh JPEG/PNG nhúng trong SKP/SKB và lưu ảnh
    có diện tích lớn nhất thành PNG.

    Đây không thay thế SketchUp C API, nhưng giúp lấy preview thực tế trong nhiều
    file SKP/SKB khi native skp_processor chưa được build.
    """
    try:
        from PIL import Image
    except ImportError as exc:
        raise SkpProcessorError(
            "Pillow is required for SKP/SKB fallback preview extraction. "
            "Install it with: python3 -m pip install Pillow"
        ) from exc

    data = input_file.read_bytes()
    candidates = []
    signatures = [(b"\xff\xd8\xff", "JPEG"), (b"\x89PNG\r\n\x1a\n", "PNG")]

    for signature, image_type in signatures:
        offset = data.find(signature)
        while offset != -1:
            try:
                image = Image.open(BytesIO(data[offset:]))
                image.verify()
                image = Image.open(BytesIO(data[offset:]))
                candidates.append((image.width * image.height, offset, image_type))
            except Exception:
                pass
            offset = data.find(signature, offset + 1)

    if not candidates:
        raise SkpProcessorError(
            "No embedded JPEG/PNG preview was found in this SKP/SKB file. "
            "Build skp_processor with SketchUp C API SDK for the official thumbnail path."
        )

    _, best_offset, _ = max(candidates, key=lambda item: item[0])
    image = Image.open(BytesIO(data[best_offset:]))
    if image.mode not in ("RGB", "RGBA"):
        image = image.convert("RGBA")
    image.save(output_file, format="PNG")

    if not output_file.exists() or output_file.stat().st_size == 0:
        raise SkpProcessorError(f"Could not write output PNG: {output_file}")

    return output_file


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract SKP/SKB thumbnail to PNG.")
    parser.add_argument("input", help="Input .skp or .skb file")
    parser.add_argument("output", help="Output .png file")
    parser.add_argument("--processor", help="Path to skp_processor executable")
    parser.add_argument(
        "--mode",
        choices=["thumbnail", "render"],
        default="thumbnail",
        help="Processing mode. render is a reserved advanced mode.",
    )
    args = parser.parse_args()

    try:
        output = convert_skp_to_png(args.input, args.output, args.processor, args.mode)
        print(f"OK: {output}")
        return 0
    except Exception as exc:
        print(f"ERROR: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
