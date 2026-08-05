#!/usr/bin/env python3
import argparse
import time
from pathlib import Path
from typing import Optional

from PIL import Image
import serial


def rgb888_to_rgb565(r: int, g: int, b: int) -> int:
    return ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3)


def transform_image(image_path: Path, width: int, height: int, swap_wh: bool) -> Image.Image:
    img = Image.open(image_path).convert("RGB")
    if swap_wh:
        # Keep final output dimensions as width x height, but swap source axes
        # first and transpose back so pixel stream layout matches display scan.
        img = img.resize((height, width), Image.Resampling.LANCZOS)
        img = img.transpose(Image.Transpose.TRANSPOSE)
    else:
        img = img.resize((width, height), Image.Resampling.LANCZOS)
    return img


def build_square_test_image(
    width: int,
    height: int,
    square_size: int,
    square_x: Optional[int],
    square_y: Optional[int],
) -> Image.Image:
    img = Image.new("RGB", (width, height), (255, 255, 255))

    side = max(1, min(square_size, width, height))
    x0 = (width - side) // 2 if square_x is None else square_x
    y0 = (height - side) // 2 if square_y is None else square_y

    x0 = max(0, min(x0, width - side))
    y0 = max(0, min(y0, height - side))

    px = img.load()
    for y in range(y0, y0 + side):
        for x in range(x0, x0 + side):
            px[x, y] = (0, 0, 0)

    print(f"Square pattern: {side}x{side} at x={x0}, y={y0} on white background")
    return img


def image_to_rgb565_bytes(img: Image.Image) -> bytes:
    out = bytearray()
    raw = img.tobytes()
    for i in range(0, len(raw), 3):
        r = raw[i]
        g = raw[i + 1]
        b = raw[i + 2]
        pix = rgb888_to_rgb565(r, g, b)
        out.append((pix >> 8) & 0xFF)
        out.append(pix & 0xFF)
    return bytes(out)


def send_frame(
    port: str,
    baud: int,
    payload: bytes,
    startup_delay: float,
    chunk_size: int,
    inter_chunk_delay: float,
    repeat: int,
) -> None:
    with serial.Serial(port, baudrate=baud, timeout=0.5) as ser:
        print(f"Opened {port} @ {baud} baud")
        if startup_delay > 0:
            print(f"Waiting {startup_delay:.2f}s for FPGA/LCD init...")
            time.sleep(startup_delay)

        for frame_idx in range(repeat):
            sent = 0
            while sent < len(payload):
                end = min(sent + chunk_size, len(payload))
                ser.write(payload[sent:end])
                sent = end
                if inter_chunk_delay > 0:
                    time.sleep(inter_chunk_delay)
            print(f"Sent frame {frame_idx + 1}/{repeat}: {len(payload)} bytes")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Send an image to ST7735 over UART as RGB565 big-endian pixels"
    )
    parser.add_argument(
        "--source",
        choices=["image", "rom-square"],
        default="image",
        help="Payload source: transformed image or deterministic ROM-style square pattern",
    )
    parser.add_argument(
        "--image",
        default="img/l_hires.bmp",
        help="Path to source image",
    )
    parser.add_argument(
        "--port",
        default="/dev/cu.usbserial-2012301",
        help="Serial device",
    )
    parser.add_argument("--baud", type=int, default=115200, help="UART baud rate")
    parser.add_argument(
        "--width",
        type=int,
        default=80,
        help="Target width in pixels",
    )
    parser.add_argument(
        "--height",
        type=int,
        default=160,
        help="Target height in pixels",
    )
    parser.add_argument(
        "--startup-delay",
        type=float,
        default=2.0,
        help="Delay before sending to allow LCD init",
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=64,
        help="Bytes per serial write",
    )
    parser.add_argument(
        "--inter-chunk-delay",
        type=float,
        default=0.0,
        help="Delay between chunks in seconds",
    )
    parser.add_argument(
        "--repeat",
        type=int,
        default=1,
        help="How many times to transmit the frame",
    )
    parser.add_argument(
        "--swap-wh",
        action="store_true",
        help="Swap image resize dimensions (height/width)",
    )
    parser.add_argument(
        "--square-size",
        type=int,
        default=16,
        help="Square side size for --source rom-square",
    )
    parser.add_argument(
        "--square-x",
        type=int,
        default=None,
        help="Square top-left X for --source rom-square (default: centered)",
    )
    parser.add_argument(
        "--square-y",
        type=int,
        default=None,
        help="Square top-left Y for --source rom-square (default: centered)",
    )
    parser.add_argument(
        "--dump-image",
        default=None,
        help="Write transformed image to this file (e.g. transformed.png)",
    )
    parser.add_argument(
        "--dump-only",
        action="store_true",
        help="Only dump/prepare image and exit without UART send",
    )

    args = parser.parse_args()

    if args.repeat < 1:
        raise SystemExit("--repeat must be >= 1")

    if args.source == "image":
        img_path = Path(args.image)
        if not img_path.exists():
            raise SystemExit(f"Image not found: {img_path}")
        img = transform_image(img_path, args.width, args.height, args.swap_wh)
        if args.swap_wh:
            print("Using swapped resize dimensions: height/width")
    else:
        img = build_square_test_image(
            args.width,
            args.height,
            args.square_size,
            args.square_x,
            args.square_y,
        )

    payload = image_to_rgb565_bytes(img)
    expected = args.width * args.height * 2
    print(f"Prepared payload: {len(payload)} bytes (expected {expected})")

    if args.dump_image:
        dump_path = Path(args.dump_image)
        dump_path.parent.mkdir(parents=True, exist_ok=True)
        img.save(dump_path)
        print(f"Saved transformed image: {dump_path}")

    if args.dump_only:
        print("Dump-only mode: skipping UART send")
        raise SystemExit(0)

    send_frame(
        port=args.port,
        baud=args.baud,
        payload=payload,
        startup_delay=args.startup_delay,
        chunk_size=max(args.chunk_size, 1),
        inter_chunk_delay=max(args.inter_chunk_delay, 0.0),
        repeat=args.repeat,
    )
