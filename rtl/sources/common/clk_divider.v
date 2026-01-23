`timescale 1ns/1ps

module clk_divider #(
    parameter CLK_FREQ = 100_000_000,  // Input clock frequency (Hz)
    parameter BAUD_RATE = 115200        // Desired baud rate
)(
    input  wire clk,
    input  wire rst_n,
    output reg  baud_tick
);

    // Calculate divisor: CLK_FREQ / (BAUD_RATE * 16)
    // *16 because we oversample at 16x baud rate
    localparam DIVISOR = CLK_FREQ / (BAUD_RATE * 16);
    localparam COUNTER_WIDTH = $clog2(DIVISOR);
    
    reg [COUNTER_WIDTH-1:0] counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            baud_tick <= 0;
        end else begin
            if (counter == DIVISOR - 1) begin
                counter <= 0;
                baud_tick <= 1;
            end else begin
                counter <= counter + 1;
                baud_tick <= 0;
            end
        end
    end
endmodule