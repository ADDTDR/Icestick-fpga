`timescale 1ns/1ps
`define DUMPSTR(x) `"x.vcd`"
module blink_tb();

parameter DURATION  = 10000;

reg CLK_i = 0;


always begin
    #41.667
    CLK_i =!CLK_i;
end

top UUT(
    .CLK_i(CLK_i)

);

initial begin

  $dumpfile(`DUMPSTR(`VCD_OUTPUT));
  $dumpvars(0, blink_tb);

   #(DURATION) 
  $display("End of simulation");
  $finish;
end

endmodule