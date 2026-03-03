import serial
import time

# Configuration
PORT = "/dev/cu.usbserial-20122301"
BAUDRATE = 115200
INTERVAL = 0.01  # 150 ms

def main():
    try:
        with serial.Serial(PORT, BAUDRATE) as ser:
            print(f"Opened {PORT} at {BAUDRATE} baud")

            while True:
                # Count up 0 -> 255
                for value in range(256):
                    ser.write(bytes([value]))
                    # print(f"Sent: {value}")
                    time.sleep(INTERVAL)

                # Count down 254 -> 0 (avoid repeating 255)
                for value in range(254, -1, -1):
                    ser.write(bytes([value]))
                    # print(f"Sent: {value}")
                    time.sleep(INTERVAL)

    except serial.SerialException as e:
        print(f"Serial error: {e}")
    except KeyboardInterrupt:
        print("\nStopped by user")

if __name__ == "__main__":
    main()