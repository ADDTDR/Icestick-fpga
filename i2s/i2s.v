
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
    // iCEstick-specific timing:
    //   MCLK = 48 MHz from the PLL
    //   BCLK = MCLK / 16 = 3.0 MHz
    //   LRCLK = BCLK / 64 = 46.875 kHz
    // This is close to 48 kHz, but not exact because the PLL only supports
    // integer division from the onboard 12 MHz reference.
    localparam [3:0] BCLK_DIV_LAST = 4'd7;
    localparam [5:0] SLOT_LAST = 6'd63;
    localparam [5:0] LEFT_SLOT_LAST = 6'd31;
    localparam [5:0] RIGHT_SLOT_FIRST = 6'd32;

    reg [3:0] clkdiv = 0;
    reg [5:0] slot = 0;
    reg signed [15:0] sample_l_hold = 0;
    reg signed [15:0] sample_r_hold = 0;

    always @(posedge clk) begin
        sample_req <= 1'b0;
        clkdiv <= clkdiv + 1'b1;

        // Toggle the bit clock every 8 MCLK cycles.
        if (clkdiv == BCLK_DIV_LAST) begin
            clkdiv <= 0;
            bclk <= ~bclk;

            // Update SDATA on one BCLK phase and hold it stable on the other.
            if (bclk) begin
                if (slot == 0) begin
                    sample_l_hold <= sample_l;
                    sample_r_hold <= sample_r;
                    sdata <= sample_l[15];
                end else if (slot >= 1 && slot <= 15) begin
                    sdata <= sample_l_hold[15 - slot];
                end else if (slot == RIGHT_SLOT_FIRST) begin
                    sdata <= sample_r_hold[15];
                end else if (slot >= 33 && slot <= 47) begin
                    sdata <= sample_r_hold[47 - slot];
                end else begin
                    sdata <= 1'b0;
                end

                // Standard I2S: LRCLK changes one bit clock before the next
                // channel's MSB. Low selects left, high selects right.
                if (slot == LEFT_SLOT_LAST)
                    lrclk <= 1'b1;
                else if (slot == SLOT_LAST)
                    lrclk <= 1'b0;

                if (slot == SLOT_LAST) begin
                    slot <= 0;
                    sample_req <= 1'b1;        // Request the next stereo sample pair.
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
    output reg  signed [15:0] sample_l = 0,
    output reg  signed [15:0] sample_r = 0,
    output reg  sample_strobe = 0,
    output reg  active = 0,
    output reg  locked = 0
);

    // Synchronizer & Noise Filter Signals
    reg [2:0] spdif_sync = 3'b000;
    reg spdif_f = 1'b0;
    reg spdif_ff = 1'b0;
    
    // Time/Edge Tracking Registers
    reg [5:0] edge_ticks = 0;
    reg [5:0] quiet_ticks = 0;

    // S/PDIF Protocol State Engine
    reg pending_short = 0;
    reg [5:0] bit_count = 0;
    reg [27:0] subframe_bits = 0;
    reg channel_sel = 0;
    reg channel_valid = 0;
    reg in_preamble = 0;
    reg [1:0] preamble_step = 0;
    reg preamble_right = 0;

    reg [5:0] good_subframes = 0;

    // Timing thresholds (Tuned for 48 MHz clock with ~2.8..3.1 MHz S/PDIF)
    localparam [5:0] SHORT_MAX = 6'd11;
    localparam [5:0] LONG_MAX  = 6'd20;
    localparam [5:0] SYNC_MIN  = 6'd21;
    localparam [5:0] IDLE_MAX  = 6'd55;

    // 3-Input Majority Voter Filter for raw signal glitch reduction
    wire spdif_maj = (spdif_sync[2] & spdif_sync[1]) |
                     (spdif_sync[2] & spdif_sync[0]) |
                     (spdif_sync[1] & spdif_sync[0]);

    // OPTIMIZATION: Hardcoded to Mode 0 (Direct MSB-first subframe mapping)
    wire [15:0] w_sel = subframe_bits[23:8];

    always @(posedge clk) begin
        sample_strobe  <= 1'b0;
        spdif_sync     <= {spdif_sync[1:0], spdif_in};
        spdif_ff       <= spdif_f;
        spdif_f        <= spdif_maj;

        // Keep counting ticks until they saturate at maximum width
        if (edge_ticks != 6'h3f)
            edge_ticks <= edge_ticks + 1'b1;
        if (quiet_ticks != 6'h3f)
            quiet_ticks <= quiet_ticks + 1'b1;

        active <= (quiet_ticks < IDLE_MAX);

        // Reset state and drop lock immediately if incoming transitions freeze
        if (quiet_ticks >= IDLE_MAX) begin
            locked         <= 1'b0;
            pending_short  <= 1'b0;
            bit_count      <= 0;
            good_subframes <= 0;
            channel_sel    <= 1'b0;
            channel_valid  <= 1'b0;
            in_preamble    <= 1'b0;
            preamble_step  <= 0;
        end

        // Evaluate logic solely on valid filtered S/PDIF transitions
        if (spdif_f ^ spdif_ff) begin
            quiet_ticks <= 0;

            if (in_preamble) begin
                // Preamble parsing window: B=3,1,1,3; M=3,3,1,1; W=3,2,1,2.
                // The second interval isolates W (right channel) from B/M (left channel).
                if (preamble_step == 2'd1)
                    preamble_right <= (edge_ticks > SHORT_MAX) && (edge_ticks < SYNC_MIN);

                if (preamble_step == 2'd3) begin
                    channel_sel    <= preamble_right;
                    channel_valid  <= 1'b1;
                    in_preamble    <= 1'b0;
                    preamble_step  <= 0;
                    bit_count      <= 0;
                    pending_short  <= 1'b0;
                end else begin
                    preamble_step  <= preamble_step + 1'b1;
                end
            end else if (edge_ticks >= SYNC_MIN) begin
                // A 3T sync interval identifies the start of an S/PDIF preamble.
                // Commit the compiled payload registers before parsing the next preamble header.
                if (channel_valid && (bit_count >= 6'd24)) begin
                    if (channel_sel) begin
                        sample_r      <= w_sel;
                        sample_strobe <= 1'b1;
                    end else begin
                        sample_l      <= w_sel;
                    end

                    if (good_subframes != 6'h3f)
                        good_subframes <= good_subframes + 1'b1;
                end else if (channel_valid) begin
                    good_subframes <= 0;
                    locked         <= 1'b0;
                end

                if (good_subframes >= 6'd4)
                    locked <= 1'b1;

                in_preamble   <= 1'b1;
                preamble_step <= 2'd1;
                bit_count     <= 0;
                pending_short <= 1'b0;
            end else begin
                // Decode incoming data based on measured cell periods
                if (edge_ticks <= SHORT_MAX) begin
                    if (!pending_short) begin
                        pending_short <= 1'b1; // First half of BMC logic '1' cell
                    end else begin
                        pending_short <= 1'b0; // Second half complete
                        if (bit_count < 6'd28) begin
                            subframe_bits[bit_count] <= 1'b1;
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end else if (edge_ticks <= LONG_MAX) begin
                    if (pending_short) begin
                        // Phase tracking fault detected: reset window alignment
                        pending_short  <= 1'b0;
                        bit_count      <= 0;
                        good_subframes <= 0;
                        locked         <= 1'b0;
                    end else begin
                        if (bit_count < 6'd28) begin
                            subframe_bits[bit_count] <= 1'b0;
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end else begin
                    // Ambiguous interval width: bypass data bit, wait for clean sync block
                    pending_short <= 1'b0;
                end
            end

            edge_ticks <= 0; // Reset period counter for the next edge interval
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
        .sample_l(sample_l),
        .sample_r(sample_r),
        .sample_strobe(sample_strobe),
        .active(spdif_active),
        .locked(spdif_locked)
    );

    // Keep DAC master clock at 48 MHz
    assign MCLK = clk_sys;

    i2s_tx i2s (
        .clk(clk_sys),
        .sample_l((pll_lock && spdif_active && (rx_watchdog < 24'd4800000)) ? sample_l : sample_fallback),
        .sample_r((pll_lock && spdif_active && (rx_watchdog < 24'd4800000)) ? sample_r : sample_fallback),
        .sample_req(sample_req),
        .bclk(BLCK),
        .lrclk(LRCLK),
        .sdata(SDATA)
    );

    // Debug is meaningful decode status: lock or recent valid frame strobes.
    assign SPDIF_DBG = spdif_locked | (dbg_hold != 0);
endmodule

