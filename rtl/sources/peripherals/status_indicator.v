// ============================================================================
// Project:     Real-Time Streaming Graphics System
// Module:      status_indicator
// Description: LED output driver with state-dependent patterns
// 
// Author:      Krishang Krishang Talsania
// Created:     2025-01-08
// Revision:    0.1 - 2025-01-08 - Animation patterns added
//
// Revisions:
//   0.0 - 2025-01-08 - Simple binary counter display
//   0.1 - 2025-01-08 - State-based LED patterns
// ============================================================================

module status_indicator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [4:0]  event_count,  // 0-24 accumulated events
    input  wire [1:0]  ctrl_state,
    
    output reg  [15:0] led
);

    // ========== State Definitions ==========
    localparam STATE_MENU     = 2'b00;
    localparam STATE_PLAYING  = 2'b01;
    localparam STATE_VICTORY  = 2'b10;
    localparam STATE_GAMEOVER = 2'b11;
    
    // ========== Animation Counter ==========
    // For blinking/scrolling effects
    reg [25:0] anim_counter;
    reg [3:0] blink_state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            anim_counter <= 0;
            blink_state <= 0;
        end else begin
            anim_counter <= anim_counter + 1;
            
            // Update blink state every ~0.25 seconds
            if (anim_counter == 26'd25_000_000) begin
                anim_counter <= 0;
                blink_state <= blink_state + 1;
            end
        end
    end
    
    // ========== LED Pattern Generation ==========
    always @(*) begin
        case (ctrl_state)
            // ===== MENU State =====
            STATE_MENU: begin
                // Pulsing center pattern - "Press Start"
                case (blink_state[1:0])
                    2'b00: led = 16'b0000_0110_0110_0000;  // Center 4 LEDs
                    2'b01: led = 16'b0001_1001_1001_1000;  // Expand
                    2'b10: led = 16'b0111_0000_0000_1110;  // More expand
                    2'b11: led = 16'b1000_0000_0000_0001;  // Edge only
                endcase
            end
            
            // ===== PLAYING State =====
            STATE_PLAYING: begin
                // Binary event count display on lower 5 LEDs
                // Upper LEDs show progress bar
                led = {11'h0, event_count};
                
                // Alternative: Progress bar visualization
                // case (event_count)
                //     5'd0:       led = 16'b0000_0000_0000_0000;
                //     5'd1 - 5'd6:  led = {10'b0, 6'b111111};
                //     5'd7 - 5'd12: led = {4'b0, 12'b111111111111};
                //     default:    led = 16'b1111111111111111;
                // endcase
            end
            
            // ===== VICTORY State =====
            STATE_VICTORY: begin
                // Scrolling pattern - celebration!
                case (blink_state[2:0])
                    3'b000: led = 16'b1000_0000_0000_0001;
                    3'b001: led = 16'b0100_0000_0000_0010;
                    3'b010: led = 16'b0010_0000_0000_0100;
                    3'b011: led = 16'b0001_0000_0000_1000;
                    3'b100: led = 16'b0000_1000_0001_0000;
                    3'b101: led = 16'b0000_0100_0010_0000;
                    3'b110: led = 16'b0000_0010_0100_0000;
                    3'b111: led = 16'b0000_0001_1000_0000;
                endcase
            end
            
            // ===== GAMEOVER State =====
            STATE_GAMEOVER: begin
                // Alternating pattern - sad face
                if (blink_state[0]) begin
                    led = 16'b1010_1010_1010_1010;  // Odd LEDs
                end else begin
                    led = 16'b0101_0101_0101_0101;  // Even LEDs
                end
            end
            
            default: begin
                led = 16'h0000;
            end
        endcase
    end

endmodule
