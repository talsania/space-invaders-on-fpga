## =============================================================================
## Nexys A7-100T Constraints File
## Updated with ESP32 UART Bridge Support
## =============================================================================

## Clock signal (100 MHz)
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clk}];

## =============================================================================
## UART - ESP32 Bridge (via Pmod JA Connector)
## =============================================================================
## 
## Connection Mapping:
##   ESP32 TX (GPIO17) → FPGA RX (Pmod JA Pin 1 / C17)
##   ESP32 RX (GPIO16) → FPGA TX (Pmod JA Pin 2 / D18) [optional]
##   ESP32 GND         → FPGA GND (Pmod JA Pin 5 / GND)
##
## Pmod JA Pin Layout:
##   Pin 1 (C17): FPGA RX ← ESP32 TX
##   Pin 2 (D18): FPGA TX → ESP32 RX
##   Pin 3 (E18): Not used
##   Pin 4 (G17): Not used
##   Pin 5 (GND): Connect to ESP32 GND
##   Pin 6 (VCC): Do NOT connect (use separate ESP32 power)
##
## Alternative: USB-UART Bridge (comment out Pmod if using this)
## set_property -dict { PACKAGE_PIN C4    IOSTANDARD LVCMOS33 } [get_ports { uart_rx }];
## set_property -dict { PACKAGE_PIN D4    IOSTANDARD LVCMOS33 } [get_ports { uart_tx }];

## ESP32 via Pmod JA (PRIMARY CONFIGURATION)
set_property -dict { PACKAGE_PIN C17   IOSTANDARD LVCMOS33 } [get_ports { uart_rx }];    # JA1: ESP32 TX → FPGA RX
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { uart_tx }];    # JA2: FPGA TX → ESP32 RX

## =============================================================================
## LEDs (Game State Indicators)
## =============================================================================
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { led[0] }];     # Game State Bit 0
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { led[1] }];     # Game State Bit 1
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { led[2] }];     # Player Alive
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { led[3] }];     # Fire Active
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { led[4] }];     # Enemy Hit
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { led[5] }];     # UART Activity
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { led[6] }];     # Controller Connected
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports { led[7] }];     # Reserved
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { led[8] }];     # Reserved
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { led[9] }];     # Reserved
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports { led[10] }];    # Reserved
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { led[11] }];    # Reserved
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { led[12] }];    # Reserved
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports { led[13] }];    # Reserved
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { led[14] }];    # Reserved
set_property -dict { PACKAGE_PIN V11   IOSTANDARD LVCMOS33 } [get_ports { led[15] }];    # Reserved

## =============================================================================
## Switches (Debug/Testing)
## =============================================================================
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }];
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }];
set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }];
set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }];
set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports { sw[4] }];
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { sw[5] }];
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { sw[6] }];
set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports { sw[7] }];
set_property -dict { PACKAGE_PIN T8    IOSTANDARD LVCMOS33 } [get_ports { sw[8] }];
set_property -dict { PACKAGE_PIN U8    IOSTANDARD LVCMOS33 } [get_ports { sw[9] }];
set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports { sw[10] }];
set_property -dict { PACKAGE_PIN T13   IOSTANDARD LVCMOS33 } [get_ports { sw[11] }];
set_property -dict { PACKAGE_PIN H6    IOSTANDARD LVCMOS33 } [get_ports { sw[12] }];
set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports { sw[13] }];
set_property -dict { PACKAGE_PIN U11   IOSTANDARD LVCMOS33 } [get_ports { sw[14] }];
set_property -dict { PACKAGE_PIN V10   IOSTANDARD LVCMOS33 } [get_ports { sw[15] }];

## =============================================================================
## Push Buttons (Manual Override)
## =============================================================================
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { btn_center }];
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports { btn_up }];
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports { btn_left }];
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports { btn_right }];
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { btn_down }];

## =============================================================================
## Reset Button (CPU_RESET)
## =============================================================================
set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports { rst_n }];

