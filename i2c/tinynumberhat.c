#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>
#include <time.h>

#define HT16K33_ADDRESS_0 0x70

#define HT16K33_CMD_TURN_ON_OSCILLATOR 0x21
#define HT16K33_CMD_ENABLE_DISPLAY 0x81
#define HT16K33_CMD_BRIGHTNESS 0xE0
#define LED_DRIVER_BRIGHTNESS_LEVEL 0x0C

#define KEY_A_BIT 4
#define KEY_B_BIT 5
#define KEY_C_BIT 6
#define KEY_D_BIT 7
#define KEY_PRESS_EVT 0x1
#define KEY_RELEASE_EVT 0x2

#define MAX_ASCII 128

const unsigned char sgmt_font[MAX_ASCII] = {
        ['0'] = 0b00111111,
        ['1'] = 0b00000110,
        ['2'] = 0b01011011,
        ['3'] = 0b01001111,
        ['4'] = 0b01100110,
        ['5'] = 0b01101101,
        ['6'] = 0b01111101,
        ['7'] = 0b00000111,
        ['8'] = 0b01111111,
        ['9'] = 0b01101111,
        ['.'] = 0b10000000,
        ['P'] = 0b01110011,
        ['L'] = 0b00111000,
        ['A'] = 0b01110111,
        ['Y'] = 0b01101110,
        ['S'] = 0b01101101,
        ['T'] = 0b01111000,
        ['O'] = 0b00111111,
        ['U'] = 0b00111110,
        ['E'] = 0b01111001,
        [' '] = 0b00000000,
        ['H'] = 0b01110110,
        ['-'] = 0b01000000,
        ['B'] = 0b01111100,
        ['C'] = 0b00111001,
        ['D'] = 0b01011110,
        ['F'] = 0b01110001,
        ['G'] = 0b01111101,
        ['I'] = 0b00000110,
        ['J'] = 0b00011110,
        ['K'] = 0b01110101,
        ['M'] = 0b01010100,
        ['N'] = 0b01010100,
        ['Q'] = 0b01101011,
        ['R'] = 0b01010000,
        ['V'] = 0b00111110,
        ['W'] = 0b00101010,
        ['X'] = 0b01110110,
        ['Z'] = 0b01011011,
        ['!'] = 0b10000110,
        ['?'] = 0b01010011,
        ['*'] = 0b01100011,
        ['#'] = 0b01111100,
        ['$'] = 0b01101101
};


unsigned char find_fnt_value(char key) {
    if (key < MAX_ASCII) {
        return sgmt_font[(int)key];
    }
    return 0; // Default value if key not found
}


const char *device = "/dev/i2c-0"; // I2C bus device path
int fd;

void getTime(char *buffer, size_t size){
    time_t currentTime = time(NULL);
    struct tm *localTime = localtime(&currentTime);
    snprintf(buffer, size, "%02d-%02d-%02d.", localTime->tm_hour, localTime->tm_min, localTime->tm_sec);
}

int send_ht16k_cmd(int device_fd, unsigned char command){
    // Send command
    unsigned char cmd[2] = {command, 0x00};
    if (write(device_fd, cmd, sizeof(cmd)) != sizeof(cmd)) {
        perror("Error: Unable to turn on oscillator for device");
        close(device_fd);
        return 1;
    }
    return 0;
}

int set_led_driver_brightness(int device_fd, unsigned char brightness){
    // Set brightness
    send_ht16k_cmd(device_fd, HT16K33_CMD_BRIGHTNESS | brightness);
    return  0;
}

int tinynumberhat_init(){
    fd = open(device, O_RDWR);
    if (fd < 0) {
        perror("Error: Unable to open I2C device");
        return 1;
    }

    // Set up the first HT16K33 LED driver
    if (ioctl(fd, I2C_SLAVE, HT16K33_ADDRESS_0) < 0) {
        perror("Error: Unable to set I2C slave address for device 0");
        close(fd);
        return 1;
    }

    // Set up the first HT16K33 LED driver
    if (ioctl(fd, I2C_SLAVE, HT16K33_ADDRESS_0) < 0) {
        perror("Error: Unable to set I2C slave address for device 0");
        close(fd);
        return 1;
    }

    // Turn on oscillator
    send_ht16k_cmd(fd, HT16K33_CMD_TURN_ON_OSCILLATOR);

    // Enable display
    send_ht16k_cmd(fd, HT16K33_CMD_ENABLE_DISPLAY);

    // Set brightness
    send_ht16k_cmd(fd, HT16K33_CMD_BRIGHTNESS | LED_DRIVER_BRIGHTNESS_LEVEL);

    return 0;

}

