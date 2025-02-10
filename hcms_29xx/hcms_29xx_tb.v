`timescale 1ns/1ps


module top_tb();

reg CLK_i = 0;


localparam  DURATION = 10000000;

always begin
    // Delay 
    #41.667
    CLK_i = ~CLK_i;
end


hmcs_serial uut(
    .CLK_i(CLK_i)


);

initial begin
     $dumpfile("hcms_29xx_tb.vcd");
     $dumpvars(0, uut );

     #(DURATION)
     $display("Finished!");
     $finish;
end

endmodule