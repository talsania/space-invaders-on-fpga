// ============================================================================
// Project:     Real-Time Streaming Graphics System
// Module:      system_controller
// Description: Top-level FSM managing system states (IDLE/ACTIVE/HALT)
// 
// Author:      Krishang Krishang Talsania
// Created:     2025-01-08
// Revision:    0.1 - 2025-01-08 - Initial state machine implementation
//
// Revisions:
//   0.0 - 2025-01-08 - Module created with 4-state FSM
//   0.1 - 2025-01-08 - Added reset pulse generator
// ============================================================================

module system_controller (
    input  wire        clk,
    input  wire        rst_n,
    
    // ===== Control Inputs =====
    input  wire        start_button,           // Press to start/restart
    input  wire [4:0]  active_count,           // 0-24 (remaining entities)
    input  wire        halt_condition,         // Termination trigger
    
    // ===== State Outputs =====
    output reg  [1:0]  ctrl_state,
    output wire        system_active,          // Enable system operation
    output wire        reset_pulse             // Pulse to reset entities
);

    // ========== State Definitions ==========
    localparam STATE_MENU     = 2'b00;  // Waiting to start
    localparam STATE_PLAYING  = 2'b01;  // System in progress
    localparam STATE_VICTORY  = 2'b10;  // All targets cleared
    localparam STATE_GAMEOVER = 2'b11;  // Halt condition met
    
    // System is only active during PLAYING state
    assign system_active = (ctrl_state == STATE_PLAYING);
    
    // ========== Button Debouncing ==========
    reg start_button_prev;
    reg start_button_prev2;
    wire start_pressed;
    
    // Debounce: detect rising edge after 2 clock cycles
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_button_prev <= 0;
            start_button_prev2 <= 0;
        end else begin
            start_button_prev2 <= start_button_prev;
            start_button_prev <= start_button;
        end
    end
    
    assign start_pressed = start_button_prev && !start_button_prev2;
    
    // ========== Reset Pulse Generator ==========
    reg reset_triggered;
    reg [3:0] reset_counter;
    
    assign reset_pulse = (reset_counter > 0);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_counter <= 0;
        end else begin
            if (reset_triggered) begin
                reset_counter <= 15;  // Hold reset for 15 cycles
            end else if (reset_counter > 0) begin
                reset_counter <= reset_counter - 1;
            end
        end
    end
    
    // ========== State Machine ==========
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_state <= STATE_MENU;
            reset_triggered <= 0;
        end else begin
            reset_triggered <= 0;  // Default: no reset
            
            case (ctrl_state)
                // ===== MENU State =====
                STATE_MENU: begin
                    if (start_pressed) begin
                        ctrl_state <= STATE_PLAYING;
                        reset_triggered <= 1;  // Reset entities
                    end
                end
                
                // ===== PLAYING State =====
                STATE_PLAYING: begin
                    if (active_count == 5'd0) begin
                        // All targets cleared
                        ctrl_state <= STATE_VICTORY;
                    end else if (halt_condition) begin
                        // Termination condition met
                        ctrl_state <= STATE_GAMEOVER;
                    end
                end
                
                // ===== VICTORY State =====
                STATE_VICTORY: begin
                    if (start_pressed) begin
                        ctrl_state <= STATE_MENU;
                    end
                end
                
                // ===== GAMEOVER State =====
                STATE_GAMEOVER: begin
                    if (start_pressed) begin
                        ctrl_state <= STATE_MENU;
                    end
                end
                
                default: begin
                    ctrl_state <= STATE_MENU;
                end
            endcase
        end
    end

endmodule
