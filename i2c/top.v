module top(
    input wire CLK_i,
	output wire SCL_PIN,
	inout wire SDA_PIN
   
    );

wire rst = 1'b0;

ht16k33 ht16k33_inst (
    .clk(CLK_i),
    .rst(rst),
    .scl(SCL_PIN),
    .sda(SDA_PIN)
);
endmodule