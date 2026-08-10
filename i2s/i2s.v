
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
    input  wire signed [15:0] sample_l,
    input  wire signed [15:0] sample_r,
    output reg  sample_req = 0,
    output reg  bclk = 0,
    output reg  lrclk = 0,
    output reg  sdata = 0
);
    reg [3:0] clkdiv = 0;
    reg [5:0] slot = 0;
    reg signed [15:0] sample_l_hold = 0;
    reg signed [15:0] sample_r_hold = 0;

    always @(posedge clk) begin
        sample_req <= 1'b0;
        clkdiv <= clkdiv + 1'b1;

        // 48 MHz / (2 * 8) = 3.0 MHz BCLK, LRCLK = 3.0 MHz / 64 = 46.875 kHz.
        if (clkdiv == 4'd7) begin
            clkdiv <= 0;
            bclk <= ~bclk;

            // Left-Justified framing: channel MSB aligns with LRCLK edge.
            // Update SDATA on BCLK falling edge so the DAC samples on rising edge.
            if (bclk) begin
                if (slot == 0) begin
                    // Drive left sample MSB now, then hold it for the remaining bits.
                    sample_l_hold <= sample_l;
                    sample_r_hold <= sample_r;
                    sdata <= sample_l[15];
                end else if (slot >= 1 && slot <= 15) begin
                    sdata <= sample_l_hold[15 - slot];
                end else if (slot == 32) begin
                    sdata <= sample_r_hold[15];
                end else if (slot >= 33 && slot <= 47) begin
                    sdata <= sample_r_hold[47 - slot];
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

module pll_48m (
    input  wire clk_12m,
    output wire clk_48m,
    output wire pll_lock
);
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .DIVR(4'b0000),
        .DIVF(7'b0111111),
        .DIVQ(3'b100),
        .FILTER_RANGE(3'b001)
    ) pll_i (
        .REFERENCECLK(clk_12m),
        .PLLOUTCORE(clk_48m),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .LOCK(pll_lock)
    );
endmodule

module spdif_rx (
    input  wire clk,
    input  wire spdif_in,
    input  wire [1:0] force_mode,
    output reg  signed [15:0] sample_l = 0,
    output reg  signed [15:0] sample_r = 0,
    output reg  sample_strobe = 0,
    output reg  active = 0,
    output reg  locked = 0
);
    function [15:0] bitrev16;
        input [15:0] x;
        integer i;
        begin
            for (i = 0; i < 16; i = i + 1)
                bitrev16[i] = x[15 - i];
        end
    endfunction

    reg [2:0] spdif_sync = 3'b000;
    reg spdif_f = 1'b0;
    reg spdif_ff = 1'b0;
    reg [5:0] edge_ticks = 0;
    reg [5:0] quiet_ticks = 0;

    reg pending_short = 0;
    reg [5:0] bit_count = 0;
    reg [27:0] subframe_bits = 0;
    reg channel_sel = 0;

    reg [5:0] good_subframes = 0;
    reg [15:0] left_hold = 0;

    // Timing thresholds tuned for 48 MHz clock and ~2.8..3.1 MHz S/PDIF bit rate.
    localparam [5:0] SHORT_MAX = 6'd11;
    localparam [5:0] LONG_MAX  = 6'd20;
    localparam [5:0] SYNC_MIN  = 6'd21;
    localparam [5:0] IDLE_MAX  = 6'd55;

    wire spdif_maj = (spdif_sync[2] & spdif_sync[1]) |
                     (spdif_sync[2] & spdif_sync[0]) |
                     (spdif_sync[1] & spdif_sync[0]);

    wire [15:0] w0 = subframe_bits[23:8];
    wire [15:0] w1 = bitrev16(subframe_bits[23:8]);
    wire [15:0] w2 = subframe_bits[19:4];
    wire [15:0] w3 = bitrev16(subframe_bits[19:4]);

    wire [15:0] w_sel = (force_mode == 2'd0) ? w0 :
                        (force_mode == 2'd1) ? w1 :
                        (force_mode == 2'd2) ? w2 : w3;

    always @(posedge clk) begin
        sample_strobe <= 1'b0;
        spdif_sync <= {spdif_sync[1:0], spdif_in};
        spdif_ff <= spdif_f;
        spdif_f <= spdif_maj;

        if (edge_ticks != 6'h3f)
            edge_ticks <= edge_ticks + 1'b1;
        if (quiet_ticks != 6'h3f)
            quiet_ticks <= quiet_ticks + 1'b1;

        active <= (quiet_ticks < IDLE_MAX);

        // Drop lock when input stops transitioning.
        if (quiet_ticks >= IDLE_MAX) begin
            locked <= 1'b0;
            pending_short <= 1'b0;
            bit_count <= 0;
            good_subframes <= 0;
            channel_sel <= 1'b0;
        end

        // Use filtered edges, not raw pin transitions.
        if (spdif_f ^ spdif_ff) begin
            quiet_ticks <= 0;

            if (edge_ticks >= SYNC_MIN) begin
                // Preamble/sync violation: start a fresh 28-bit subframe payload.
                if (bit_count >= 6'd24) begin
                    if (!channel_sel) begin
                        left_hold <= w_sel;
                    end else begin
                        sample_l <= left_hold;
                        sample_r <= w_sel;

                        sample_strobe <= 1'b1;
                    end

                    channel_sel <= ~channel_sel;
                    if (good_subframes != 6'h3f)
                        good_subframes <= good_subframes + 1'b1;
                end else begin
                    good_subframes <= 0;
                    channel_sel <= 1'b0;
                end

                if (good_subframes >= 6'd4)
                    locked <= 1'b1;

                bit_count <= 0;
                pending_short <= 1'b0;
            end else begin
                if (edge_ticks <= SHORT_MAX) begin
                    if (!pending_short) begin
                        pending_short <= 1'b1;
                    end else begin
                        pending_short <= 1'b0;
                        if (bit_count < 6'd28) begin
                            subframe_bits[bit_count] <= 1'b1;
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end else if (edge_ticks <= LONG_MAX) begin
                    if (pending_short) begin
                        // Phase slip: resync at next preamble.
                        pending_short <= 1'b0;
                        bit_count <= 0;
                        good_subframes <= 0;
                        locked <= 1'b0;
                    end else begin
                        if (bit_count < 6'd28) begin
                            subframe_bits[bit_count] <= 1'b0;
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end else begin
                    // Ambiguous timing: wait for next preamble instead of hard-dropping lock.
                    pending_short <= 1'b0;
                end
            end

            edge_ticks <= 0;
        end
    end
endmodule

module top (
    input  wire i_clk,
    input  wire SPDIF_IN,
    output wire MCLK,
    output wire LRCLK,
    output wire SDATA,
    output wire BLCK,
    output wire SPDIF_DBG
);
    wire clk_sys;
    wire pll_lock;

    reg [23:0] rx_watchdog = 24'hffffff;
    reg [21:0] dbg_hold = 0;

    wire signed [15:0] sample_l;
    wire signed [15:0] sample_r;
    wire sample_strobe;
    wire spdif_active;
    wire spdif_locked;
    wire [1:0] force_mode;

    reg [9:0] sample_addr = 0;
    reg signed [15:0] sample_fallback = 0;
    wire signed [15:0] rom_sample;

    wire sample_req;

    // Deterministic mode sweep by rebuilds: 0,1,2,3
    assign force_mode = 2'd0;

    pll_48m pll (
        .clk_12m(i_clk),
        .clk_48m(clk_sys),
        .pll_lock(pll_lock)
    );

    tone_rom #(
        .INIT_FILE("mem_init.txt")
    ) rom (
        .clk(clk_sys),
        .addr(sample_addr),
        .data(rom_sample)
    );

    always @(posedge clk_sys) begin
        if (sample_strobe)
            rx_watchdog <= 24'd0;
        else if (rx_watchdog != 24'hffffff)
            rx_watchdog <= rx_watchdog + 1'b1;

        // Hold debug high briefly after each valid frame pair.
        if (sample_strobe)
            dbg_hold <= 22'd2000000;
        else if (dbg_hold != 0)
            dbg_hold <= dbg_hold - 1'b1;

        if (sample_req) begin
            sample_fallback <= rom_sample;
            sample_addr <= sample_addr + 1'b1;
        end
    end

    spdif_rx rx (
        .clk(clk_sys),
        .spdif_in(SPDIF_IN),
        .force_mode(force_mode),
        .sample_l(sample_l),
        .sample_r(sample_r),
        .sample_strobe(sample_strobe),
        .active(spdif_active),
        .locked(spdif_locked)
    );

    // Keep DAC master clock at 12 MHz (known-good on this board).
    assign MCLK = i_clk;

    i2s_tx i2s (
        .clk(clk_sys),
        .sample_l((pll_lock && spdif_active && (rx_watchdog < 24'd4800000)) ? sample_r : sample_fallback),
        .sample_r((pll_lock && spdif_active && (rx_watchdog < 24'd4800000)) ? sample_r : sample_fallback),
        .sample_req(sample_req),
        .bclk(BLCK),
        .lrclk(LRCLK),
        .sdata(SDATA)
    );

    // Debug is meaningful decode status: lock or recent valid frame strobes.
    assign SPDIF_DBG = spdif_locked | (dbg_hold != 0);
endmodule

