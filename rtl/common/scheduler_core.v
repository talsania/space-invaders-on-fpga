// ============================================================================
// Project:     Real-Time Streaming Graphics System
// Module:      scheduler_core
// Description: Generates periodic event packets for system orchestration
// 
// Author:      Krishang Krishang Talsania
// Created:     2025-01-08
// Revision:    0.1 - 2025-01-08 - Adaptive rate scheduling added
//
// Revisions:
//   0.0 - 2025-01-08 - Basic fixed-rate timer
//   0.1 - 2025-01-08 - Variable rate based on load factor
// ============================================================================

module scheduler_core (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        system_active,
    input  wire [4:0]  active_count,  // 0-24 entities
    
    // ===== AXI-Stream Output (Event Packets) =====
    output reg  [63:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    output reg         m_axis_tlast,
    input  wire        m_axis_tready
);

    // ========== Frame Counter ==========
    // Counts clock cycles to generate timed events
    reg [25:0] frame_counter;
    
    // ========== Event Rate Calculation ==========
    // Threshold determines how many clock cycles between events
    // Lower threshold = faster event generation
    reg [25:0] event_threshold;
    
    always @(*) begin
        // Speed up as entity count decreases
        if (active_count > 18) begin
            // 19-24 entities: Slow (60 frames per event @ 60Hz = 1 second)
            event_threshold = 26'd100_000_000;  // 1 second at 100MHz
        end else if (active_count > 12) begin
            // 13-18 entities: Medium (30 frames = 0.5 seconds)
            event_threshold = 26'd50_000_000;
        end else if (active_count > 6) begin
            // 7-12 entities: Fast (15 frames = 0.25 seconds)
            event_threshold = 26'd25_000_000;
        end else begin
            // 1-6 entities: Very fast (7 frames = 0.12 seconds)
            event_threshold = 26'd12_000_000;
        end
    end
    
    // ========== Packet Generation ==========
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            frame_counter <= 0;
            m_axis_tvalid <= 0;
            m_axis_tlast <= 0;
            m_axis_tdata <= 64'h0;
        end else if (system_active) begin
            // Increment frame counter
            frame_counter <= frame_counter + 1;
            
            // Generate event packet when threshold reached
            if (frame_counter >= event_threshold && !m_axis_tvalid) begin
                // Packet type 0x03 = PERIODIC_EVENT
                m_axis_tdata <= {56'h0, 8'h03};
                m_axis_tvalid <= 1;
                m_axis_tlast <= 1;
                frame_counter <= 0;  // Reset counter
            end
            
            // Clear valid when packet is accepted
            if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 0;
                m_axis_tlast <= 0;
            end
        end else begin
            // System not active - reset everything
            frame_counter <= 0;
            m_axis_tvalid <= 0;
            m_axis_tlast <= 0;
        end
    end

endmodule
