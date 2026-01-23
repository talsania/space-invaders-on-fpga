// ============================================================================
// Project:     Real-Time Streaming Graphics System
// Module:      render_object_1
// Description: Autonomous projectile entity with collision response
// 
// Author:      Krishang Krishang Talsania
// Created:     2025-01-07
// Revision:    0.2 - 2025-01-08 - Added collision destroy
//
// Revisions:
//   0.0 - 2025-01-07 - Basic projectile movement
//   0.1 - 2025-01-07 - Trigger-based spawning
//   0.2 - 2025-01-08 - Collision detection integration
// ============================================================================

module render_object_1 (
    input  wire        clk,
    input  wire        rst_n,
    
    // Spawn command from object_0
    input  wire        trigger,
    input  wire [9:0]  spawn_x,
    input  wire [9:0]  spawn_y,
    
    // Collision input (destroys projectile)
    input  wire        collision_detected,
    
    // VGA
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire        video_on,
    
    output reg  [3:0]  vga_r,
    output reg  [3:0]  vga_g,
    output reg  [3:0]  vga_b,
    
    // Projectile positions (for collision)
    output reg  [9:0]  obj1_x,
    output reg  [9:0]  obj1_y,
    output reg         obj1_active
);

    localparam OBJ_WIDTH = 4;
    localparam OBJ_HEIGHT = 8;
    localparam PROJECTILE_VEL = 4;
    
    // Frame counter for movement timing (move every N clocks)
    localparam MOVE_DIVIDER = 500000;  // ~5ms at 100MHz (smooth movement)
    reg [19:0] move_counter;
    
    // Projectile state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            obj1_active <= 1'b0;
            obj1_x <= 10'd0;
            obj1_y <= 10'd0;
            move_counter <= 20'd0;
        end else begin
            move_counter <= move_counter + 1'b1;
            
            // Destroy projectile on collision
            if (collision_detected && obj1_active) begin
                obj1_active <= 1'b0;
                move_counter <= 20'd0;
            end
            // Spawn new projectile (only if none active)
            else if (trigger && !obj1_active) begin
                obj1_active <= 1'b1;
                obj1_x <= spawn_x + 10'd6;  // Center of 16-pixel sprite
                obj1_y <= spawn_y;
                move_counter <= 20'd0;
            end
            // Move projectile upward at regular intervals
            else if (move_counter == MOVE_DIVIDER && obj1_active) begin
                if (obj1_y > PROJECTILE_VEL) begin
                    obj1_y <= obj1_y - PROJECTILE_VEL;
                end else begin
                    obj1_active <= 1'b0;  // Projectile reached top
                end
                move_counter <= 20'd0;
            end
        end
    end
    
    // Draw projectile (combinational)
    wire in_obj_x = (pixel_x >= obj1_x) && (pixel_x < obj1_x + OBJ_WIDTH);
    wire in_obj_y = (pixel_y >= obj1_y) && (pixel_y < obj1_y + OBJ_HEIGHT);
    wire in_obj = obj1_active && in_obj_x && in_obj_y && video_on;
    
    always @(*) begin
        if (in_obj) begin
            // White projectile
            vga_r = 4'hF;
            vga_g = 4'hF;
            vga_b = 4'hF;
        end else begin
            // Transparent
            vga_r = 4'h0;
            vga_g = 4'h0;
            vga_b = 4'h0;
        end
    end

endmodule
