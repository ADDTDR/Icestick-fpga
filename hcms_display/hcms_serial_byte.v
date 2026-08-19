// Sends one byte to HCMS serial interface.
module hcms_serial_byte (
    input i_clk,
    input [7:0] i_data,
    input i_data_load,
    input i_cmd,
    input i_hcms_reset,
    input i_latch_enable,
    input i_output_enable,
    output reg o_ready,
    output reg o_serial_data,
    output o_register_sel,
    output o_serial_clk,
    output o_nce,
    output o_nreset
);

localparam ST_IDLE = 2'd0;
localparam ST_SEND = 2'd1;
localparam ST_DONE = 2'd2;

reg [1:0] r_state = ST_IDLE;
reg [2:0] r_bit_index = 3'd0;
reg [7:0] r_shift = 8'd0;
reg r_ce = 1'b0;

// initial begin
//     o_ready = 1'b0;
//     o_serial_data = 1'b0;
// end

assign o_serial_clk = (r_ce && !i_hcms_reset && i_output_enable) ? i_clk : 1'b0;
assign o_register_sel = i_cmd;
assign o_nreset = !i_hcms_reset;
assign o_nce = i_hcms_reset ? 1'b1 : (!r_ce && i_latch_enable);

always @(negedge i_clk) begin
    case (r_state)
        ST_IDLE: begin
            r_ce <= 1'b0;
            o_ready <= 1'b0;
            if (i_data_load) begin
                r_state <= ST_SEND;
                r_bit_index <= 3'd0;
                r_shift <= i_data;
            end
        end

        ST_SEND: begin
            o_serial_data <= r_shift[7];
            r_shift <= {r_shift[6:0], 1'b0};
            r_ce <= 1'b1;

            if (r_bit_index == 3'd7)
                r_state <= ST_DONE;
            else
                r_bit_index <= r_bit_index + 1'b1;
        end

        ST_DONE: begin
            r_ce <= 1'b0;
            o_ready <= 1'b1;
            if (!i_data_load) begin
                o_ready <= 1'b0;
                r_state <= ST_IDLE;
            end
        end

        default: begin
            r_state <= ST_IDLE;
        end
    endcase
end

endmodule
