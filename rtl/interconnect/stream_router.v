// ============================================================================
// Project:     Real-Time Streaming Graphics System
// Module:      stream_router
// Description: Routes AXI-Stream packets to destinations based on type field
// 
// Author:      Krishang Krishang Talsania
// Created:     2025-01-05
// Revision:    0.2 - 2025-01-08 - Added port 3 for scheduler
//
// Revisions:
//   0.0 - 2025-01-05 - Initial 3-port router
//   0.1 - 2025-01-06 - Verified backpressure handling
//   0.2 - 2025-01-08 - Extended to 4 ports for timer integration
// ============================================================================

module stream_router (
    input  wire        clk,
    input  wire        rst_n,
    
    // ===== Input Stream =====
    input  wire [63:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    input  wire        s_axis_tlast,
    output reg         s_axis_tready,
    
    // ===== Output Port 0 (Player - Type 0x01) =====
    output reg  [63:0] m_axis_port0_tdata,
    output reg         m_axis_port0_tvalid,
    output reg         m_axis_port0_tlast,
    input  wire        m_axis_port0_tready,
    
    // ===== Output Port 1 (Bullet - Type 0x02) =====
    output reg  [63:0] m_axis_port1_tdata,
    output reg         m_axis_port1_tvalid,
    output reg         m_axis_port1_tlast,
    input  wire        m_axis_port1_tready,
    
    // ===== Output Port 2 (Reserved) =====
    output reg  [63:0] m_axis_port2_tdata,
    output reg         m_axis_port2_tvalid,
    output reg         m_axis_port2_tlast,
    input  wire        m_axis_port2_tready,
    
    // ===== Output Port 3 (Enemy - Type 0x03) - NEW! =====
    output reg  [63:0] m_axis_port3_tdata,
    output reg         m_axis_port3_tvalid,
    output reg         m_axis_port3_tlast,
    input  wire        m_axis_port3_tready
);

    // Extract packet type from first byte
    wire [7:0] packet_type = s_axis_tdata[7:0];
    
    // ========== Routing Logic ==========
    always @(*) begin
        // Default: all outputs invalid
        m_axis_port0_tvalid = 0;
        m_axis_port0_tdata = s_axis_tdata;
        m_axis_port0_tlast = s_axis_tlast;
        
        m_axis_port1_tvalid = 0;
        m_axis_port1_tdata = s_axis_tdata;
        m_axis_port1_tlast = s_axis_tlast;
        
        m_axis_port2_tvalid = 0;
        m_axis_port2_tdata = s_axis_tdata;
        m_axis_port2_tlast = s_axis_tlast;
        
        m_axis_port3_tvalid = 0;
        m_axis_port3_tdata = s_axis_tdata;
        m_axis_port3_tlast = s_axis_tlast;
        
        // Route based on packet type
        case (packet_type)
            8'h01: begin
                // Player movement
                m_axis_port0_tvalid = s_axis_tvalid;
            end
            
            8'h02: begin
                // Bullet control (unused in current design)
                m_axis_port1_tvalid = s_axis_tvalid;
            end
            
            8'h03: begin
                // Enemy movement - NEW!
                m_axis_port3_tvalid = s_axis_tvalid;
            end
            
            default: begin
                // Unknown packet type - drop it
            end
        endcase
    end
    
    // ========== Backpressure Logic ==========
    always @(*) begin
        case (packet_type)
            8'h01: s_axis_tready = m_axis_port0_tready;
            8'h02: s_axis_tready = m_axis_port1_tready;
            8'h03: s_axis_tready = m_axis_port3_tready;
            default: s_axis_tready = 1'b1;  // Always ready for unknown types
        endcase
    end

endmodule