// HCMS-2903 Software SPI Control

#define DATA_PIN 6
#define CLOCK_PIN 7
#define REGISTER_SELECT 8

#define ENABLE 9
#define RESET 10


static const unsigned char MESSAGE[] = {
 	0x7E, 0x11, 0x11, 0x11, 0x7E,// A
	0x7F, 0x49, 0x49, 0x49, 0x36,// B
	0x3E, 0x41, 0x41, 0x41, 0x22,// C
	0x7F, 0x41, 0x41, 0x22, 0x1C // D
}; 

void pulseClock() {
    digitalWrite(CLOCK_PIN, HIGH);
    delayMicroseconds(1);
    digitalWrite(CLOCK_PIN, LOW);
}

void sendBit(bool bitValue) {
    digitalWrite(DATA_PIN, bitValue);
    pulseClock();
}

void sendByte(uint8_t data) {
    for (int i = 7; i >= 0; i--) {
        sendBit((data >> i) & 1);
    }
}

void sendData(uint8_t data) {
    // digitalWrite(REGISTER_SELECT, LOW); // Enter data mode
    // digitalWrite(ENABLE, LOW);
    sendByte(data);
    // digitalWrite(ENABLE, HIGH);
}

void sendCommand(uint8_t character) {
    digitalWrite(REGISTER_SELECT, HIGH); // Enter data commnd mode
    digitalWrite(ENABLE, LOW);  // Set #CS low 
    sendByte(character);
    digitalWrite(ENABLE, HIGH); // Set #CS HIGH 
}

void resetDisplay() {
    digitalWrite(RESET, LOW);
    delay(1);
    digitalWrite(RESET, HIGH);
}

void setup() {
    pinMode(DATA_PIN, OUTPUT);
    pinMode(REGISTER_SELECT, OUTPUT);
    pinMode(CLOCK_PIN, OUTPUT);
    pinMode(ENABLE, OUTPUT);
    pinMode(RESET, OUTPUT);

    digitalWrite(ENABLE, HIGH);
    resetDisplay();
    
   
   
    sendCommand(B10000001); // Set control word 1, see table 2 from datasheet. 
    sendCommand(B01110001); // Set control word 2, see table 2 from datasheet. 
    // sendData(0xff);
    // sendCommand(0x02, 0x07); // Enable display
}

void loop() {
    
    digitalWrite(REGISTER_SELECT, LOW); // Enter data mode
    digitalWrite(ENABLE, LOW);
    for (int i = 0; i < 20; i++) {
        sendData(MESSAGE[i]); 
        // sendData(i);
        
    }
    digitalWrite(ENABLE, HIGH);
    delay(100);
 
}
