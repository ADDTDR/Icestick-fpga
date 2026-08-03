#!/usr/bin/env python3
import argparse
import time

import serial


FONT_5X7 = {
    " ": [0x00, 0x00, 0x00, 0x00, 0x00],
    "!": [0x00, 0x00, 0x5F, 0x00, 0x00],
    ".": [0x00, 0x60, 0x60, 0x00, 0x00],
    ",": [0x00, 0x02, 0x01, 0x00, 0x00],
    ":": [0x00, 0x36, 0x36, 0x00, 0x00],
    "-": [0x08, 0x08, 0x08, 0x08, 0x08],
    "_": [0x40, 0x40, 0x40, 0x40, 0x40],
    "?": [0x02, 0x01, 0x51, 0x09, 0x06],
    "0": [0x3E, 0x51, 0x49, 0x45, 0x3E],
    "1": [0x00, 0x42, 0x7F, 0x40, 0x00],
    "2": [0x42, 0x61, 0x51, 0x49, 0x46],
    "3": [0x21, 0x41, 0x45, 0x4B, 0x31],
    "4": [0x18, 0x14, 0x12, 0x7F, 0x10],
    "5": [0x27, 0x45, 0x45, 0x45, 0x39],
    "6": [0x3C, 0x4A, 0x49, 0x49, 0x30],
    "7": [0x01, 0x71, 0x09, 0x05, 0x03],
    "8": [0x36, 0x49, 0x49, 0x49, 0x36],
    "9": [0x06, 0x49, 0x49, 0x29, 0x1E],
    "A": [0x7E, 0x11, 0x11, 0x11, 0x7E],
    "B": [0x7F, 0x49, 0x49, 0x49, 0x36],
    "C": [0x3E, 0x41, 0x41, 0x41, 0x22],
    "D": [0x7F, 0x41, 0x41, 0x22, 0x1C],
    "E": [0x7F, 0x49, 0x49, 0x49, 0x41],
    "F": [0x7F, 0x09, 0x09, 0x09, 0x01],
    "G": [0x3E, 0x41, 0x49, 0x49, 0x7A],
    "H": [0x7F, 0x08, 0x08, 0x08, 0x7F],
    "I": [0x00, 0x41, 0x7F, 0x41, 0x00],
    "J": [0x20, 0x40, 0x41, 0x3F, 0x01],
    "K": [0x7F, 0x08, 0x14, 0x22, 0x41],
    "L": [0x7F, 0x40, 0x40, 0x40, 0x40],
    "M": [0x7F, 0x02, 0x0C, 0x02, 0x7F],
    "N": [0x7F, 0x04, 0x08, 0x10, 0x7F],
    "O": [0x3E, 0x41, 0x41, 0x41, 0x3E],
    "P": [0x7F, 0x09, 0x09, 0x09, 0x06],
    "Q": [0x3E, 0x41, 0x51, 0x21, 0x5E],
    "R": [0x7F, 0x09, 0x19, 0x29, 0x46],
    "S": [0x46, 0x49, 0x49, 0x49, 0x31],
    "T": [0x01, 0x01, 0x7F, 0x01, 0x01],
    "U": [0x3F, 0x40, 0x40, 0x40, 0x3F],
    "V": [0x1F, 0x20, 0x40, 0x20, 0x1F],
    "W": [0x7F, 0x20, 0x18, 0x20, 0x7F],
    "X": [0x63, 0x14, 0x08, 0x14, 0x63],
    "Y": [0x07, 0x08, 0x70, 0x08, 0x07],
    "Z": [0x61, 0x51, 0x49, 0x45, 0x43],
}


def text_to_columns(text: str) -> list[int]:
    columns: list[int] = []
    for ch in text.upper():
        glyph = FONT_5X7.get(ch, FONT_5X7["?"])
        columns.extend(glyph)
        columns.append(0x00)
    return columns


def parse_byte_list(raw_bytes: str) -> list[int]:
    values: list[int] = []
    for token in raw_bytes.split(","):
        token = token.strip()
        if not token:
            continue
        values.append(int(token, 0) & 0xFF)
    return values


def send_frame(ser: serial.Serial, frame: list[int]) -> None:
    # Newline is used by FPGA logic as a frame-start reset.
    ser.write(b"\n")
    ser.write(bytes(frame))


def main() -> None:
    parser = argparse.ArgumentParser(description="Send mapped HCMS display bytes over UART")
    parser.add_argument("--port", default="/dev/cu.usbserial-2012301", help="Serial port")
    parser.add_argument("--baud", type=int, default=115200, help="Baud rate")
    parser.add_argument("--width", type=int, default=20, help="Display width in columns")
    parser.add_argument("--text", default="", help="Text to map into 5x7 font columns")
    parser.add_argument("--bytes", dest="raw_bytes", default="", help="Comma-separated raw bytes (e.g. 0x7E,0x11,0x11)")
    parser.add_argument("--scroll-delay", type=float, default=0.08, help="Delay between scroll frames")
    parser.add_argument("--once", action="store_true", help="Send one frame and exit")
    parser.add_argument("--clock", action="store_true", help="Run clock mode: send HH.MM frames with blinking dot")
    args = parser.parse_args()

    # If user didn't provide text or raw bytes or once/clock flags, default to clock mode
    if not args.raw_bytes and args.text == "" and not args.once and not args.clock:
        args.clock = True

    source_columns = parse_byte_list(args.raw_bytes) if args.raw_bytes else text_to_columns(args.text)
    if not source_columns:
        source_columns = [0x00]

    pad = [0x00] * args.width
    scroll_data = pad + source_columns + pad

    try:
        with serial.Serial(args.port, args.baud, timeout=0.2) as ser:
            print(f"Opened {args.port} @ {args.baud}")

            if args.clock:
                # Prepare base columns for HHMM (4 digits, 5 columns each = 20 cols by default)
                dot_bit = 0x08
                while True:
                    t = time.localtime()
                    timestr = time.strftime("%H%M", t)
                    base_cols = []
                    for ch in timestr:
                        glyph = FONT_5X7.get(ch, FONT_5X7["?"])
                        base_cols.extend(glyph)
                    # ensure base length matches width
                    if len(base_cols) < args.width:
                        base_cols += [0x00] * (args.width - len(base_cols))
                    elif len(base_cols) > args.width:
                        base_cols = base_cols[: args.width]

                    # Dot position: end of second digit (index 2*5 - 1 == 9 for width=20)
                    dot_index = min(len(base_cols) - 1, 2 * 5 - 1)

                    dot_on = (int(time.time()) % 2) == 0
                    cols = base_cols.copy()
                    if dot_on:
                        cols[dot_index] = cols[dot_index] | dot_bit
                    else:
                        cols[dot_index] = cols[dot_index] & (~dot_bit & 0xFF)
                    send_frame(ser, cols)
                    time.sleep(1.0)

            if args.once:
                frame = (source_columns + pad)[: args.width]
                send_frame(ser, frame)
                print(f"Sent one frame ({len(frame)} bytes)")
                return

            while True:
                for i in range(0, len(scroll_data) - args.width + 5):
                    frame = scroll_data[i : i + args.width]
                    send_frame(ser, frame)
                    time.sleep(args.scroll_delay)
    except serial.SerialException as exc:
        print(f"Serial error: {exc}")
    except KeyboardInterrupt:
        print("Stopped")


if __name__ == "__main__":
    main()
