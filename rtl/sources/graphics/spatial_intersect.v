// ============================================================================
// Project:     Real-Time Streaming Graphics System
// Module:      spatial_intersect
// Description: Real-time overlap detection for moving AABBs
// 
// Author:      Krishang Krishang Talsania
// Created:     2025-01-08
// Revision:    0.2 - 2025-01-08 - Dynamic grid position tracking
//
// Revisions:
//   0.0 - 2025-01-08 - Basic AABB collision
//   0.1 - 2025-01-08 - Tested with static grid
//   0.2 - 2025-01-08 - Updated for moving reference frame
// ============================================================================

module spatial_intersect (
    input  wire        clk,
    input  wire        rst_n,
    
    // ===== Projectile Position =====
    input  wire [9:0]  obj1_x,
    input  wire [9:0]  obj1_y,
    input  wire        obj1_active,
    
    // ===== Moving Grid Position =====
    input  wire [9:0]  group_x,
    input  wire [9:0]  group_y,
    
    // ===== Collision Output =====
    output reg         collision_detected,
    output reg  [2:0]  hit_row,    // 0-2 (3 rows)
    output reg  [3:0]  hit_col     // 0-7 (8 columns)
);

    // ========== Constants ==========
    localparam GRID_COLS = 8;
    localparam GRID_ROWS = 3;
    localparam GROUP_ELEMENT_SIZE = 12;
    localparam SPACING = 60;
    localparam OBJ1_WIDTH = 4;
    localparam OBJ1_HEIGHT = 8;
    
    // ========== Collision Detection Logic ==========
    integer row, col;
    reg [9:0] element_x, element_y;
    reg overlap_x, overlap_y;
    reg [2:0] temp_hit_row;
    reg [3:0] temp_hit_col;
    reg temp_collision;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            collision_detected <= 0;
            hit_row <= 0;
            hit_col <= 0;
        end else if (obj1_active) begin
            // Reset collision flags
            temp_collision = 0;
            temp_hit_row = 0;
            temp_hit_col = 0;
            
            // Check collision with all possible element positions
            // render_group will determine if the element is actually alive
            for (row = 0; row < GRID_ROWS; row = row + 1) begin
                for (col = 0; col < GRID_COLS; col = col + 1) begin
                    // Calculate element position relative to moving grid
                    element_x = group_x + (col * SPACING);
                    element_y = group_y + (row * SPACING);
                    
                    // Check X overlap
                    overlap_x = (obj1_x < element_x + GROUP_ELEMENT_SIZE) &&
                               (obj1_x + OBJ1_WIDTH > element_x);
                    
                    // Check Y overlap
                    overlap_y = (obj1_y < element_y + GROUP_ELEMENT_SIZE) &&
                               (obj1_y + OBJ1_HEIGHT > element_y);
                    
                    // If both X and Y overlap, we have a potential hit
                    if (overlap_x && overlap_y && !temp_collision) begin
                        temp_collision = 1;
                        temp_hit_row = row;
                        temp_hit_col = col;
                    end
                end
            end
            
            // Output the collision result
            collision_detected <= temp_collision;
            hit_row <= temp_hit_row;
            hit_col <= temp_hit_col;
            
        end else begin
            collision_detected <= 0;
        end
    end

endmodule