## =============================================================================
## VGA Connector (12-bit color)
## =============================================================================
## Red Channel (4 bits)
set_property -dict { PACKAGE_PIN A3    IOSTANDARD LVCMOS33 } [get_ports { vga_r[0] }];
set_property -dict { PACKAGE_PIN B4    IOSTANDARD LVCMOS33 } [get_ports { vga_r[1] }];
set_property -dict { PACKAGE_PIN C5    IOSTANDARD LVCMOS33 } [get_ports { vga_r[2] }];
set_property -dict { PACKAGE_PIN A4    IOSTANDARD LVCMOS33 } [get_ports { vga_r[3] }];

## Green Channel (4 bits)
set_property -dict { PACKAGE_PIN C6    IOSTANDARD LVCMOS33 } [get_ports { vga_g[0] }];
set_property -dict { PACKAGE_PIN A5    IOSTANDARD LVCMOS33 } [get_ports { vga_g[1] }];
set_property -dict { PACKAGE_PIN B6    IOSTANDARD LVCMOS33 } [get_ports { vga_g[2] }];
set_property -dict { PACKAGE_PIN A6    IOSTANDARD LVCMOS33 } [get_ports { vga_g[3] }];

## Blue Channel (4 bits)
set_property -dict { PACKAGE_PIN B7    IOSTANDARD LVCMOS33 } [get_ports { vga_b[0] }];
set_property -dict { PACKAGE_PIN C7    IOSTANDARD LVCMOS33 } [get_ports { vga_b[1] }];
set_property -dict { PACKAGE_PIN D7    IOSTANDARD LVCMOS33 } [get_ports { vga_b[2] }];
set_property -dict { PACKAGE_PIN D8    IOSTANDARD LVCMOS33 } [get_ports { vga_b[3] }];

## Sync Signals
set_property -dict { PACKAGE_PIN B11   IOSTANDARD LVCMOS33 } [get_ports { vga_hsync }];
set_property -dict { PACKAGE_PIN B12   IOSTANDARD LVCMOS33 } [get_ports { vga_vsync }];

## =============================================================================
## Pmod Connectors (Additional I/O)
## =============================================================================

## Pmod JA (Used for ESP32 UART - See above)
# set_property -dict { PACKAGE_PIN C17   IOSTANDARD LVCMOS33 } [get_ports { ja[0] }];   # JA1 - UART RX
# set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { ja[1] }];   # JA2 - UART TX
# set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { ja[2] }];   # JA3
# set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { ja[3] }];   # JA4
# set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS33 } [get_ports { ja[4] }];   # JA7
# set_property -dict { PACKAGE_PIN E17   IOSTANDARD LVCMOS33 } [get_ports { ja[5] }];   # JA8
# set_property -dict { PACKAGE_PIN F18   IOSTANDARD LVCMOS33 } [get_ports { ja[6] }];   # JA9
# set_property -dict { PACKAGE_PIN G18   IOSTANDARD LVCMOS33 } [get_ports { ja[7] }];   # JA10

## Pmod JB (Available for expansion)
set_property -dict { PACKAGE_PIN D14   IOSTANDARD LVCMOS33 } [get_ports { jb[0] }];   # JB1
set_property -dict { PACKAGE_PIN F16   IOSTANDARD LVCMOS33 } [get_ports { jb[1] }];   # JB2
set_property -dict { PACKAGE_PIN G16   IOSTANDARD LVCMOS33 } [get_ports { jb[2] }];   # JB3
set_property -dict { PACKAGE_PIN H14   IOSTANDARD LVCMOS33 } [get_ports { jb[3] }];   # JB4
set_property -dict { PACKAGE_PIN E16   IOSTANDARD LVCMOS33 } [get_ports { jb[4] }];   # JB7
set_property -dict { PACKAGE_PIN F13   IOSTANDARD LVCMOS33 } [get_ports { jb[5] }];   # JB8
set_property -dict { PACKAGE_PIN G13   IOSTANDARD LVCMOS33 } [get_ports { jb[6] }];   # JB9
set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { jb[7] }];   # JB10

