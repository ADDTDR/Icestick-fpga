module dds_sine (
    input  wire        clk,
    input  wire        sample_tick,
    output wire signed [15:0] sample
);
    reg [9:0] phase = 0;

    

    always @(posedge clk) begin
        if (sample_tick)
            phase <= phase + 1;

            if (phase == 882 )
                phase <= 0;
       

    end





    memory storage(
    .clk(clk),
    .r_addr(phase),
    .r_en(1'b1),
    .r_data(sample),
    .w_en(1'b0)

);


endmodule


module memory #(
    parameter INIT_FILE = "mem_init.txt"
)(
    input clk,
    input w_en,
    input r_en,
    input [9:0] w_addr,
    input [9:0] r_addr,
    input [15:0] w_data, 

    output reg [15:0] r_data
);

    reg [15:0]  mem [0:1023];

    always @(posedge clk) begin
        if (w_en == 1'b1) begin
            mem[w_addr] <= w_data;    
        end
        
        if (r_en == 1'b1) begin
            r_data <= mem[r_addr];
        end
    end

    initial if (INIT_FILE) begin
        $readmemh(INIT_FILE, mem);
    end
    
endmodule


module i2s_tx (
    input  wire clk,            // 12 MHz
    input  wire signed [15:0] sample,
    output reg  bclk = 0,
    output reg  lrclk = 0,
    output reg  sdata = 0
);

    reg [1:0] clkdiv = 0;
    reg [5:0] bit_cnt = 0;
    reg [31:0] shift = 0;

    always @(posedge clk) begin
        clkdiv <= clkdiv + 1;

        if (clkdiv == 2'd1) begin
            clkdiv <= 0;
            bclk <= ~bclk;

            if (!bclk) begin  // falling edge = update data
                sdata <= shift[31];
                shift <= shift << 1;
                bit_cnt <= bit_cnt + 1;

                if (bit_cnt == 0) begin
                    lrclk <= 0;              // LEFT
                    shift <= {sample, 16'd0};
                end

                if (bit_cnt == 16) begin
                    lrclk <= 1;              // RIGHT
                    shift <= {sample, 16'd0};
                end

                if (bit_cnt == 31) begin
                    bit_cnt <= 0;
                end
            end
        end
    end
endmodule






module top (
    input  wire i_clk,
    output wire LRCLK,
    output wire SDATA,
    output wire BLCK
);
    wire signed [15:0] sample;
    reg [9:0] sample_div = 0;
    wire sample_tick = (sample_div == 0);

    always @(posedge i_clk)
        sample_div <= sample_div + 1;

    dds_sine dds (
        .clk(i_clk),
        .sample_tick(sample_tick),
        .sample(sample)
    );

    i2s_tx i2s (
        .clk(i_clk),
        .sample(sample),
        .bclk(BLCK),
        .lrclk(LRCLK),
        .sdata(SDATA)
    );
endmodule

