#!/usr/bin/env python3
"""Генерация минимальных PNG-изображений для mock-фикстур (SP-E1-01).

Создаёт простые цветные PNG (без внешних зависимостей, только std-lib):
  - teaser.png  — 640x360, оранжевый фон
  - box.png     — 640x360, синий фон
Затем sips конвертирует их в JPEG (images/teaser.jpg, images/box.jpg).
"""

import struct
import zlib
from pathlib import Path

OUT = Path(__file__).resolve().parent / "images"
OUT.mkdir(parents=True, exist_ok=True)


def chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def make_png(path: Path, width: int, height: int, rgb: tuple[int, int, int]) -> None:
    # RGBA-строки: 1 байт filter (0) + 4 байта пикселя на строку.
    row = b"\x00" + bytes(rgb) * width
    raw = row * height

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)  # 8-bit RGBA
    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )
    path.write_bytes(png)
    print(f"created {path} ({width}x{height}, {len(png)} bytes)")


make_png(OUT / "teaser.png", 640, 360, (230, 126, 34))  # оранжевый
make_png(OUT / "box.png", 640, 360, (41, 128, 185))    # синий