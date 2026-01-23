// ============================================================================
// Project:     Real-Time Streaming Graphics System
// Module:      render_group
// Description: Multi-element renderer with coordinated movement
// 
// Author:      Krishang Krishang Talsania
// Created:     2025-01-07
// Revision:    0.2 - 2025-01-08 - Packet-driven animation
//
// Revisions:
//   0.0 - 2025-01-07 - Static grid rendering
//   0.1 - 2025-01-08 - Collision-based element removal
//   0.2 - 2025-01-08 - Movement from scheduler packets
// ============================================================================

module render_group (
    input  wire        clk,
    input  wire        rst_n,
    
    // ===== Movement Command (AXI-Stream from Scheduler) =====
    input  wire [63:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    input  wire        s_axis_tlast,
    output wire        s_axis_tready,
    
    // ===== Collision Detection =====
    input  wire        collision_detected,
    input  wire [1:0]  hit_row,
    input  wire [2:0]  hit_col,
    
    // ===== VGA Rendering =====
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire        video_on,
    
    output reg  [3:0]  vga_r,
    output reg  [3:0]  vga_g,
    output reg  [3:0]  vga_b,
    
    // ===== Status Outputs =====
    output reg  [9:0]  group_x,           // Group X position for collision
    output reg  [9:0]  group_y,           // Group Y position for collision
    output reg  [4:0]  active_count,      // Elements remaining
    output reg         halt_condition     // Termination trigger
);

    // ========== Constants ==========
    localparam GRID_COLS = 8;
    localparam GRID_ROWS = 3;
    localparam GROUP_ELEMENT_SIZE = 12;
    localparam SPACING = 60;
    
    // ========== Grid State ==========
    reg elements_alive [0:GRID_ROWS-1][0:GRID_COLS-1];
    reg direction;  // 0=right, 1=left
    reg [3:0] move_count;
    
    // Always ready to accept movement commands
    assign s_axis_tready = 1'b1;
    
    // ========== Initialization ==========
    integer init_row, init_col;
    initial begin
        group_x = 100;
        group_y = 50;
        direction = 0;  // Start moving right
        move_count = 0;
        active_count = 24;
        halt_condition = 0;
        
        // Initialize all elements as alive
        for (init_row = 0; init_row < GRID_ROWS; init_row = init_row + 1)
            for (init_col = 0; init_col < GRID_COLS; init_col = init_col + 1)
                elements_alive[init_row][init_col] = 1'b1;
    end
    
    // ========== Movement Logic ==========
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            group_x <= 100;
            group_y <= 50;
            direction <= 0;
            move_count <= 0;
            halt_condition <= 0;
        end else begin
            // Process event packet (type 0x03)
            if (s_axis_tvalid && s_axis_tlast && s_axis_tdata[7:0] == 8'h03) begin
                if (direction == 0) begin
                    // Moving right
                    if (group_x < 250) begin
                        group_x <= group_x + 4;  // Move right
                    end else begin
                        direction <= 1;          // Switch to left
                        group_y <= group_y + 20; // Drop down
                        move_count <= 0;
                    end
                end else begin
                    // Moving left
                    if (group_x > 20) begin
                        group_x <= group_x - 4;  // Move left
                    end else begin
                        direction <= 0;          // Switch to right
                        group_y <= group_y + 20; // Drop down
                        move_count <= 0;
                    end
                end
                move_count <= move_count + 1;
            end
            
            // Check halt condition (group reached bottom)
            if (group_y + (GRID_ROWS * SPACING) > 420) begin
                halt_condition <= 1;
            end
        end
    end
    
    // ========== Collision Handling ==========
    always @(posedge clk) begin
        if (collision_detected && 
            hit_row < GRID_ROWS && 
            hit_col < GRID_COLS &&
            elements_alive[hit_row][hit_col]) begin
            elements_alive[hit_row][hit_col] <= 1'b0;
            active_count <= active_count - 1;
        end
    end
    
    // ========== Rendering Logic ==========
    integer row, col;
    reg [9:0] element_x, element_y;
    reg in_element;
    
    always @(*) begin
        in_element = 0;
        
        // Check if current pixel is inside any alive element
        for (row = 0; row < GRID_ROWS; row = row + 1) begin
            for (col = 0; col < GRID_COLS; col = col + 1) begin
                if (elements_alive[row][col]) begin
                    element_x = group_x + (col * SPACING);
                    element_y = group_y + (row * SPACING);
                    
                    if ((pixel_x >= element_x) &&
                        (pixel_x < element_x + GROUP_ELEMENT_SIZE) &&
                        (pixel_y >= element_y) &&
                        (pixel_y < element_y + GROUP_ELEMENT_SIZE)) begin
                        in_element = 1;
                    end
                end
            end
        end
    end
    
    // Color output
    always @(*) begin
        if (!video_on || !in_element) begin
            vga_r = 4'h0;
            vga_g = 4'h0;
            vga_b = 4'h0;
        end else begin
            // Red elements
            vga_r = 4'hF;
            vga_g = 4'h0;
            vga_b = 4'h0;
        end
    end

endmodule
