module top (
    input PMOD_4,
    input PMOD_3,
    output D1,
    output D2,
    output D3,
    output D4, 
    output D5
);
    assign D1 = PMOD_4;
    assign D2 = PMOD_3;
    assign D3 = 0;
    assign D4 = 0;
    assign D5 = 0;

endmodule