## Pmod JC (Available for expansion)
set_property -dict { PACKAGE_PIN K1    IOSTANDARD LVCMOS33 } [get_ports { jc[0] }];   # JC1
set_property -dict { PACKAGE_PIN F6    IOSTANDARD LVCMOS33 } [get_ports { jc[1] }];   # JC2
set_property -dict { PACKAGE_PIN J2    IOSTANDARD LVCMOS33 } [get_ports { jc[2] }];   # JC3
set_property -dict { PACKAGE_PIN G6    IOSTANDARD LVCMOS33 } [get_ports { jc[3] }];   # JC4
set_property -dict { PACKAGE_PIN E7    IOSTANDARD LVCMOS33 } [get_ports { jc[4] }];   # JC7
set_property -dict { PACKAGE_PIN J3    IOSTANDARD LVCMOS33 } [get_ports { jc[5] }];   # JC8
set_property -dict { PACKAGE_PIN J4    IOSTANDARD LVCMOS33 } [get_ports { jc[6] }];   # JC9
set_property -dict { PACKAGE_PIN E6    IOSTANDARD LVCMOS33 } [get_ports { jc[7] }];   # JC10

## Pmod JD (Available for expansion)
set_property -dict { PACKAGE_PIN H4    IOSTANDARD LVCMOS33 } [get_ports { jd[0] }];   # JD1
set_property -dict { PACKAGE_PIN H1    IOSTANDARD LVCMOS33 } [get_ports { jd[1] }];   # JD2
set_property -dict { PACKAGE_PIN G1    IOSTANDARD LVCMOS33 } [get_ports { jd[2] }];   # JD3
set_property -dict { PACKAGE_PIN G3    IOSTANDARD LVCMOS33 } [get_ports { jd[3] }];   # JD4
set_property -dict { PACKAGE_PIN H2    IOSTANDARD LVCMOS33 } [get_ports { jd[4] }];   # JD7
set_property -dict { PACKAGE_PIN G4    IOSTANDARD LVCMOS33 } [get_ports { jd[5] }];   # JD8
set_property -dict { PACKAGE_PIN G2    IOSTANDARD LVCMOS33 } [get_ports { jd[6] }];   # JD9
set_property -dict { PACKAGE_PIN F3    IOSTANDARD LVCMOS33 } [get_ports { jd[7] }];   # JD10

## =============================================================================
## Configuration
## =============================================================================
set_property CONFIG_VOLTAGE 3.3 [current_design];
set_property CFGBVS VCCO [current_design];

## =============================================================================
## Timing Constraints (if needed)
## =============================================================================

## UART Timing (relaxed for 115200 baud)
## One bit period at 115200 baud ≈ 8.68 μs
set_input_delay -clock [get_clocks sys_clk_pin] -max 1.0 [get_ports uart_rx]
set_input_delay -clock [get_clocks sys_clk_pin] -min 0.5 [get_ports uart_rx]
set_output_delay -clock [get_clocks sys_clk_pin] -max 1.0 [get_ports uart_tx]
set_output_delay -clock [get_clocks sys_clk_pin] -min 0.5 [get_ports uart_tx]

## VGA Timing (25.175 MHz pixel clock for 640x480@60Hz)
## These constraints should be adjusted based on your VGA controller implementation
# create_generated_clock -name vga_clk -source [get_pins clk_gen/clk_out] -divide_by 4 [get_pins vga_ctrl/pixel_clk]

## =============================================================================
## Notes:
## =============================================================================
## 
## 1. ESP32 Connection via Pmod JA:
##    - Wire ESP32 TX (GPIO17) to Pmod JA Pin 1 (C17)
##    - Wire ESP32 RX (GPIO16) to Pmod JA Pin 2 (D18)
##    - Connect ESP32 GND to Pmod JA Pin 5 (GND)
##    - Power ESP32 separately via USB or external 3.3V supply
##
## 2. Alternative USB-UART Bridge:
##    - Comment out Pmod JA uart_rx/uart_tx lines
##    - Uncomment the USB-UART lines (C4/D4)
##    - Use for PC-based testing with Python scripts
##
## 3. LED Indicators:
##    - LED[5]: Flashes on UART activity (helps debug connectivity)
##    - LED[6]: Solid when controller connected (optional feature)
##
## 4. Pmod Connectors:
##    - JB, JC, JD available for future expansion
##    - Can add: audio output, additional sensors, etc.
##
## =============================================================================
