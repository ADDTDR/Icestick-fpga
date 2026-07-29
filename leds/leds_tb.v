`default_nettype none
`define DUMPSTR(x) `"x.vcd`"
`timescale 100 ns / 10 ns

module leds_tb();

//-- Simulation time
parameter DURATION = 4000;

//-- Clock signal. It is not used in this simulation
reg clk = 0;
always #0.5 clk = ~clk;

//-- Leds port
wire d1, d2, d3, d4, d5;
//-- Instantiate the unit to test

//-- Instantiate top-level leds module (contains master + slave)
leds UUT (
  .CLK_i(clk),
  .D1(d1),
  .D2(d2),
  .D3(d3),
  .D4(d4),
  .D5(d5)
);


initial begin
  //-- File were to store the simulation results
  $dumpfile(`DUMPSTR(`VCD_OUTPUT));
  $dumpvars(0, leds_tb);
  repeat (2) @(posedge clk);

   #(DURATION) $display("End of simulation");
  $finish;
end

endmodule
