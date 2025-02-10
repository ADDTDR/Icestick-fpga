`timescale 1ns/10ps


module top_tb();

reg CLK_i = 0;
reg [7:0] data;

localparam  DURATION = 10000000;

always begin
    // Delay 
    #41.667
    CLK_i = ~CLK_i;
end

reg load_data = 0; 

hcms_serial uut(
    .CLK_i(CLK_i),
    .DATA_i(data),
    .DATA_LOAD(load_data)

);

initial begin

    #(2 * 41.67)
    data = 8'h04;
    load_data = 1'b0;     
    // Clear read addr and enable  signal 
    #(2 * 41.67)
    data = 8'h32;
    load_data = 1'b1;

    #(2 * 41.67)
    data = 8'h64;
    load_data = 1'b1;  

     $dumpfile("hcms_29xx_tb.vcd");
     $dumpvars(0, top_tb );

     #(DURATION)
     $display("Finished!");
     $finish;
end

endmodule