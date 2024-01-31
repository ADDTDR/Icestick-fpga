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


reg [24:0] counter;

assign D1 = counter[24];
assign D2 = counter[23];
assign D3 = counter[22];
assign D4 = counter[21];
assign D5 = counter[20];

always @(posedge CLK_i) begin
    counter <= counter + 1;    
end

endmodule