#include <ps5Controller.h>

// Configuration
#define UART_BAUD 115200
#define UPDATE_RATE_HZ 60
#define UPDATE_INTERVAL_MS (1000 / UPDATE_RATE_HZ)
#define START_PULSE_DURATION_MS 500

// Hardware UART pins
#define FPGA_RX_PIN 16  // ESP32 GPIO16 ← FPGA TX
#define FPGA_TX_PIN 17  // ESP32 GPIO17 → FPGA RX

// DualSense - MAC address
const char* ps5_MAC = "44:46:48:20:5C:CD";

// Packet Structure
typedef struct {
    uint8_t packet_type;
    uint8_t direction;
    uint8_t action;
    uint8_t reserved[5];
} __attribute__((packed)) fpga_packet_t;

// Global State
unsigned long lastUpdate = 0;
bool controllerConnected = false;
bool gameStarted = false;
unsigned long startButtonPressTime = 0;

void setup() {
    // USB Serial for debugging
    Serial.begin(115200);
    delay(1000);
    
    // **CRITICAL FIX: Use Serial2 instead of Serial1**
    Serial2.begin(UART_BAUD, SERIAL_8N1, FPGA_RX_PIN, FPGA_TX_PIN);
    delay(500);
    
    Serial.println("\n╔═════════════════════════════╗");
    Serial.println("║  PS5 → ESP32 → FPGA Bridge  ║");
    Serial.println("║  (Serial2 on GPIO16/17)     ║");
    Serial.println("╚═════════════════════════════╝");
    Serial.printf("FPGA UART: TX=GPIO%d, RX=GPIO%d @ %d baud\n", 
                  FPGA_TX_PIN, FPGA_RX_PIN, UART_BAUD);
    Serial.printf("Waiting for PS5 controller: %s\n", ps5_MAC);
    
    ps5.attachOnConnect(onConnect);
    ps5.attachOnDisconnect(onDisconnect);
    ps5.begin(ps5_MAC);
    
    Serial.println("Press PS button on controller to connect...");
}

void onConnect() {
    controllerConnected = true;
    gameStarted = false;
    
    Serial.println("✓ PS5 Controller Connected!");
    Serial.printf("   Battery: %d%%\n", ps5.Battery());
    
    ps5.setRumble(100, 100);
    delay(200);
    ps5.setRumble(0, 0);
    
    Serial.println("⚡ Auto-starting game...");
    startButtonPressTime = millis();
}

void onDisconnect() {
    controllerConnected = false;
    gameStarted = false;
    Serial.println("✗ Controller Disconnected");
}

void sendStartCommand() {
    fpga_packet_t packet = {0};
    packet.packet_type = 0x01;
    packet.direction = 0x09;
    packet.action = 0x01;
    
    Serial2.write((uint8_t*)&packet, sizeof(packet));  // Changed to Serial2
    Serial2.flush();
    
    Serial.println("→ START command sent [01 09 01 00 00 00 00 00]");
}

void sendReleaseCommand() {
    fpga_packet_t packet = {0};
    packet.packet_type = 0x01;
    packet.direction = 0x00;
    packet.action = 0x00;
    
    Serial2.write((uint8_t*)&packet, sizeof(packet));  // Changed to Serial2
    Serial2.flush();
}

void loop() {
    // Handle auto-start sequence
    if (controllerConnected && !gameStarted) {
        unsigned long elapsed = millis() - startButtonPressTime;
        
        if (elapsed < START_PULSE_DURATION_MS) {
            sendStartCommand();
            delay(50);
        } else {
            sendReleaseCommand();
            gameStarted = true;
            Serial.println("✓ Game started! Controller ready.");
            
            ps5.setRumble(150, 150);
            delay(100);
            ps5.setRumble(0, 0);
            delay(50);
            ps5.setRumble(150, 150);
            delay(100);
            ps5.setRumble(0, 0);
        }
        return;
    }
    
    // Throttle updates
    if (millis() - lastUpdate < UPDATE_INTERVAL_MS) {
        return;
    }
    lastUpdate = millis();
    
    if (!ps5.isConnected() || !gameStarted) {
        return;
    }
    
    // Parse Controller State
    fpga_packet_t packet = {0};
    packet.packet_type = 0x01;
    
    // Map Left Stick
    int16_t stickX = ps5.LStickX();
    int16_t stickY = ps5.LStickY();
    
    if (abs(stickY) > 50 || abs(stickX) > 50) {
        if (abs(stickY) > abs(stickX)) {
            packet.direction = (stickY < 0) ? 1 : 2;
        } else {
            packet.direction = (stickX < 0) ? 3 : 4;
        }
    }
    
    // D-Pad override
    if (ps5.Up())    packet.direction = 1;
    if (ps5.Down())  packet.direction = 2;
    if (ps5.Left())  packet.direction = 3;
    if (ps5.Right()) packet.direction = 4;
    
    // X Button to shoot
    if (ps5.Cross()) {
        packet.action = 1;
    }
    
    // OPTIONS to restart
    if (ps5.Options()) {
        Serial.println("⟳ Restarting game...");
        gameStarted = false;
        startButtonPressTime = millis();
        return;
    }
    
    // Send to FPGA
    Serial2.write((uint8_t*)&packet, sizeof(packet));  // Changed to Serial2
    Serial2.flush();
    
    // Optional debug
    if (packet.direction != 0 || packet.action != 0) {
        Serial.printf("→ [%02X %02X %02X...] Dir=%d Act=%d\n",
                      packet.packet_type, packet.direction, packet.action,
                      packet.direction, packet.action);
    }
}

