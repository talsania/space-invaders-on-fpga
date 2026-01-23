`timescale 1ns/1ps

module uart_rx #(
    parameter DATA_BITS = 8
)(
    input  wire                clk,
    input  wire                rst_n,
    input  wire                baud_tick,   // 16x oversampling tick
    input  wire                rx,          // UART RX pin
    
    output reg [DATA_BITS-1:0] data,
    output reg                 data_valid,
    output reg                 frame_error
);

    // FSM states
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;
    
    reg [1:0] state;
    reg [3:0] tick_count;      // Count 16 ticks per bit
    reg [2:0] bit_count;       // Count data bits
    reg [DATA_BITS-1:0] shift_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            data_valid <= 0;
            frame_error <= 0;
            tick_count <= 0;
            bit_count <= 0;
        end else begin
            data_valid <= 0;  // Default: pulse for one cycle
            
            if (baud_tick) begin
                case (state)
                    IDLE: begin
                        if (rx == 0) begin  // Start bit detected
                            state <= START;
                            tick_count <= 0;
                        end
                    end
                    
                    START: begin
                        if (tick_count == 7) begin  // Sample at middle of bit
                            if (rx == 0) begin      // Valid start bit
                                state <= DATA;
                                tick_count <= 0;
                                bit_count <= 0;
                            end else begin
                                state <= IDLE;      // False start
                            end
                        end else begin
                            tick_count <= tick_count + 1;
                        end
                    end
                    
                    DATA: begin
                        if (tick_count == 15) begin
                            // Sample data bit
                            shift_reg <= {rx, shift_reg[DATA_BITS-1:1]};
                            tick_count <= 0;
                            
                            if (bit_count == DATA_BITS - 1) begin
                                state <= STOP;
                            end else begin
                                bit_count <= bit_count + 1;
                            end
                        end else begin
                            tick_count <= tick_count + 1;
                        end
                    end
                    
                    STOP: begin
                        if (tick_count == 15) begin
                            if (rx == 1) begin  // Valid stop bit
                                data <= shift_reg;
                                data_valid <= 1;
                                frame_error <= 0;
                            end else begin
                                frame_error <= 1;
                            end
                            state <= IDLE;
                            tick_count <= 0;
                        end else begin
                            tick_count <= tick_count + 1;
                        end
                    end
                endcase
            end
        end
    end
endmodule