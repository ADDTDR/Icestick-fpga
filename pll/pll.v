module top(
    CLK_i,
    D1,
    D2,
    D3,
    D4,
    D5
);

input CLK_i;
output D1;
output D2;
output D3;
output D4;
output D5;

wire pll_clk_o;
reg [24:0] counter = 0;

initial begin
    counter <= 0;
end



assign D1 = counter[24];
assign D2 = counter[23];
assign D3 = counter[22];
assign D4 = counter[21];
assign D5 = counter[20];

pll_module pll_mull(
    .clk_i(CLK_i),
    .clk_o(pll_clk_o)
);

always @(posedge pll_clk_o) begin
    counter <= counter + 1;    
end

endmodule

module pll_module (
    input clk_i,
    output clk_o
); 
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"), // Don't use fine delay adjustment 
        .PLLOUT_SELECT("GENCLK"), // No phase shift on output 
        .DIVR(4'b0000),           // Reference clock divider 
        .DIVF(7'b1001111),        // Feedback divider 
        .DIVQ(3'b011),            // VCO clock divider  
        .FILTER_RANGE(3'b001)     // Filter range   
    ) pll (
        .REFERENCECLK(clk_i),     // Clock input 
        .PLLOUTCORE(clk_o),       // Clock output 
        .LOCK(),                  // Locked signal 
        .RESETB(1'b1),            // Active low reset   
        .BYPASS(1'b0)             // No bypass, use PLL signal as outputl 
    ); 
endmodule