module sine_rom (
    input  wire [7:0] addr,
    output reg  signed [15:0] data
);
always @(*) begin
    case (addr)
        8'd0: data = -16'sd0;
        8'd1: data = 16'sd804;
        8'd2: data = 16'sd1608;
        8'd3: data = 16'sd2410;
        8'd4: data = 16'sd3212;
        8'd5: data = 16'sd4011;
        8'd6: data = 16'sd4808;
        8'd7: data = 16'sd5602;
        8'd8: data = 16'sd6393;
        8'd9: data = 16'sd7179;
        8'd10: data = 16'sd7962;
        8'd11: data = 16'sd8739;
        8'd12: data = 16'sd9512;
        8'd13: data = 16'sd10278;
        8'd14: data = 16'sd11039;
        8'd15: data = 16'sd11793;
        8'd16: data = 16'sd12539;
        8'd17: data = 16'sd13279;
        8'd18: data = 16'sd14010;
        8'd19: data = 16'sd14732;
        8'd20: data = 16'sd15446;
        8'd21: data = 16'sd16151;
        8'd22: data = 16'sd16846;
        8'd23: data = 16'sd17530;
        8'd24: data = 16'sd18204;
        8'd25: data = 16'sd18868;
        8'd26: data = 16'sd19519;
        8'd27: data = 16'sd20159;
        8'd28: data = 16'sd20787;
        8'd29: data = 16'sd21403;
        8'd30: data = 16'sd22005;
        8'd31: data = 16'sd22594;
        8'd32: data = 16'sd23170;
        8'd33: data = 16'sd23731;
        8'd34: data = 16'sd24279;
        8'd35: data = 16'sd24811;
        8'd36: data = 16'sd25329;
        8'd37: data = 16'sd25832;
        8'd38: data = 16'sd26319;
        8'd39: data = 16'sd26790;
        8'd40: data = 16'sd27245;
        8'd41: data = 16'sd27683;
        8'd42: data = 16'sd28105;
        8'd43: data = 16'sd28510;
        8'd44: data = 16'sd28898;
        8'd45: data = 16'sd29268;
        8'd46: data = 16'sd29621;
        8'd47: data = 16'sd29956;
        8'd48: data = 16'sd30273;
        8'd49: data = 16'sd30571;
        8'd50: data = 16'sd30852;
        8'd51: data = 16'sd31113;
        8'd52: data = 16'sd31356;
        8'd53: data = 16'sd31580;
        8'd54: data = 16'sd31785;
        8'd55: data = 16'sd31971;
        8'd56: data = 16'sd32137;
        8'd57: data = 16'sd32285;
        8'd58: data = 16'sd32412;
        8'd59: data = 16'sd32521;
        8'd60: data = 16'sd32609;
        8'd61: data = 16'sd32678;
        8'd62: data = 16'sd32728;
        8'd63: data = 16'sd32757;
        8'd64: data = 16'sd32767;
        8'd65: data = 16'sd32757;
        8'd66: data = 16'sd32728;
        8'd67: data = 16'sd32678;
        8'd68: data = 16'sd32609;
        8'd69: data = 16'sd32521;
        8'd70: data = 16'sd32412;
        8'd71: data = 16'sd32285;
        8'd72: data = 16'sd32137;
        8'd73: data = 16'sd31971;
        8'd74: data = 16'sd31785;
        8'd75: data = 16'sd31580;
        8'd76: data = 16'sd31356;
        8'd77: data = 16'sd31113;
        8'd78: data = 16'sd30852;
        8'd79: data = 16'sd30571;
        8'd80: data = 16'sd30273;
        8'd81: data = 16'sd29956;
        8'd82: data = 16'sd29621;
        8'd83: data = 16'sd29268;
        8'd84: data = 16'sd28898;
        8'd85: data = 16'sd28510;
        8'd86: data = 16'sd28105;
        8'd87: data = 16'sd27683;
        8'd88: data = 16'sd27245;
        8'd89: data = 16'sd26790;
        8'd90: data = 16'sd26319;
        8'd91: data = 16'sd25832;
        8'd92: data = 16'sd25329;
        8'd93: data = 16'sd24811;
        8'd94: data = 16'sd24279;
        8'd95: data = 16'sd23731;
        8'd96: data = 16'sd23170;
        8'd97: data = 16'sd22594;
        8'd98: data = 16'sd22005;
        8'd99: data = 16'sd21403;
        8'd100: data = 16'sd20787;
        8'd101: data = 16'sd20159;
        8'd102: data = 16'sd19519;
        8'd103: data = 16'sd18868;
        8'd104: data = 16'sd18204;
        8'd105: data = 16'sd17530;
        8'd106: data = 16'sd16846;
        8'd107: data = 16'sd16151;
        8'd108: data = 16'sd15446;
        8'd109: data = 16'sd14732;
        8'd110: data = 16'sd14010;
        8'd111: data = 16'sd13279;
        8'd112: data = 16'sd12539;
        8'd113: data = 16'sd11793;
        8'd114: data = 16'sd11039;
        8'd115: data = 16'sd10278;
        8'd116: data = 16'sd9512;
        8'd117: data = 16'sd8739;
        8'd118: data = 16'sd7962;
        8'd119: data = 16'sd7179;
        8'd120: data = 16'sd6393;
        8'd121: data = 16'sd5602;
        8'd122: data = 16'sd4808;
        8'd123: data = 16'sd4011;
        8'd124: data = 16'sd3212;
        8'd125: data = 16'sd2410;
        8'd126: data = 16'sd1608;
        8'd127: data = 16'sd804;
        8'd128: data = -16'sd0;
        8'd129: data = -16'sd804;
        8'd130: data = -16'sd1608;
        8'd131: data = -16'sd2410;
        8'd132: data = -16'sd3212;
        8'd133: data = -16'sd4011;
        8'd134: data = -16'sd4808;
        8'd135: data = -16'sd5602;
        8'd136: data = -16'sd6393;
        8'd137: data = -16'sd7179;
        8'd138: data = -16'sd7962;
        8'd139: data = -16'sd8739;
        8'd140: data = -16'sd9512;
        8'd141: data = -16'sd10278;
        8'd142: data = -16'sd11039;
        8'd143: data = -16'sd11793;
        8'd144: data = -16'sd12539;
        8'd145: data = -16'sd13279;
        8'd146: data = -16'sd14010;
        8'd147: data = -16'sd14732;
        8'd148: data = -16'sd15446;
        8'd149: data = -16'sd16151;
        8'd150: data = -16'sd16846;
        8'd151: data = -16'sd17530;
        8'd152: data = -16'sd18204;
        8'd153: data = -16'sd18868;
        8'd154: data = -16'sd19519;
        8'd155: data = -16'sd20159;
        8'd156: data = -16'sd20787;
        8'd157: data = -16'sd21403;
        8'd158: data = -16'sd22005;
        8'd159: data = -16'sd22594;
        8'd160: data = -16'sd23170;
        8'd161: data = -16'sd23731;
        8'd162: data = -16'sd24279;
        8'd163: data = -16'sd24811;
        8'd164: data = -16'sd25329;
        8'd165: data = -16'sd25832;
        8'd166: data = -16'sd26319;
        8'd167: data = -16'sd26790;
        8'd168: data = -16'sd27245;
        8'd169: data = -16'sd27683;
        8'd170: data = -16'sd28105;
        8'd171: data = -16'sd28510;
        8'd172: data = -16'sd28898;
        8'd173: data = -16'sd29268;
        8'd174: data = -16'sd29621;
        8'd175: data = -16'sd29956;
        8'd176: data = -16'sd30273;
        8'd177: data = -16'sd30571;
        8'd178: data = -16'sd30852;
        8'd179: data = -16'sd31113;
        8'd180: data = -16'sd31356;
        8'd181: data = -16'sd31580;
        8'd182: data = -16'sd31785;
        8'd183: data = -16'sd31971;
        8'd184: data = -16'sd32137;
        8'd185: data = -16'sd32285;
        8'd186: data = -16'sd32412;
        8'd187: data = -16'sd32521;
        8'd188: data = -16'sd32609;
        8'd189: data = -16'sd32678;
        8'd190: data = -16'sd32728;
        8'd191: data = -16'sd32757;
        8'd192: data = -16'sd32767;
        8'd193: data = -16'sd32757;
        8'd194: data = -16'sd32728;
        8'd195: data = -16'sd32678;
        8'd196: data = -16'sd32609;
        8'd197: data = -16'sd32521;
        8'd198: data = -16'sd32412;
        8'd199: data = -16'sd32285;
        8'd200: data = -16'sd32137;
        8'd201: data = -16'sd31971;
        8'd202: data = -16'sd31785;
        8'd203: data = -16'sd31580;
        8'd204: data = -16'sd31356;
        8'd205: data = -16'sd31113;
        8'd206: data = -16'sd30852;
        8'd207: data = -16'sd30571;
        8'd208: data = -16'sd30273;
        8'd209: data = -16'sd29956;
        8'd210: data = -16'sd29621;
        8'd211: data = -16'sd29268;
        8'd212: data = -16'sd28898;
        8'd213: data = -16'sd28510;
        8'd214: data = -16'sd28105;
        8'd215: data = -16'sd27683;
        8'd216: data = -16'sd27245;
        8'd217: data = -16'sd26790;
        8'd218: data = -16'sd26319;
        8'd219: data = -16'sd25832;
        8'd220: data = -16'sd25329;
        8'd221: data = -16'sd24811;
        8'd222: data = -16'sd24279;
        8'd223: data = -16'sd23731;
        8'd224: data = -16'sd23170;
        8'd225: data = -16'sd22594;
        8'd226: data = -16'sd22005;
        8'd227: data = -16'sd21403;
        8'd228: data = -16'sd20787;
        8'd229: data = -16'sd20159;
        8'd230: data = -16'sd19519;
        8'd231: data = -16'sd18868;
        8'd232: data = -16'sd18204;
        8'd233: data = -16'sd17530;
        8'd234: data = -16'sd16846;
        8'd235: data = -16'sd16151;
        8'd236: data = -16'sd15446;
        8'd237: data = -16'sd14732;
        8'd238: data = -16'sd14010;
        8'd239: data = -16'sd13279;
        8'd240: data = -16'sd12539;
        8'd241: data = -16'sd11793;
        8'd242: data = -16'sd11039;
        8'd243: data = -16'sd10278;
        8'd244: data = -16'sd9512;
        8'd245: data = -16'sd8739;
        8'd246: data = -16'sd7962;
        8'd247: data = -16'sd7179;
        8'd248: data = -16'sd6393;
        8'd249: data = -16'sd5602;
        8'd250: data = -16'sd4808;
        8'd251: data = -16'sd4011;
        8'd252: data = -16'sd3212;
        8'd253: data = -16'sd2410;
        8'd254: data = -16'sd1608;
        8'd255: data = -16'sd804;
        default: data = 16'sd0;
    endcase
end
endmodule



module dds_sine (
    input  wire        clk,
    input  wire        sample_tick,
    output wire signed [15:0] sample
);
    reg [31:0] phase = 0;

    localparam [31:0] PHASE_INC = 32'd39370533;

    always @(posedge clk) begin
        if (sample_tick)
            phase <= phase + PHASE_INC;
    end

    sine_rom rom (
        .addr(phase[31:24]),
        .data(sample)
    );
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

