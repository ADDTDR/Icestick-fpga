module top (
    input wire CLK_I,
    output wire HCMS_DATA_O,
    output wire HCMS_CLOCK_O,
    output wire HCMS_REGSEL_O,
    output wire HCMS_NCS_O,
    output wire HCMS_RESET_O
);

reg [20:0] TICK_COUNT_R = 21'd0;
reg [13:0] VALUE_R = 14'd0;

localparam TICK_MAX = 21'd1200000 - 1; // 12 MHz / 1_200_000 = 10 Hz increment.

always @(posedge CLK_I) begin
    if (TICK_COUNT_R == TICK_MAX) begin
        TICK_COUNT_R <= 21'd0;
        if (VALUE_R == 14'd9999)
            VALUE_R <= 14'd0;
        else
            VALUE_R <= VALUE_R + 1'b1;
    end else begin
        TICK_COUNT_R <= TICK_COUNT_R + 1'b1;
    end
end

hcms29xx_integer_display u_display (
    .i_clk(CLK_I),
    .i_value(VALUE_R),
    .i_pwm(4'b1101),
    .i_current(2'b00),
    .i_sleep(1'b1),
    .o_hcms_data(HCMS_DATA_O),
    .o_hcms_clock(HCMS_CLOCK_O),
    .o_hcms_regsel(HCMS_REGSEL_O),
    .o_hcms_ncs(HCMS_NCS_O),
    .o_hcms_reset(HCMS_RESET_O)
);

endmodule
