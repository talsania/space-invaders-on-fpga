// ============================================================================
// Project:     Real-Time Streaming Graphics System
// Module:      stream_adapter
// Description: Converts serial byte stream to AXI-Stream packets
// 
// Author:      Krishang Krishang Talsania
// Created:     2025-01-05
// Revision:    0.3 - 2025-01-06 - Buffer clearing fix
//
// Revisions:
//   0.0 - 2025-01-05 - Initial creation
//   0.1 - 2025-01-05 - Added byte accumulation logic
//   0.2 - 2025-01-06 - Fixed byte ordering (MSB/LSB swap)
//   0.3 - 2025-01-06 - Added buffer clear on handshake
// ============================================================================

`timescale 1ns/1ps

module stream_adapter #(
    parameter PACKET_SIZE = 8,
    parameter DATA_WIDTH = 64
)(
    input  wire                  clk,
    input  wire                  rst_n,
    
    input  wire [7:0]            uart_data,
    input  wire                  uart_valid,
    
    output reg [DATA_WIDTH-1:0]  m_axis_tdata,
    output reg                   m_axis_tvalid,
    output reg                   m_axis_tlast,
    input  wire                  m_axis_tready
);

    reg [2:0] byte_count;
    reg [DATA_WIDTH-1:0] packet_buffer;
    reg [7:0] first_byte;  // Store first byte for debug print
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_count <= 0;
            packet_buffer <= 0;
            m_axis_tvalid <= 0;
            m_axis_tlast <= 0;
            first_byte <= 0;
        end else begin
            // Accumulate bytes from UART
            if (uart_valid && !m_axis_tvalid) begin
                // Shift right, insert byte at MSB
                packet_buffer <= {uart_data, packet_buffer[DATA_WIDTH-1:8]};
                
                // Store first byte (packet type)
                if (byte_count == 0) begin
                    first_byte <= uart_data;
                end
                
                byte_count <= byte_count + 1;
                
                // Debug print
                $display("[ADAPTER] Byte %0d: 0x%02h -> buffer=0x%016h", 
                         byte_count, uart_data, {uart_data, packet_buffer[DATA_WIDTH-1:8]});
                
                // When full packet assembled
                if (byte_count == PACKET_SIZE - 1) begin
                    m_axis_tdata <= {uart_data, packet_buffer[DATA_WIDTH-1:8]};
                    m_axis_tvalid <= 1;
                    m_axis_tlast <= 1;
                    byte_count <= 0;
                    
                    // Show correct packet type (first byte we received)
                    $display("[ADAPTER] ✓ Packet complete: 0x%016h (type=0x%02h)", 
                             {uart_data, packet_buffer[DATA_WIDTH-1:8]},
                             first_byte);  // Use stored first byte
                end
            end
            
            // Clear valid when downstream accepts packet
            if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 0;
                m_axis_tlast <= 0;
                packet_buffer <= 0;  // Clear buffer for next packet
            end
        end
    end
endmodule