int write_led_driver_data(int led_driver_fd, const unsigned  char * led_driver_data){
    unsigned char cmd[2];
    for (int j = 0; j < 16; ++j) {
        unsigned char reg_addr = j;
        cmd[0] = reg_addr;
        cmd[1] = led_driver_data[j];
        if (write(led_driver_fd, cmd, sizeof(cmd)) != sizeof(cmd)) {
            perror("Error: Unable to write data to device 1");
            close(led_driver_fd);
            return 1;
        }
    }
    return 0;
}

int read_buttons(int led_driver_fd, unsigned char * button_values){
    //    Set the read start address for the button data
    unsigned char key_reg = {0x40};
    if (write(led_driver_fd, &key_reg, 1) != 1) {
        perror("Unable to  set read address to the device 1");
        close(led_driver_fd);
        return 1;
    }

    //   Read the entire button 6 bytes data
    if(read(led_driver_fd, button_values, 6) != 6){
        perror("Failed to read button data from the driver");
        close(led_driver_fd);
        return 1;
    }
    return 0;
}

int main(){
    tinynumberhat_init();
    printf("Tinynumberhat\n");
    char str[10];
    unsigned char buffer[16];


    // Button variables
    unsigned char  key_5 = 0;
    unsigned char  key_a =0, key_b=0, key_d=0, key_c = 0;

    // Display brightness level variable
    unsigned char display_brightness_level = 0x01;

    unsigned char  trail = 0;

    while (1){
        getTime(str, sizeof(str));
        for (int i = 0; i < sizeof(str); i++) {
            buffer[i] = find_fnt_value(str[i]);
        }
        trail = ~ trail;
        if(trail == 0)
            buffer[8] = 0b10000000;
        else
            buffer[8] = 0;

        write_led_driver_data(fd, buffer);

        unsigned char  button_values[6];
        read_buttons(fd, button_values);
        // extract last byte for connected keys
//        printf("keys: 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, 0x%x \n", button_values[5], button_values[4], button_values[3], button_values[2], button_values[1], button_values[0]);

        key_a = (key_a << 1) | (button_values[4] & (1 << KEY_A_BIT)) >> KEY_A_BIT;
        key_a = key_a & 0b00000011;

        if (key_a == KEY_PRESS_EVT){
            printf("Key a press\n");
        }
        if (key_a == KEY_RELEASE_EVT){
            printf("Key a release\n");
        }

        key_b = (key_b << 1) | (button_values[4] & (1 << KEY_B_BIT)) >> KEY_B_BIT;
        key_b = key_b & 0b00000011;

        if (key_b == KEY_PRESS_EVT){
            printf("Key b press\n");
        }
        if (key_b == KEY_RELEASE_EVT){
            printf("Key b release\n");
        }

        key_c = (key_c << 1) | (button_values[4] & (1 << KEY_C_BIT)) >> KEY_C_BIT;
        key_c = key_c & 0b00000011;

        if (key_c == KEY_PRESS_EVT){
            printf("Key c press\n");
            if(display_brightness_level < 15){
                display_brightness_level ++;
                set_led_driver_brightness(fd, display_brightness_level);
                printf("Brightness set to: %d\n", display_brightness_level);
            }
        }
        if (key_c == KEY_RELEASE_EVT){
            printf("Key c release\n");
        }

        key_d = (key_d << 1) | (button_values[4] & (1 << KEY_D_BIT)) >> KEY_D_BIT;
        key_d = key_d & 0b00000011;

        if (key_d == KEY_PRESS_EVT){
            printf("Key d press\n");
            if(display_brightness_level > 0){
                display_brightness_level --;
                set_led_driver_brightness(fd, display_brightness_level);
                printf("Brightness set to: %d\n", display_brightness_level);
            }
        }
        if (key_d == KEY_RELEASE_EVT){
            printf("Key d release\n");
        }

        usleep(100000);
    }

    return 0;
}