// Reusable HCMS-29xx display driver for zero-padded integer output (0000..9999).
module hcms29xx_integer_display (
    input i_clk,
    input [13:0] i_value,
    input [3:0] i_pwm,
    input [1:0] i_current,
    input i_sleep,
    output o_hcms_data,
    output o_hcms_clock,
    output o_hcms_regsel,
    output o_hcms_ncs,
    output o_hcms_reset
);

localparam HCMS_DATA_REGISTER = 1'b0;
localparam HCMS_COMMAND_REGISTER = 1'b1;
localparam HCMS_COLS = 5;
localparam HCMS_DIGITS = 4;
localparam HCMS_FRAME_BYTES = HCMS_COLS * HCMS_DIGITS;

localparam CFG_WORD_0_SEL = 1'b0;
localparam CFG_WORD_1_SEL = 1'b1;

wire [13:0] w_value_clamped = (i_value > 14'd9999) ? 14'd9999 : i_value;

reg [3:0] r_thousands = 4'd0;
reg [3:0] r_hundreds = 4'd0;
reg [3:0] r_tens = 4'd0;
reg [3:0] r_ones = 4'd0;
reg [13:0] r_value_shadow = 14'd0;
reg [29:0] r_bcd_shift = 30'd0;
reg [3:0] r_bcd_step = 4'd0;
reg r_bcd_busy = 1'b0;
wire [29:0] w_bcd_adjusted = bcd_add3(r_bcd_shift);
wire [29:0] w_bcd_shifted = w_bcd_adjusted << 1;

reg [7:0] r_data = 8'd0;
reg r_load_data = 1'b1;
wire w_ready;
reg r_cmd = HCMS_DATA_REGISTER;
reg r_ds_reset = 1'b1;
reg r_latch_enable = 1'b0;
reg r_output_enable = 1'b1;
reg [4:0] r_col = 5'd0;
reg r_ready_d = 1'b0;

wire [7:0] w_col_data;
assign w_col_data = frame_col_data(r_col, r_thousands, r_hundreds, r_tens, r_ones);

localparam SM_BOOT = 2'd0;
localparam SM_CFG0 = 2'd1;
localparam SM_CFG1 = 2'd2;
localparam SM_RUN  = 2'd3;

reg [1:0] r_sm_state = SM_BOOT;

wire [7:0] w_control_word_0 = {CFG_WORD_0_SEL, i_sleep, i_current, i_pwm};
wire [7:0] w_control_word_1 = {CFG_WORD_1_SEL, 5'b00000, 1'b0, 1'b1};

always @(posedge i_clk)
    r_load_data <= !w_ready;

always @(posedge i_clk)
    r_ready_d <= w_ready;

always @(posedge i_clk) begin
    if (!r_bcd_busy) begin
        if (w_value_clamped != r_value_shadow) begin
            r_value_shadow <= w_value_clamped;
            r_bcd_shift <= {16'd0, w_value_clamped};
            r_bcd_step <= 4'd0;
            r_bcd_busy <= 1'b1;
        end
    end else begin
        r_bcd_shift <= w_bcd_shifted;

        if (r_bcd_step == 4'd13) begin
            r_bcd_busy <= 1'b0;
            r_thousands <= w_bcd_shifted[29:26];
            r_hundreds <= w_bcd_shifted[25:22];
            r_tens <= w_bcd_shifted[21:18];
            r_ones <= w_bcd_shifted[17:14];
        end else begin
            r_bcd_step <= r_bcd_step + 1'b1;
        end
    end
end

function [29:0] bcd_add3;
    input [29:0] in;
    reg [29:0] t;
    begin
        t = in;
        if (t[29:26] >= 4'd5)
            t[29:26] = t[29:26] + 4'd3;
        if (t[25:22] >= 4'd5)
            t[25:22] = t[25:22] + 4'd3;
        if (t[21:18] >= 4'd5)
            t[21:18] = t[21:18] + 4'd3;
        if (t[17:14] >= 4'd5)
            t[17:14] = t[17:14] + 4'd3;
        bcd_add3 = t;
    end
endfunction

hcms_serial_byte u_serial (
    .i_clk(i_clk),
    .i_data(r_data),
    .i_data_load(r_load_data),
    .i_cmd(r_cmd),
    .i_hcms_reset(r_ds_reset),
    .i_latch_enable(r_latch_enable),
    .i_output_enable(r_output_enable),
    .o_ready(w_ready),
    .o_serial_data(o_hcms_data),
    .o_register_sel(o_hcms_regsel),
    .o_serial_clk(o_hcms_clock),
    .o_nce(o_hcms_ncs),
    .o_nreset(o_hcms_reset)
);

always @(posedge i_clk) begin
    // Advance one transaction per rising edge of ready, but stay in i_clk domain.
    if (w_ready && !r_ready_d) begin
        case (r_sm_state)
            SM_BOOT: begin
                r_ds_reset <= 1'b1;
                r_sm_state <= SM_CFG0;
            end

            SM_CFG0: begin
                r_ds_reset <= 1'b0;
                r_cmd <= HCMS_COMMAND_REGISTER;
                r_data <= w_control_word_0;
                r_latch_enable <= 1'b1;
                r_output_enable <= 1'b1;
                r_sm_state <= SM_CFG1;
            end

            SM_CFG1: begin
                r_ds_reset <= 1'b0;
                r_cmd <= HCMS_COMMAND_REGISTER;
                r_data <= w_control_word_1;
                r_latch_enable <= 1'b1;
                r_output_enable <= 1'b1;
                r_col <= 5'd0;
                r_sm_state <= SM_RUN;
            end

            SM_RUN: begin
                r_cmd <= HCMS_DATA_REGISTER;

                if (r_col == HCMS_FRAME_BYTES[4:0]) begin
                    // Pulse latch with CE inactive after all 20 bytes are shifted.
                    r_data <= 8'd0;
                    r_col <= 5'd0;
                    r_latch_enable <= 1'b1;
                    r_output_enable <= 1'b0;
                end else begin
                    r_data <= w_col_data;
                    r_col <= r_col + 1'b1;
                    r_latch_enable <= 1'b0;
                    r_output_enable <= 1'b1;
                end
            end

            default: begin
                r_sm_state <= SM_BOOT;
            end
        endcase
    end
end

function [7:0] frame_col_data;
    input [4:0] idx;
    input [3:0] d3;
    input [3:0] d2;
    input [3:0] d1;
    input [3:0] d0;
    begin
        case (idx)
            5'd0:  frame_col_data = digit_col(d3, 3'd0);
            5'd1:  frame_col_data = digit_col(d3, 3'd1);
            5'd2:  frame_col_data = digit_col(d3, 3'd2);
            5'd3:  frame_col_data = digit_col(d3, 3'd3);
            5'd4:  frame_col_data = digit_col(d3, 3'd4);
            5'd5:  frame_col_data = digit_col(d2, 3'd0);
            5'd6:  frame_col_data = digit_col(d2, 3'd1);
            5'd7:  frame_col_data = digit_col(d2, 3'd2);
            5'd8:  frame_col_data = digit_col(d2, 3'd3);
            5'd9:  frame_col_data = digit_col(d2, 3'd4);
            5'd10: frame_col_data = digit_col(d1, 3'd0);
            5'd11: frame_col_data = digit_col(d1, 3'd1);
            5'd12: frame_col_data = digit_col(d1, 3'd2);
            5'd13: frame_col_data = digit_col(d1, 3'd3);
            5'd14: frame_col_data = digit_col(d1, 3'd4);
            5'd15: frame_col_data = digit_col(d0, 3'd0);
            5'd16: frame_col_data = digit_col(d0, 3'd1);
            5'd17: frame_col_data = digit_col(d0, 3'd2);
            5'd18: frame_col_data = digit_col(d0, 3'd3);
            5'd19: frame_col_data = digit_col(d0, 3'd4);
            default: frame_col_data = 8'h00;
        endcase
    end
