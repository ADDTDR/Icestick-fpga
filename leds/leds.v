//------------------------------------------------------------------
//-- Hello world example for the iCEstick board
//-- Turn on all the leds
//------------------------------------------------------------------

//----------------------------------------------------------------------
// Very small Wishbone LED PWM peripheral
//
// Address map (wb_adr_i):
//   0 -> D1 PWM value
//   1 -> D2 PWM value
//   2 -> D3 PWM value
//   3 -> D4 PWM value
//   4 -> D5 PWM value
//
// Each register is 8 bits. PWM duty cycle is value/255.
//----------------------------------------------------------------------
module wb_led_pwm_driver(
        input  wire       wb_clk_i,
        input  wire       wb_rst_i,
        input  wire       wb_cyc_i,
        input  wire       wb_stb_i,
        input  wire       wb_we_i,
        input  wire [2:0] wb_adr_i,
        input  wire [7:0] wb_dat_i,
        output reg  [7:0] wb_dat_o,
        output reg        wb_ack_o,
        output wire       D1,
        output wire       D2,
        output wire       D3,
        output wire       D4,
        output wire       D5
);

reg [7:0] pwm_d1;
reg [7:0] pwm_d2;
reg [7:0] pwm_d3;
reg [7:0] pwm_d4;
reg [7:0] pwm_d5;
reg [7:0] pwm_counter;

always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
        // Default brightness values so leds are visible without a master
        pwm_d1 <= 8'd64;
        pwm_d2 <= 8'd128;
        pwm_d3 <= 8'd192;
        pwm_d4 <= 8'd32;
        pwm_d5 <= 8'd255;
        pwm_counter <= 8'd0;
        wb_ack_o <= 1'b0;
    end else begin
        pwm_counter <= pwm_counter + 8'd1;

        // One-cycle acknowledge whenever master requests a transfer.
        wb_ack_o <= wb_cyc_i & wb_stb_i;

        if (wb_cyc_i & wb_stb_i & wb_we_i) begin
            case (wb_adr_i)
                3'd0: pwm_d1 <= wb_dat_i;
                3'd1: pwm_d2 <= wb_dat_i;
                3'd2: pwm_d3 <= wb_dat_i;
                3'd3: pwm_d4 <= wb_dat_i;
                3'd4: pwm_d5 <= wb_dat_i;
                default: ;
            endcase
        end
    end
end

always @(*) begin
    case (wb_adr_i)
        3'd0: wb_dat_o = pwm_d1;
        3'd1: wb_dat_o = pwm_d2;
        3'd2: wb_dat_o = pwm_d3;
        3'd3: wb_dat_o = pwm_d4;
        3'd4: wb_dat_o = pwm_d5;
        default: wb_dat_o = 8'd0;
    endcase
end

assign D1 = (pwm_counter < pwm_d1);
assign D2 = (pwm_counter < pwm_d2);
assign D3 = (pwm_counter < pwm_d3);
assign D4 = (pwm_counter < pwm_d4);
assign D5 = (pwm_counter < pwm_d5);

endmodule

//----------------------------------------------------------------------
// Very small Wishbone master that drives the pwm registers to produce
// staggered fade in/out effects on multiple LEDs.
//----------------------------------------------------------------------
module wb_master_fader(
    input  wire       clk,
    input  wire       rst,
    output reg        wb_cyc_o,
    output reg        wb_stb_o,
    output reg        wb_we_o,
    output reg [2:0]  wb_adr_o,
    output reg [7:0]  wb_dat_o,
    input  wire       wb_ack_i
);

localparam NLEDS = 5;

reg [7:0] led_val [0:NLEDS-1];
reg       led_dir [0:NLEDS-1];
reg [2:0] cur_led;
reg [23:0] slow_cnt;

// Simple state machine for write transactions
localparam S_IDLE = 2'd0;
localparam S_WRITE = 2'd1;
localparam S_WAIT = 2'd2;
reg [1:0] state;

