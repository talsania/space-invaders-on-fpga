// ============================================================================
// Project:     Real-Time Streaming Graphics System
// Module:      stream_arbiter
// Description: Priority-based AXI-Stream multiplexer (2:1)
// 
// Author:      Krishang Krishang Talsania
// Created:     2025-01-08
// Revision:    0.1 - 2025-01-08 - Sequential arbitration logic
//
// Revisions:
//   0.0 - 2025-01-08 - Combinational arbiter (failed timing)
//   0.1 - 2025-01-08 - Registered outputs for timing closure
// ============================================================================

module stream_arbiter (
    input  wire        clk,
    input  wire        rst_n,
    
    // ===== Input Port 0 (Higher Priority - UART/Player Input) =====
    input  wire [63:0] s_axis0_tdata,
    input  wire        s_axis0_tvalid,
    input  wire        s_axis0_tlast,
    output wire        s_axis0_tready,
    
    // ===== Input Port 1 (Lower Priority - Timer/Enemy Movement) =====
    input  wire [63:0] s_axis1_tdata,
    input  wire        s_axis1_tvalid,
    input  wire        s_axis1_tlast,
    output wire        s_axis1_tready,
    
    // ===== Merged Output =====
    output reg  [63:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    output reg         m_axis_tlast,
    input  wire        m_axis_tready
);

    // ========== Sequential Priority Arbiter ==========
    // Registered output for better synthesis and timing
    // Port 0 (UART) always takes precedence over Port 1 (Timer)
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata  <= 64'h0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end else begin
            if (s_axis0_tvalid) begin
                // UART packet has priority - forward it
                m_axis_tdata  <= s_axis0_tdata;
                m_axis_tvalid <= s_axis0_tvalid;
                m_axis_tlast  <= s_axis0_tlast;
            end else begin
                // No UART packet - forward Timer packet
                m_axis_tdata  <= s_axis1_tdata;
                m_axis_tvalid <= s_axis1_tvalid;
                m_axis_tlast  <= s_axis1_tlast;
            end
        end
    end
    
    // ========== Backpressure Routing ==========
    // Forward ready signal back to the active source
    
    // Port 0 always gets ready signal (high priority)
    assign s_axis0_tready = m_axis_tready;
    
    // Port 1 only gets ready when Port 0 is not valid (low priority)
    assign s_axis1_tready = m_axis_tready && !s_axis0_tvalid;

endmodule