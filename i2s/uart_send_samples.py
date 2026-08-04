#!/usr/bin/env python3
import sys
import serial
import math
import time

PORT = sys.argv[1] if len(sys.argv) > 1 else '/dev/cu.usbserial-2012301'
SAMPLES = 1000
SAMPLE_RATE = 46875
CYCLES_IN_BUFFER = 8
FREQ_HZ = SAMPLE_RATE * CYCLES_IN_BUFFER / SAMPLES

ser = serial.Serial(PORT, 115200, timeout=1)
time.sleep(0.05)
ser.reset_output_buffer()

# Frame format: [0xA5, 0x5A][sample_count_lo][sample_count_hi][PCM16 little-endian payload]
# Repeat 0xA5 preamble to help the FPGA parser re-lock if any first byte is lost.
ser.write(bytes([0xA5] * 8 + [0x5A, SAMPLES & 0xFF, (SAMPLES >> 8) & 0xFF]))

# Send a simple tone as 16-bit little-endian samples.
for n in range(SAMPLES):
    value = int(0.6 * 32767 * math.sin(2 * math.pi * FREQ_HZ * n / SAMPLE_RATE))
    lo = value & 0xFF
    hi = (value >> 8) & 0xFF
    ser.write(bytes([lo, hi]))

ser.close()
print(f'Sent {SAMPLES} samples to {PORT} at {FREQ_HZ:.3f} Hz')
