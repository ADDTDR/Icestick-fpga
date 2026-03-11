import serial
import time

# Configuration
PORT = "/dev/cu.usbserial-20122301"
BAUDRATE = 115200
INTERVAL = 0.12  # 150 ms



def main():
    scale_values = [16, 32, 48, 64, 64, 48, 32, 16]
    try:
        with serial.Serial(PORT, BAUDRATE) as ser:
            print(f"Opened {PORT} at {BAUDRATE} baud")

            while True:
                # Count up 0 -> 255
                for value in scale_values + [0]:
                    ser.write(bytes([value]))
                    # print(f"Sent: {value}")
                time.sleep(INTERVAL)
                scale_values = scale_values[1:] + scale_values[:1]
 
    except serial.SerialException as e:
        print(f"Serial error: {e}")
    except KeyboardInterrupt:
        print("\nStopped by user")

if __name__ == "__main__":
    main()