// ============================================================================
// Project:     Real-Time Streaming Graphics System
// Module:      system_top
// Description: Top-level integration of all subsystems
// 
// Author:      Krishang Krishang Talsania
// Created:     2025-01-05
// Revision:    0.4 - 2025-01-08 - Full Phase 7 integration
//
// Revisions:
//   0.0 - 2025-01-05 - Basic UART → VGA path
//   0.1 - 2025-01-06 - Added packet routing
//   0.2 - 2025-01-07 - Integrated rendering pipeline
//   0.3 - 2025-01-08 - Added scheduler and state control
//   0.4 - 2025-01-08 - Complete system with all features
// ============================================================================

module system_top (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       uart_rx,
    
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b,
    output wire       vga_hsync,
    output wire       vga_vsync,
    
    output wire [15:0] led
);

    // ========== UART → AXI-Stream Chain ==========
    wire baud_tick;
    wire [7:0] uart_data;
    wire uart_valid;
    
    clk_divider #(
        .CLK_FREQ(100_000_000), 
        .BAUD_RATE(115200)
    ) baud_gen (
        .clk(clk), 
        .rst_n(rst_n), 
        .baud_tick(baud_tick)
    );
    
    uart_rx uart_receiver (
        .clk(clk), 
        .rst_n(rst_n), 
        .baud_tick(baud_tick),
        .rx(uart_rx), 
        .data(uart_data), 
        .data_valid(uart_valid)
    );
    
    wire [63:0] uart_axis_tdata;
    wire uart_axis_tvalid, uart_axis_tlast, uart_axis_tready;
    
    stream_adapter uart_converter (
        .clk(clk), 
        .rst_n(rst_n),
        .uart_data(uart_data), 
        .uart_valid(uart_valid),
        .m_axis_tdata(uart_axis_tdata), 
        .m_axis_tvalid(uart_axis_tvalid),
        .m_axis_tlast(uart_axis_tlast), 
        .m_axis_tready(uart_axis_tready)
    );
    
    // ========== Control Plane ==========
    wire [1:0] ctrl_state;
    wire system_active;
    wire reset_pulse;
    wire [4:0] active_count;
    wire halt_condition;
    
    // Extract start button from UART (button 9 or SELECT)
    wire start_button = uart_axis_tvalid && 
                       (uart_axis_tdata[7:0] == 8'h01) && 
                       (uart_axis_tdata[15:8] == 8'h09);
    
    system_controller state_manager (
        .clk(clk),
        .rst_n(rst_n),
        .start_button(start_button),
        .active_count(active_count),
        .halt_condition(halt_condition),
        .ctrl_state(ctrl_state),
        .system_active(system_active),
        .reset_pulse(reset_pulse)
    );
    
    // ========== Scheduler Core ==========
    wire [63:0] timer_axis_tdata;
    wire timer_axis_tvalid, timer_axis_tlast, timer_axis_tready;
    
    scheduler_core event_generator (
        .clk(clk),
        .rst_n(rst_n),
        .system_active(system_active),  // Only generate events when active
        .active_count(active_count),
        .m_axis_tdata(timer_axis_tdata),
        .m_axis_tvalid(timer_axis_tvalid),
        .m_axis_tlast(timer_axis_tlast),
        .m_axis_tready(timer_axis_tready)
    );
    
    // ========== Packet Merger ==========
    wire [63:0] merged_axis_tdata;
    wire merged_axis_tvalid, merged_axis_tlast, merged_axis_tready;
    
    stream_arbiter packet_combiner (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis0_tdata(uart_axis_tdata),
        .s_axis0_tvalid(uart_axis_tvalid),
        .s_axis0_tlast(uart_axis_tlast),
        .s_axis0_tready(uart_axis_tready),
        .s_axis1_tdata(timer_axis_tdata),
        .s_axis1_tvalid(timer_axis_tvalid),
        .s_axis1_tlast(timer_axis_tlast),
        .s_axis1_tready(timer_axis_tready),
        .m_axis_tdata(merged_axis_tdata),
        .m_axis_tvalid(merged_axis_tvalid),
        .m_axis_tlast(merged_axis_tlast),
        .m_axis_tready(merged_axis_tready)
    );
    
    // ========== Packet Router ==========
    wire [63:0] player_tdata, bullet_tdata, unused_tdata, enemy_tdata;
    wire player_tvalid, bullet_tvalid, unused_tvalid, enemy_tvalid;
    wire player_tlast, bullet_tlast, unused_tlast, enemy_tlast;
    wire player_tready, bullet_tready, unused_tready, enemy_tready;
    
    stream_router router (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tdata(merged_axis_tdata),
        .s_axis_tvalid(merged_axis_tvalid),
        .s_axis_tlast(merged_axis_tlast),
        .s_axis_tready(merged_axis_tready),
        .m_axis_port0_tdata(player_tdata),
        .m_axis_port0_tvalid(player_tvalid),
        .m_axis_port0_tlast(player_tlast),
        .m_axis_port0_tready(player_tready),
        .m_axis_port1_tdata(bullet_tdata),
        .m_axis_port1_tvalid(bullet_tvalid),
        .m_axis_port1_tlast(bullet_tlast),
        .m_axis_port1_tready(1'b1),
        .m_axis_port2_tdata(unused_tdata),
        .m_axis_port2_tvalid(unused_tvalid),
        .m_axis_port2_tlast(unused_tlast),
        .m_axis_port2_tready(1'b1),
        .m_axis_port3_tdata(enemy_tdata),
        .m_axis_port3_tvalid(enemy_tvalid),
        .m_axis_port3_tlast(enemy_tlast),
        .m_axis_port3_tready(enemy_tready)
    );
    
    // ========== VGA Timing ==========
    wire [9:0] pixel_x, pixel_y;
    wire video_on;
    
    vga_timing vga_tim (
        .clk(clk),
        .rst_n(rst_n),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .video_on(video_on)
    );
    
    // ========== Render Object 0 ==========
    wire [3:0] obj0_r, obj0_g, obj0_b;
    wire [9:0] obj0_x, obj0_y;
    wire trigger;
    
    render_object_0 object_0 (
        .clk(clk),
        .rst_n(rst_n && !reset_pulse),  // Reset on system restart
        .s_axis_tdata(player_tdata),
        .s_axis_tvalid(player_tvalid && system_active),  // Only move when active
        .s_axis_tlast(player_tlast),
        .s_axis_tready(player_tready),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_on(video_on),
        .vga_r(obj0_r),
        .vga_g(obj0_g),
        .vga_b(obj0_b),
        .obj0_x(obj0_x),
        .obj0_y(obj0_y),
        .trigger(trigger)
    );
    
    // ========== Render Object 1 ==========
    wire [3:0] obj1_r, obj1_g, obj1_b;
    wire [9:0] obj1_x, obj1_y;
    wire obj1_active;
    wire collision_detected;
    
    render_object_1 object_1 (
        .clk(clk),
        .rst_n(rst_n && !reset_pulse),  // Reset on system restart
        .trigger(trigger && system_active),    // Only trigger when active
        .spawn_x(obj0_x),
        .spawn_y(obj0_y),
        .collision_detected(collision_detected),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_on(video_on),
        .vga_r(obj1_r),
        .vga_g(obj1_g),
        .vga_b(obj1_b),
        .obj1_x(obj1_x),
        .obj1_y(obj1_y),
        .obj1_active(obj1_active)
    );
    
    // ========== Render Group ==========
    wire [3:0] group_r, group_g, group_b;
    wire [9:0] group_x, group_y;
    wire [2:0] hit_row;
    wire [3:0] hit_col;
    
    render_group element_group (
        .clk(clk),
        .rst_n(rst_n && !reset_pulse),  // Reset on system restart
        .s_axis_tdata(enemy_tdata),
        .s_axis_tvalid(enemy_tvalid && system_active),  // Only move when active
        .s_axis_tlast(enemy_tlast),
        .s_axis_tready(enemy_tready),
        .collision_detected(collision_detected),
        .hit_row(hit_row[1:0]),
        .hit_col(hit_col[2:0]),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_on(video_on),
        .vga_r(group_r),
        .vga_g(group_g),
        .vga_b(group_b),
        .group_x(group_x),
        .group_y(group_y),
        .active_count(active_count),
        .halt_condition(halt_condition)
    );
    
    // ========== Spatial Intersection ==========
    spatial_intersect collider (
        .clk(clk),
        .rst_n(rst_n),
        .obj1_x(obj1_x),
        .obj1_y(obj1_y),
        .obj1_active(obj1_active && system_active),
        .group_x(group_x),
        .group_y(group_y),
        .collision_detected(collision_detected),
        .hit_row(hit_row),
        .hit_col(hit_col)
    );
    
    // ========== Status Indicator ==========
    status_indicator status (
        .clk(clk),
        .rst_n(rst_n),
        .event_count(5'd24 - active_count),
        .ctrl_state(ctrl_state),
        .led(led)
    );
    
    // ========== VGA Mixer ==========
    reg [3:0] mixed_r, mixed_g, mixed_b;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mixed_r <= 4'h0;
            mixed_g <= 4'h0;
            mixed_b <= 4'h0;
        end else begin
            if (!video_on) begin
                mixed_r <= 4'h0;
                mixed_g <= 4'h0;
                mixed_b <= 4'h0;
            end else if (obj1_r != 4'h0 || obj1_g != 4'h0 || obj1_b != 4'h0) begin
                mixed_r <= obj1_r;
                mixed_g <= obj1_g;
                mixed_b <= obj1_b;
            end else if (obj0_r != 4'h0 || obj0_g != 4'h0 || obj0_b != 4'h0) begin
                mixed_r <= obj0_r;
                mixed_g <= obj0_g;
                mixed_b <= obj0_b;
            end else if (group_r != 4'h0 || group_g != 4'h0 || group_b != 4'h0) begin
                mixed_r <= group_r;
                mixed_g <= group_g;
                mixed_b <= group_b;
            end else begin
                mixed_r <= 4'h0;
                mixed_g <= 4'h0;
                mixed_b <= 4'h0;
            end
        end
    end
    
    assign vga_r = mixed_r;
    assign vga_g = mixed_g;
    assign vga_b = mixed_b;

endmodule