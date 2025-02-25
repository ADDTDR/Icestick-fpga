`timescale 1ns/10ps


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

 
     $dumpfile("hcms_29xx_tb.vcd");
     $dumpvars(0, top_tb );

     #(DURATION)
     $display("Finished!");
     $finish;
end

endmodule