integer i;
always @(posedge clk) begin
    if (rst) begin
        for (i=0;i<NLEDS;i=i+1) begin
            led_val[i] <= 8'd0;
            led_dir[i] <= 1'b1;
        end
        cur_led <= 3'd0;
        slow_cnt <= 24'd0;
        wb_cyc_o <= 1'b0;
        wb_stb_o <= 1'b0;
        wb_we_o  <= 1'b0;
        wb_adr_o <= 3'd0;
        wb_dat_o <= 8'd0;
        state <= S_IDLE;
    end else begin
        slow_cnt <= slow_cnt + 24'd1;

        // On slow tick, update a single LED value and request a write
        // Smaller threshold for demo/simulation responsiveness
        if (slow_cnt == 24'd2000 && state == S_IDLE) begin
            // update current LED
            if (led_dir[cur_led]) begin
                if (led_val[cur_led] == 8'hFF) begin
                    led_dir[cur_led] <= 1'b0;
                    led_val[cur_led] <= led_val[cur_led] - 8'd1;
                end else begin
                    led_val[cur_led] <= led_val[cur_led] + 8'd1;
                end
            end else begin
                if (led_val[cur_led] == 8'h00) begin
                    led_dir[cur_led] <= 1'b1;
                    led_val[cur_led] <= led_val[cur_led] + 8'd1;
                end else begin
                    led_val[cur_led] <= led_val[cur_led] - 8'd1;
                end
            end

            // Start a write transaction
            wb_adr_o <= cur_led;
            wb_dat_o <= led_val[cur_led];
            wb_we_o  <= 1'b1;
            wb_cyc_o <= 1'b1;
            wb_stb_o <= 1'b1;
            state <= S_WRITE;
        end

        // handle write handshake
        case (state)
            S_WRITE: begin
                // wait for ack
                if (wb_ack_i) begin
                    // deassert signals next cycle
                    wb_cyc_o <= 1'b0;
                    wb_stb_o <= 1'b0;
                    wb_we_o  <= 1'b0;
                    // move to next LED
                    cur_led <= (cur_led == (NLEDS-1)) ? 3'd0 : cur_led + 3'd1;
                    state <= S_IDLE;
                end
            end
            default: ;
        endcase
    end
end

endmodule

module leds(input  wire CLK_i,
            output wire D1,
            output wire D2,
            output wire D3,
            output wire D4,
            output wire D5);

wire wb_cyc;
wire wb_stb;
wire wb_we;
wire [2:0] wb_adr;
wire [7:0] wb_dat_w;
wire [7:0] wb_dat_r;
wire wb_ack;

// Power-on reset: assert for a short time after configuration so
// both master and slave initialize their registers deterministically.
reg [15:0] por_cnt;
wire por = (por_cnt != 16'd50000);

always @(posedge CLK_i) begin
    if (por_cnt != 16'd50000)
        por_cnt <= por_cnt + 16'd1;
end

// Instantiate master
wb_master_fader master (
    .clk(CLK_i),
    .rst(por),
    .wb_cyc_o(wb_cyc),
    .wb_stb_o(wb_stb),
    .wb_we_o(wb_we),
    .wb_adr_o(wb_adr),
    .wb_dat_o(wb_dat_w),
    .wb_ack_i(wb_ack)
);

// Instantiate slave
wb_led_pwm_driver slave (
    .wb_clk_i(CLK_i),
    .wb_rst_i(por),
    .wb_cyc_i(wb_cyc),
    .wb_stb_i(wb_stb),
    .wb_we_i(wb_we),
    .wb_adr_i(wb_adr),
    .wb_dat_i(wb_dat_w),
    .wb_dat_o(wb_dat_r),
    .wb_ack_o(wb_ack),
    .D1(D1),
    .D2(D2),
    .D3(D3),
    .D4(D4),
    .D5(D5)
);

endmodule