// ...DEBUGGING SCRIPT...

// #define FPGA_TX_PIN 17  // ESP32 GPIO17 → FPGA RX (C17)
// #define FPGA_RX_PIN 16  // ESP32 GPIO16 ← FPGA TX (D18)
// #define UART_BAUD 115200

// // Test packet structure
// typedef struct {
//     uint8_t packet_type;
//     uint8_t direction;
//     uint8_t action;
//     uint8_t reserved[5];
// } __attribute__((packed)) fpga_packet_t;

// void setup() {
//     // USB Serial for debugging
//     Serial.begin(115200);
//     delay(1000);
    
//     // FPGA Serial on GPIO16/17
//     Serial2.begin(UART_BAUD, SERIAL_8N1, FPGA_RX_PIN, FPGA_TX_PIN);
//     delay(100);
    
//     Serial.println("╔══════════════════════════╗");
//     Serial.println("║  ESP32 → FPGA UART Test  ║");
//     Serial.println("╚══════════════════════════╝");
//     Serial.printf("TX=GPIO%d, RX=GPIO%d @ %d baud\n\n", 
//                   FPGA_TX_PIN, FPGA_RX_PIN, UART_BAUD);
    
//     Serial.println("Starting continuous packet transmission...");
//     Serial.println("Watch FPGA LED[5] - it should blink!");
//     Serial.println("===\n");
// }

// void loop() {
//     static uint32_t packetNum = 0;
//     static uint32_t testCycle = 0;
    
//     fpga_packet_t packet = {0};
    
//     // Cycle through different test patterns
//     switch(testCycle % 5) {
//         case 0: // Test pattern 1
//             packet.packet_type = 0xFF;
//             packet.direction = 0xAA;
//             packet.action = 0x55;
//             Serial.println("→ Test Pattern: [FF AA 55 00 00 00 00 00]");
//             break;
            
//         case 1: // START command (what you need)
//             packet.packet_type = 0x01;
//             packet.direction = 0x09;
//             packet.action = 0x01;
//             Serial.println("→ START Command: [01 09 01 00 00 00 00 00]");
//             break;
            
//         case 2: // Movement UP
//             packet.packet_type = 0x01;
//             packet.direction = 0x01;
//             packet.action = 0x00;
//             Serial.println("→ Move UP: [01 01 00 00 00 00 00 00]");
//             break;
            
//         case 3: // Fire action
//             packet.packet_type = 0x01;
//             packet.direction = 0x00;
//             packet.action = 0x01;
//             Serial.println("→ FIRE: [01 00 01 00 00 00 00 00]");
//             break;
            
//         case 4: // Idle/release
//             packet.packet_type = 0x01;
//             packet.direction = 0x00;
//             packet.action = 0x00;
//             Serial.println("→ IDLE: [01 00 00 00 00 00 00 00]");
//             break;
//     }
    
//     // Send packet to FPGA
//     size_t written = Serial2.write((uint8_t*)&packet, sizeof(packet));
    
//     Serial.printf("   Bytes written: %d, Packet #%d\n", written, ++packetNum);
    
//     // Check if FPGA is sending anything back
//     if (Serial2.available()) {
//         Serial.print("   ← FPGA Response: ");
//         while (Serial2.available()) {
//             uint8_t b = Serial2.read();
//             Serial.printf("%02X ", b);
//         }
//         Serial.println();
//     }
    
//     Serial.println();
    
//     testCycle++;
//     delay(1000);  // Send one packet per second
    
//     // Every 10 seconds, print status
//     if (packetNum % 10 == 0) {
//         Serial.println("═══");
//         Serial.printf("Status: %d packets sent\n", packetNum);
//         Serial.println("Check FPGA LED[5] - blinking?");
//         Serial.println("═══\n");
//     }
// }