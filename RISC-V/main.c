#include <femtorv32.h>


int main(){
    uint8_t leds = 0x01;
    while(1){
        printf("Hello from femto risv-c ");
        printf("Freq: %d MHz\r\n", FEMTORV32_FREQ);
        *(volatile uint32_t*)(0x400004) = leds;
        leds = (leds << 1) | (leds >> 7);
        delay(50);
        *(volatile uint32_t*)(0x400004) = 0;
        delay(100);
    }
    return 0;
}