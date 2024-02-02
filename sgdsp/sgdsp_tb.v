`timescale 1ns/1ps

module top_tb();

    reg CLK_i = 0;
    reg PMOD_2;
    reg PMOD_3;
    reg PMOD_4;


localparam  DURATION = 10000000;

always begin
    // Delay 
    #41.667
    CLK_i = ~CLK_i;
end

top #(.COUNT_WIDTH(4), .MAX_COUNT(6)) uut(
    .CLK_i(CLK_i)


);

initial begin
     $dumpfile("sgdsp_tb.vcd");
     $dumpvars(0, top_tb );

     #(DURATION)
     $display("Finished!");
     $finish;
end
endmodule