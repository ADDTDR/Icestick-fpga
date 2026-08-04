
module tone_rom #(
    parameter INIT_FILE = "mem_init.txt"
)(
    input wire clk,
    input wire [9:0] addr,
    output reg signed [15:0] data
);
    reg signed [15:0] mem [0:1023];

    always @(posedge clk) begin
        data <= mem[addr];
    end

    initial if (INIT_FILE) begin
        $readmemh(INIT_FILE, mem);
    end
endmodule

module i2s_tx (
    input  wire clk,
    input  wire signed [15:0] sample,
    output reg  sample_req = 0,
    output reg  bclk = 0,
    output reg  lrclk = 0,
    output reg  sdata = 0
);
    reg [1:0] clkdiv = 0;
    reg [5:0] slot = 0;
    reg signed [15:0] sample_hold = 0;

    always @(posedge clk) begin
        sample_req <= 1'b0;
        clkdiv <= clkdiv + 1'b1;

        // 12 MHz / (2 * 2) = 3.0 MHz BCLK, LRCLK = 3.0 MHz / 64 = 46.875 kHz.
        if (clkdiv == 2'd1) begin
            clkdiv <= 0;
            bclk <= ~bclk;

            // Left-Justified framing: channel MSB aligns with LRCLK edge.
            // Update SDATA on BCLK falling edge so the DAC samples on rising edge.
            if (bclk) begin
                if (slot == 0) begin
                    // Important: drive current sample MSB now, then latch it for following bits.
                    sample_hold <= sample;
                    sdata <= sample[15];
                end else if (slot >= 1 && slot <= 15) begin
                    sdata <= sample_hold[15 - slot];
                end else if (slot == 32) begin
                    sdata <= sample_hold[15];
                end else if (slot >= 33 && slot <= 47) begin
                    sdata <= sample_hold[47 - slot];
                end else begin
                    sdata <= 1'b0;
                end

                if (slot == 6'd31)
                    lrclk <= 1'b1;
                else if (slot == 6'd63)
                    lrclk <= 1'b0;

                if (slot == 6'd63) begin
                    slot <= 0;
                    sample_req <= 1'b1;
                end else begin
                    slot <= slot + 1'b1;
                end
            end
        end
    end
endmodule

module top (
    input  wire i_clk,
    output wire MCLK,
    output wire LRCLK,
    output wire SDATA,
    output wire BLCK
);
    reg [9:0] sample_addr = 0;
    reg signed [15:0] sample_reg = 0;
    wire signed [15:0] rom_sample;
    wire sample_req;

    tone_rom #(
        .INIT_FILE("mem_init.txt")
    ) rom (
        .clk(i_clk),
        .addr(sample_addr),
        .data(rom_sample)
    );

    always @(posedge i_clk) begin
        if (sample_req) begin
            sample_reg <= rom_sample;
            sample_addr <= sample_addr + 1'b1;
        end
    end

    // Digilent Pmod I2S can use this as a master clock source.
    assign MCLK = i_clk;

    i2s_tx i2s (
        .clk(i_clk),
        .sample(sample_reg),
        .sample_req(sample_req),
        .bclk(BLCK),
        .lrclk(LRCLK),
        .sdata(SDATA)
    );
endmodule

