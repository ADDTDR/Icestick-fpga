`timescale 1ns/10ps


module memory_tb();

    wire [7:0] r_data;

    reg clk = 1'b0;
    reg w_en = 1'b0;
    reg r_en = 1'b1;
    reg [7:0]  w_addr;
    reg [7:0]  r_addr;
    reg [7:0] w_data;

    localparam DURATION = 10000;

    always begin
        #41.67 
        clk = ~clk;
    end

    memory uut(
        .clk(clk),
        .w_en(w_en),
        .r_en(r_en),
        .w_addr(w_addr),
        .r_addr(r_addr),
        .w_data(w_data),
        .r_data(r_data)
    );


    initial begin
        // Test read
        #(2 * 41.67)
        r_addr = 8'h00;
        r_en = 1'b1;     
        // Clear read addr and enable  signal 
        #(2 * 41.67)
        r_addr = 8'h00;
        r_en = 0;

        // Test write 
        #(2 * 41.67)
        w_addr = 8'h01;
        w_data = 8'hff;
        w_en = 1'b1;
        // Clear addr, data and enable signal
        #(2 * 41.67)
        w_addr = 8'h00;
        w_data = 8'h00;
        w_en = 1'b0;

        // Test read
        #(2 * 41.67)
        r_addr = 8'h01;
        r_en = 1'b1;  
        // Clear read addr and enable  signal 
        #(2 * 41.67)
        r_addr = 8'h00;
        r_en = 0;


    end

    initial begin
        $dumpfile("bram_tb.vcd");
        $dumpvars(0, memory_tb);

        #(DURATION)
        $display("Simulation done");
        $finish;
    end
endmodule