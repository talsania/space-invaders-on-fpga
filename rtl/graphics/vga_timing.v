module vga_timing (
    input  wire       clk,        // 100MHz
    input  wire       rst_n,
    
    output reg  [9:0] pixel_x,
    output reg  [9:0] pixel_y,
    output reg        hsync,
    output reg        vsync,
    output reg        video_on
);

    // VGA 640x480 @ 60Hz timing
    localparam H_DISPLAY = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = 800;
    
    localparam V_DISPLAY = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = 525;
    
    // 25MHz pixel clock (100MHz / 4)
    reg [1:0] clk_div;
    wire pix_tick = (clk_div == 2'b00);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_div <= 0;
        else
            clk_div <= clk_div + 1;
    end
    
    // Horizontal counter
    reg [9:0] h_count;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            h_count <= 0;
        else if (pix_tick) begin
            if (h_count == H_TOTAL - 1)
                h_count <= 0;
            else
                h_count <= h_count + 1;
        end
    end
    
    // Vertical counter
    reg [9:0] v_count;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            v_count <= 0;
        else if (pix_tick && h_count == H_TOTAL - 1) begin
            if (v_count == V_TOTAL - 1)
                v_count <= 0;
            else
                v_count <= v_count + 1;
        end
    end
    
    // Sync signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hsync <= 1;
            vsync <= 1;
        end else if (pix_tick) begin
            hsync <= (h_count < (H_DISPLAY + H_FRONT)) || 
                     (h_count >= (H_DISPLAY + H_FRONT + H_SYNC));
            vsync <= (v_count < (V_DISPLAY + V_FRONT)) || 
                     (v_count >= (V_DISPLAY + V_FRONT + V_SYNC));
        end
    end
    
    // Video on and pixel coordinates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            video_on <= 0;
            pixel_x <= 0;
            pixel_y <= 0;
        end else if (pix_tick) begin
            video_on <= (h_count < H_DISPLAY) && (v_count < V_DISPLAY);
            pixel_x <= h_count;
            pixel_y <= v_count;
        end
    end

endmodule