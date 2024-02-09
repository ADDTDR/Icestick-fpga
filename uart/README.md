# UART transmitter 
- ## TX
    Time diagram 2 stop bits
    ![alt text](<img/Screenshot from 2024-02-04 11-02-27.png>)

    ```
    picocom -b 115200  /dev/ttyUSB0

    to set 2 stop bits press 
    Ctrl+j 2 Enter 

    ```
    ![alt text](<img/Screenshot from 2024-02-04 12-12-15.png>)

    <br>
    To exit from picocom press Ctrl+a flowwed by Ctrl+x

    <br>
    To see device utilisation statistics used by implementation build with -v flag 

    ```
        apio build -v 
    ```
    Output will contain device utilisation data along another info
    ```
    ...
    Info: Device utilisation:
    Info:            ICESTORM_LC:    37/ 1280     2%
    Info:           ICESTORM_RAM:     0/   16     0%
    Info:                  SB_IO:     4/  112     3%
    Info:                  SB_GB:     2/    8    25%
    Info:           ICESTORM_PLL:     0/    1     0%
    Info:            SB_WARMBOOT:     0/    1     0%
    ...
    ```
    <br>
    Connection:

    Icestick runs uart tx logic connected to  simple 
    cp2102 usb to serial adapter receiving serial data

    ![alt text](img/photo_5332521087524787232_y.jpg)

<br>
Increment asci symbol after each end of transfer:

![alt text](<img/Screenshot from 2024-02-04 16-09-42.png>)


```
abcdefghijklmnopqrstuvwxyz{|}▒▒..

```
# Use on board dual port FTDI USB to serial for uart communications 

Use second serial port on the ft2232h instead of external cp22x dongle 

Connections:
```
# -------------------------- FTDI --------------------------------------------
# --- FTDI 0:
set_io --warn-no-port RES  66
set_io --warn-no-port DONE 65
set_io --warn-no-port SS   71
set_io --warn-no-port MISO 67
set_io --warn-no-port MOSI 68
set_io --warn-no-port SCK  70
#
# --- FTDI 1: (Serial port)
set_io --warn-no-port DCD 1
set_io --warn-no-port DSR 2
set_io --warn-no-port DTR 3
set_io --warn-no-port CTS 4
set_io --warn-no-port RTS 7
set_io --warn-no-port TX  8
set_io --warn-no-port RX  9


```


FTDI             |  FPGA
:-------------------------:|:-------------------------:
![alt text](img/uart_ft232.PNG )  |  ![alt text](img/Capture_ttl_uart.PNG)

<br>
On host machine Use second serial device for UART communications.
as  a example the implementation reads from uart 1 byte increment by 1 
and send it back so if we press '1' we would see '2' back.