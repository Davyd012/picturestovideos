from pathlib import Path
import struct
import zlib


OUTPUT = Path(__file__).parent / "generated"


def pixel(x: int, y: int, width: int, height: int) -> tuple[int, int, int]:
    color = (20, 36, 58)
    if x < width // 4 and y < height // 2:
        color = (224, 32, 32)
    elif x >= width * 3 // 4 and y < height // 2:
        color = (32, 208, 80)
    elif x < width // 4 and y >= height // 2:
        color = (32, 80, 224)
    elif x >= width * 3 // 4 and y >= height // 2:
        color = (255, 208, 32)

    if width * 45 // 100 <= x < width * 55 // 100:
        color = (240, 240, 240)
    if height * 40 // 100 <= y < height * 60 // 100:
        color = (208, 32, 208)
    if x % max(8, width // 20) < 2 or y % max(8, height // 20) < 2:
        color = (250, 250, 250)
    return color


def chunk(kind: bytes, data: bytes) -> bytes:
    checksum = zlib.crc32(kind + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", checksum)


def write_png(path: Path, width: int, height: int) -> None:
    rows = bytearray()
    for y in range(height):
        rows.append(0)
        for x in range(width):
            rows.extend(pixel(x, y, width, height))
    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", header)
        + chunk(b"IDAT", zlib.compress(bytes(rows), level=9))
        + chunk(b"IEND", b"")
    )


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, width, height in [
        ("landscape.png", 400, 200),
        ("portrait.png", 200, 400),
        ("square.png", 300, 300),
    ]:
        write_png(OUTPUT / name, width, height)


if __name__ == "__main__":
    main()
