// ============================================================================
// Project:     Real-Time Streaming Graphics System
// Module:      render_object_0
// Description: Controllable rendering entity with position state
// 
// Author:      Krishang Krishang Talsania
// Created:     2025-01-06
// Revision:    0.3 - 2025-01-07 - Separated trigger from movement
//
// Revisions:
//   0.0 - 2025-01-06 - Basic sprite rendering
//   0.1 - 2025-01-06 - Added movement from packet input
//   0.2 - 2025-01-07 - Added trigger signal output
//   0.3 - 2025-01-07 - Fixed trigger/move independence bug
// ============================================================================

module render_object_0 (
    input  wire        clk,
    input  wire        rst_n,
    
    // From packet router (Port 0 - Control input)
    input  wire [63:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    input  wire        s_axis_tlast,
    output wire        s_axis_tready,
    
    // VGA pixel query
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire        video_on,
    
    // VGA output
    output reg  [3:0]  vga_r,
    output reg  [3:0]  vga_g,
    output reg  [3:0]  vga_b,
    
    // Object state (for collision/interaction)
    output reg  [9:0]  obj0_x,
    output reg  [9:0]  obj0_y,
    output reg         trigger
);

    // Object sprite size
    localparam OBJ_WIDTH = 16;
    localparam OBJ_HEIGHT = 16;
    
    // Movement parameters
    localparam VELOCITY = 4;
    
    // Screen boundaries
    localparam MAX_X = 624;  // 640 - OBJ_WIDTH
    localparam MAX_Y = 464;  // 480 - OBJ_HEIGHT
    
    assign s_axis_tready = 1'b1;  // Always ready
    
    // Extract packet fields
    wire [7:0] packet_type = s_axis_tdata[7:0];    // Byte 0
    wire [7:0] direction   = s_axis_tdata[15:8];   // Byte 1
    wire [7:0] action      = s_axis_tdata[23:16];  // Byte 2
    
    // Process input packets - SEPARATE movement and trigger
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            obj0_x <= 10'd320 - (OBJ_WIDTH/2);
            obj0_y <= 10'd450;
            trigger <= 1'b0;
        end else begin
            // Default: no trigger
            trigger <= 1'b0;
            
            if (s_axis_tvalid && s_axis_tlast) begin
                // Trigger action (INDEPENDENT of movement)
                if (action == 8'd1) begin
                    trigger <= 1'b1;  // Pulse for one clock cycle
                end
                
                // Movement (processes regardless of trigger)
                case (direction)
                    8'd1: begin  // Up
                        if (obj0_y > VELOCITY)
                            obj0_y <= obj0_y - VELOCITY;
                    end
                    8'd2: begin  // Down
                        if (obj0_y < MAX_Y)
                            obj0_y <= obj0_y + VELOCITY;
                    end
                    8'd3: begin  // Left
                        if (obj0_x > VELOCITY)
                            obj0_x <= obj0_x - VELOCITY;
                    end
                    8'd4: begin  // Right
                        if (obj0_x < MAX_X)
                            obj0_x <= obj0_x + VELOCITY;
                    end
                    default: begin
                        // No movement, but trigger might still be active
                    end
                endcase
            end
        end
    end
    
    // Draw object sprite (combinational)
    wire in_sprite_x = (pixel_x >= obj0_x) && (pixel_x < obj0_x + OBJ_WIDTH);
    wire in_sprite_y = (pixel_y >= obj0_y) && (pixel_y < obj0_y + OBJ_HEIGHT);
    wire in_sprite = in_sprite_x && in_sprite_y && video_on;
    
    always @(*) begin
        if (in_sprite) begin
            // Green square for object
            vga_r = 4'h0;
            vga_g = 4'hF;
            vga_b = 4'h0;
        end else begin
            // Transparent (let other layers show through)
            vga_r = 4'h0;
            vga_g = 4'h0;
            vga_b = 4'h0;
        end
    end

endmodule
