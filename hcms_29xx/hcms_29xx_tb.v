`timescale 1ns/10ps
`define DUMPSTR(x) `"x.vcd`"

module top_tb();

reg CLK_i = 1'b0;
localparam  DURATION = 10000 * 6;

always begin
    // Delay 
    #41.667
    CLK_i = ~CLK_i;
end


top uut(
    .i_clk(CLK_i)
   
);


initial begin

 
     $dumpfile(`DUMPSTR(`VCD_OUTPUT));
     $dumpvars(0, top_tb );

     #(DURATION)
     $display("Finished!");
     $finish;
end

endmodule