endfunction

function [7:0] digit_col;
    input [3:0] digit;
    input [2:0] col;
    begin
        case (digit)
            4'd0: begin
                case (col)
                    3'd0: digit_col = 8'h3E;
                    3'd1: digit_col = 8'h51;
                    3'd2: digit_col = 8'h49;
                    3'd3: digit_col = 8'h45;
                    default: digit_col = 8'h3E;
                endcase
            end
            4'd1: begin
                case (col)
                    3'd0: digit_col = 8'h00;
                    3'd1: digit_col = 8'h42;
                    3'd2: digit_col = 8'h7F;
                    3'd3: digit_col = 8'h40;
                    default: digit_col = 8'h00;
                endcase
            end
            4'd2: begin
                case (col)
                    3'd0: digit_col = 8'h42;
                    3'd1: digit_col = 8'h61;
                    3'd2: digit_col = 8'h51;
                    3'd3: digit_col = 8'h49;
                    default: digit_col = 8'h46;
                endcase
            end
            4'd3: begin
                case (col)
                    3'd0: digit_col = 8'h21;
                    3'd1: digit_col = 8'h41;
                    3'd2: digit_col = 8'h45;
                    3'd3: digit_col = 8'h4B;
                    default: digit_col = 8'h31;
                endcase
            end
            4'd4: begin
                case (col)
                    3'd0: digit_col = 8'h18;
                    3'd1: digit_col = 8'h14;
                    3'd2: digit_col = 8'h12;
                    3'd3: digit_col = 8'h7F;
                    default: digit_col = 8'h10;
                endcase
            end
            4'd5: begin
                case (col)
                    3'd0: digit_col = 8'h27;
                    3'd1: digit_col = 8'h45;
                    3'd2: digit_col = 8'h45;
                    3'd3: digit_col = 8'h45;
                    default: digit_col = 8'h39;
                endcase
            end
            4'd6: begin
                case (col)
                    3'd0: digit_col = 8'h3C;
                    3'd1: digit_col = 8'h4A;
                    3'd2: digit_col = 8'h49;
                    3'd3: digit_col = 8'h49;
                    default: digit_col = 8'h30;
                endcase
            end
            4'd7: begin
                case (col)
                    3'd0: digit_col = 8'h01;
                    3'd1: digit_col = 8'h71;
                    3'd2: digit_col = 8'h09;
                    3'd3: digit_col = 8'h05;
                    default: digit_col = 8'h03;
                endcase
            end
            4'd8: begin
                case (col)
                    3'd0: digit_col = 8'h36;
                    3'd1: digit_col = 8'h49;
                    3'd2: digit_col = 8'h49;
                    3'd3: digit_col = 8'h49;
                    default: digit_col = 8'h36;
                endcase
            end
            4'd9: begin
                case (col)
                    3'd0: digit_col = 8'h06;
                    3'd1: digit_col = 8'h49;
                    3'd2: digit_col = 8'h49;
                    3'd3: digit_col = 8'h29;
                    default: digit_col = 8'h1E;
                endcase
            end
            default: begin
                digit_col = 8'h00;
            end
        endcase
    end
endfunction

endmodule
